// PlayerStore.swift
// Spielerdaten (MASTER-PROMPT.md, Block B4 Aufgabe 1 und 2): einzige
// Schreibstelle fuer Stufe, Tagesprotokoll und Spiel-Zustaende. Die
// Aufstiegs-Entscheidung selbst trifft die reine `LevelProgression`.
//
// `@MainActor`: der `mainContext` des Containers ist an den Hauptakteur
// gebunden, alle Zugriffe kommen aus der UI. Gelesen wird bewusst ueber
// einfache Vollabrufe, die im Speicher gefiltert werden - es gibt hoechstens
// einen `DayRecord` pro Tag, die Datenmenge bleibt klein, und es entfallen
// Praedikats-Eigenheiten von SwiftData.

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PlayerStore {
    /// Anzahl aktiver Tage, um die "Lieber noch bleiben" ein Angebot verschiebt.
    static let deferralActiveDays = 7
    /// Tautropfen pro abgeschlossener Spielrunde.
    nonisolated static let dewPerGame = 12

    private let container: ModelContainer
    private let clock: AppClock
    private let calendar: Calendar
    private let profile: PlayerProfile

    /// Wird nach jedem Speichern erhoeht, damit abgeleitete Werte, die aus
    /// Abrufen entstehen (`isTeaBreakCompletedToday`, `activeDaysAtCurrentLevel`),
    /// in SwiftUI neu berechnet werden.
    private(set) var revision = 0

    private var context: ModelContext { container.mainContext }

    // MARK: - Aufbau

    /// Baut den Container fuer die drei Modelle. `inMemory` fuer UI-Tests;
    /// `url` (nur ohne `inMemory`) legt die Datei fuer Tests an einen
    /// bekannten Ort. Ohne beides gilt der Standardort der App.
    static func makeContainer(inMemory: Bool, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([PlayerProfile.self, DayRecord.self, GameRecord.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    init(container: ModelContainer, clock: AppClock, calendar: Calendar = .autoupdatingCurrent) {
        self.container = container
        self.clock = clock
        self.calendar = calendar

        let context = container.mainContext
        let existing = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first
        if let existing {
            self.profile = existing
        } else {
            let now = clock.now()
            let created = PlayerProfile(
                level: .sencha,
                levelSinceDayKey: DayKey.string(for: now, calendar: calendar),
                installDate: now
            )
            context.insert(created)
            Self.persist(context)
            self.profile = created
        }
    }

    // MARK: - Stufe

    var level: TeaLevel { profile.level }
    var autoAdvance: Bool { profile.autoAdvance }
    var highestLevel: TeaLevel { profile.highestLevel }

    /// Manuelle Wahl: Zaehlung der aktiven Tage beginnt neu, ein
    /// aufgeschobenes Angebot entfaellt. Nach einer Senkung kommt das naechste
    /// Angebot nach `LevelProgression.reentryActiveDays` aktiven Tagen.
    func setLevel(_ newLevel: TeaLevel) {
        // Ist die heutige Teepause schon erledigt (typisch beim
        // Aufstiegs-Moment direkt nach dem Abschluss), zählt dieser Tag
        // noch zur alten Stufe - die neue Stufe beginnt erst morgen.
        let alreadyCountedToday = isTeaBreakCompletedToday
        profile.levelLoweredManually = newLevel < profile.level
        profile.level = newLevel
        profile.levelSinceDayKey = alreadyCountedToday ? tomorrowKey : todayKey
        profile.highestLevel = max(profile.highestLevel, newLevel)
        profile.promotionDeferredUntilActiveDays = nil
        save()
    }

    func setAutoAdvance(_ enabled: Bool) {
        profile.autoAdvance = enabled
        save()
    }

    /// Aktive Tage (Teepause erledigt) seit Beginn der aktuellen Stufe.
    var activeDaysAtCurrentLevel: Int {
        _ = revision
        let since = profile.levelSinceDayKey
        return allDayRecords().filter { $0.teaBreakCompleted && $0.dayKey >= since }.count
    }

    var isTeaBreakCompletedToday: Bool {
        _ = revision
        let key = todayKey
        return allDayRecords().first { $0.dayKey == key }?.teaBreakCompleted ?? false
    }

    // MARK: - Ergebnisse und Teepause

    /// Addiert Treffer/Fehler zum heutigen Tagesprotokoll (Stufe = aktuelle
    /// Spielerstufe) und merkt sich den Spielzeitpunkt. Zaehlt allein nicht
    /// als aktiver Tag.
    func recordGameResult(gameID: String, result: GameResult) {
        let day = dayRecord(for: todayKey)
        day.hits += result.hits
        day.misses += result.misses
        day.level = profile.level
        profile.dewDrops += Self.dewPerGame
        profile.dewEarnedTotal += Self.dewPerGame
        gameRecord(for: gameID).lastPlayed = clock.now()
        save()
    }

    /// Markiert heute als aktiven Tag (mehrfach aufgerufen weiterhin genau
    /// ein aktiver Tag) und liefert die Stufe, auf die jetzt aufgestiegen
    /// werden kann.
    @discardableResult
    func completeTeaBreak() -> TeaLevel? {
        let day = dayRecord(for: todayKey)
        day.teaBreakCompleted = true
        save()
        awardBonusBlossomIfReached()
        return pendingPromotion()
    }

    /// Stufe, auf die aktuell aufgestiegen werden kann (siehe
    /// `LevelProgression.promotionTarget`).
    func pendingPromotion() -> TeaLevel? {
        LevelProgression.promotionTarget(
            currentLevel: profile.level,
            autoAdvance: profile.autoAdvance,
            activeDaysAtCurrentLevel: activeDaysAtCurrentLevel,
            lastSevenActiveDays: recentActiveDaySummaries(),
            deferredUntilActiveDays: profile.promotionDeferredUntilActiveDays,
            loweredManually: profile.levelLoweredManually
        )
    }

    /// "Weiter mit ...": Aufstieg annehmen, wirkt wie eine manuelle Wahl.
    func acceptPromotion(to target: TeaLevel) {
        setLevel(target)
    }

    /// "Lieber noch bleiben": naechstes Angebot fruehestens nach weiteren
    /// `deferralActiveDays` aktiven Tagen.
    func deferPromotion() {
        profile.promotionDeferredUntilActiveDays = activeDaysAtCurrentLevel + Self.deferralActiveDays
        save()
    }

    // MARK: - Tau und Deko

    /// Aktuell ausgebbarer Tau.
    var dewDrops: Int { _ = revision; return profile.dewDrops }
    /// Insgesamt verdienter Tau, sinkt nie.
    var dewEarnedTotal: Int { _ = revision; return profile.dewEarnedTotal }
    var ownedDecorationIDs: Set<String> { _ = revision; return Set(profile.decorationIDs) }

    /// Kauft ein Deko-Stueck: nur wenn es existiert, noch nicht besessen wird
    /// und genug Tau da ist. Zieht den Preis von `dewDrops` ab
    /// (`dewEarnedTotal` bleibt unveraendert).
    @discardableResult
    func purchaseDecoration(id: String) -> Bool {
        guard let item = DecorationCatalog.item(id: id),
              !profile.decorationIDs.contains(id),
              profile.dewDrops >= item.price else { return false }
        profile.dewDrops -= item.price
        profile.decorationIDs.append(id)
        save()
        return true
    }

    // MARK: - Wochenziel

    var weeklyGoalDays: Int { profile.weeklyGoalDays }

    /// Je Wochentag (Montag bis Sonntag) der aktuellen Woche: Teepause erledigt?
    var weekActiveDayStates: [Bool] {
        _ = revision
        let completed = completedDayKeys()
        return WeeklyGoal.dayKeys(ofWeekContaining: clock.now(), calendar: calendar).map { completed.contains($0) }
    }

    var activeDaysThisWeek: Int { weekActiveDayStates.filter { $0 }.count }

    var bonusBlossomCount: Int { _ = revision; return profile.bonusBlossomWeeks.count }

    /// Vergibt die Bonus-Bluete der laufenden Woche, sobald das Wochenziel
    /// erreicht ist - hoechstens einmal je Woche.
    private func awardBonusBlossomIfReached() {
        let weekKey = WeeklyGoal.weekKey(for: clock.now(), calendar: calendar)
        guard WeeklyGoal.isReached(activeDays: activeDaysThisWeek, goal: profile.weeklyGoalDays),
              !profile.bonusBlossomWeeks.contains(weekKey) else { return }
        profile.bonusBlossomWeeks.append(weekKey)
        save()
    }

    private func completedDayKeys() -> Set<String> {
        Set(allDayRecords().filter { $0.teaBreakCompleted }.map(\.dayKey))
    }

    // MARK: - Spiele

    func lastPlayed(gameID: String) -> Date? {
        existingGameRecord(for: gameID)?.lastPlayed
    }

    func instructionsSeen(gameID: String) -> Bool {
        existingGameRecord(for: gameID)?.instructionsSeen ?? false
    }

    func markInstructionsSeen(gameID: String) {
        let record = gameRecord(for: gameID)
        guard !record.instructionsSeen else { return }
        record.instructionsSeen = true
        save()
    }

    func fineLevel(gameID: String) -> Int? {
        existingGameRecord(for: gameID)?.fineLevel
    }

    func saveFineLevel(gameID: String, level: Int) {
        let record = gameRecord(for: gameID)
        guard record.fineLevel != level else { return }
        record.fineLevel = level
        save()
    }

    // MARK: - Erinnerung

    var onboardingCompleted: Bool { _ = revision; return profile.onboardingCompleted }

    func completeOnboarding() {
        guard !profile.onboardingCompleted else { return }
        profile.onboardingCompleted = true
        save()
    }

    /// Gewaehlte Uhrzeit der Erinnerung, `nil` wenn keine gewaehlt wurde.
    var reminderTime: ReminderTime? {
        _ = revision
        guard let hour = profile.reminderHour, let minute = profile.reminderMinute else { return nil }
        return ReminderTime(hour: hour, minute: minute)
    }

    /// Speichert die Uhrzeit und schaltet die Erinnerung (wieder) ein.
    func setReminderTime(_ time: ReminderTime) {
        profile.reminderHour = time.hour
        profile.reminderMinute = time.minute
        profile.reminderOff = false
        save()
    }

    var reminderOff: Bool { _ = revision; return profile.reminderOff }

    func setReminderOff(_ off: Bool) {
        profile.reminderOff = off
        save()
    }

    var invitationDate: Date? { _ = revision; return profile.invitationDate }

    func setInvitationDate(_ date: Date) {
        profile.invitationDate = date
        save()
    }

    /// Anfang des letzten aktiven Tages (Teepause erledigt), sonst des
    /// Installationstages.
    var lastActiveDay: Date {
        _ = revision
        let lastKey = allDayRecords().filter { $0.teaBreakCompleted }.map(\.dayKey).max()
        if let lastKey, let date = DayKey.date(from: lastKey, calendar: calendar) {
            return date
        }
        return calendar.startOfDay(for: profile.installDate)
    }

    // MARK: - Hilfen

    private var todayKey: String {
        DayKey.string(for: clock.now(), calendar: calendar)
    }

    private var tomorrowKey: String {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: clock.now()) ?? clock.now()
        return DayKey.string(for: tomorrow, calendar: calendar)
    }

    private func allDayRecords() -> [DayRecord] {
        (try? context.fetch(FetchDescriptor<DayRecord>())) ?? []
    }

    private func dayRecord(for key: String) -> DayRecord {
        if let existing = allDayRecords().first(where: { $0.dayKey == key }) {
            return existing
        }
        let created = DayRecord(dayKey: key, level: profile.level)
        context.insert(created)
        return created
    }

    private func existingGameRecord(for gameID: String) -> GameRecord? {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        return records.first { $0.gameID == gameID }
    }

    private func gameRecord(for gameID: String) -> GameRecord {
        if let existing = existingGameRecord(for: gameID) {
            return existing
        }
        let created = GameRecord(gameID: gameID)
        context.insert(created)
        return created
    }

    /// Die letzten aktiven Tage (neueste zuletzt) mit ihren Summen.
    private func recentActiveDaySummaries() -> [ActiveDaySummary] {
        allDayRecords()
            .filter { $0.teaBreakCompleted }
            .sorted { $0.dayKey < $1.dayKey }
            .suffix(LevelProgression.accuracyWindowDays)
            .map { ActiveDaySummary(dayKey: $0.dayKey, hits: $0.hits, misses: $0.misses) }
    }

    private func save() {
        Self.persist(context)
        revision += 1
    }

    /// Speichert; ein Fehler bleibt im Release unsichtbar (die Daten bleiben
    /// im Kontext), faellt aber in DEBUG sofort auf.
    private static func persist(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("PlayerStore: Speichern fehlgeschlagen: \(error)")
        }
    }
}
