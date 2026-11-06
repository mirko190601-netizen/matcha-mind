// UITestSeed.swift
// Spielstaende fuer UI-Tests des Aufstiegs (MASTER-PROMPT.md, Block B4 Gate):
// ohne sie waeren 14 bzw. 21 echte Spieltage noetig. Nur DEBUG, nur im
// In-Memory-Speicher und nur mit einer UI-Test-Persona wirksam (siehe
// `LaunchConfiguration.effectiveSeed`). Im Release-Build existiert der Typ nicht.

#if DEBUG

import Foundation
import SwiftData

/// Spielstand kurz vor dem Aufstieg: alle frueheren aktiven Tage liegen vor dem
/// simulierten Tag, die heutige Teepause ist der Tag, der das Angebot ausloest.
enum UITestSeed: String, CaseIterable, Sendable {
    /// Sencha, 13 aktive Tage, 80 % Treffer: die heutige Teepause ist Tag 14.
    case promotionOolong = "promotion-oolong"
    /// Oolong (hoechste Stufe Oolong), 20 aktive Tage, 80 %: heute ist Tag 21.
    case promotionMatcha = "promotion-matcha"

    /// Stufe des Spielers im Spielstand.
    var level: TeaLevel {
        switch self {
        case .promotionOolong: .sencha
        case .promotionMatcha: .oolong
        }
    }

    /// Aktive Tage vor dem simulierten Tag.
    var priorActiveDays: Int {
        switch self {
        case .promotionOolong: LevelProgression.senchaToOolongActiveDays - 1
        case .promotionMatcha: LevelProgression.oolongToMatchaActiveDays - 1
        }
    }

    /// Treffer und Fehler je Seed-Tag: genau 80 %. Bewusst viele, damit die
    /// heutige Teepause im UI-Test (Fehlgriffe moeglich) die 75 % ueber die
    /// letzten sieben aktiven Tage nicht unterschreiten kann: mit sechs
    /// Seed-Tagen im Fenster vertraegt es noch 4000 Fehler am heutigen Tag.
    static let hitsPerDay = 8_000
    static let missesPerDay = 2_000

    /// Schreibt Profil und Tagesprotokolle in den (leeren) Container. Der
    /// `PlayerStore`, der danach auf demselben Container startet, findet das
    /// Profil vor und legt kein neues an.
    @MainActor
    func populate(container: ModelContainer, now: Date, calendar: Calendar) {
        let context = container.mainContext
        let firstDay = calendar.date(byAdding: .day, value: -priorActiveDays, to: now) ?? now

        let profile = PlayerProfile(
            level: level,
            levelSinceDayKey: DayKey.string(for: firstDay, calendar: calendar),
            installDate: calendar.startOfDay(for: firstDay)
        )
        context.insert(profile)

        for offset in 1...priorActiveDays {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let record = DayRecord(dayKey: DayKey.string(for: day, calendar: calendar), level: level)
            record.hits = Self.hitsPerDay
            record.misses = Self.missesPerDay
            record.teaBreakCompleted = true
            context.insert(record)
        }
        try? context.save()
    }
}

#endif
