import XCTest
@testable import MatchaMind

/// Prüft die reine Aufstiegs-Logik `LevelProgression`
/// (`Progress/LevelProgression.swift`): Schwellen 14/21 aktive Tage,
/// Genauigkeit exakt ab 75 % (Ganzzahl-Vergleich), Auto-Aufstieg, Aufschub.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung; die Tests laufen
/// erst im CI.
final class LevelProgressionTests: XCTestCase {

    /// Sieben aktive Tage mit den gegebenen Treffern/Fehlern je Tag.
    private func week(hits: [Int], misses: [Int]) -> [ActiveDaySummary] {
        precondition(hits.count == misses.count)
        return hits.indices.map { index in
            ActiveDaySummary(dayKey: "2026-01-\(String(format: "%02d", index + 1))", hits: hits[index], misses: misses[index])
        }
    }

    /// 80 % (Summe 56 Treffer, 14 Fehler).
    private var goodWeek: [ActiveDaySummary] {
        week(hits: Array(repeating: 8, count: 7), misses: Array(repeating: 2, count: 7))
    }

    /// Genau 74 von 100 Versuchen.
    private var weekAt74: [ActiveDaySummary] {
        week(hits: [10, 10, 10, 11, 11, 11, 11], misses: [4, 4, 4, 3, 3, 4, 4])
    }

    /// Genau 75 von 100 Versuchen.
    private var weekAt75: [ActiveDaySummary] {
        week(hits: [10, 10, 10, 11, 11, 11, 12], misses: [4, 4, 4, 3, 3, 4, 3])
    }

    private func target(
        level: TeaLevel = .sencha,
        autoAdvance: Bool = true,
        days: Int,
        summaries: [ActiveDaySummary]? = nil,
        deferredUntil: Int? = nil
    ) -> TeaLevel? {
        LevelProgression.promotionTarget(
            currentLevel: level,
            autoAdvance: autoAdvance,
            activeDaysAtCurrentLevel: days,
            lastSevenActiveDays: summaries ?? goodWeek,
            deferredUntilActiveDays: deferredUntil
        )
    }

    // MARK: - Genauigkeit

    func testAccuracyWithoutAttemptsIsNotMet() {
        XCTAssertFalse(LevelProgression.accuracyMeetsThreshold(lastActiveDays: []))
        XCTAssertFalse(LevelProgression.accuracyMeetsThreshold(
            lastActiveDays: [ActiveDaySummary(dayKey: "2026-01-01", hits: 0, misses: 0)]
        ))
    }

    func testAccuracyAt74PercentIsNotMet() {
        XCTAssertFalse(LevelProgression.accuracyMeetsThreshold(lastActiveDays: weekAt74))
    }

    func testAccuracyExactlyAt75PercentIsMet() {
        XCTAssertTrue(LevelProgression.accuracyMeetsThreshold(lastActiveDays: weekAt75))
    }

    func testAccuracyUsesOnlyLastSevenActiveDays() {
        // Ein sehr schlechter alter Tag vor einer guten Woche zählt nicht mit.
        let oldBadDay = ActiveDaySummary(dayKey: "2025-12-01", hits: 0, misses: 50)
        XCTAssertTrue(LevelProgression.accuracyMeetsThreshold(lastActiveDays: [oldBadDay] + goodWeek))
    }

    // MARK: - Sencha -> Oolong

    func testSenchaWith13ActiveDaysDoesNotPromote() {
        XCTAssertNil(target(days: 13))
    }

    func testSenchaWith14ActiveDaysAndGoodAccuracyPromotesToOolong() {
        XCTAssertEqual(target(days: 14), .oolong)
    }

    func testSenchaWith14DaysAt74PercentDoesNotPromote() {
        XCTAssertNil(target(days: 14, summaries: weekAt74))
    }

    func testSenchaWith14DaysAt75PercentPromotes() {
        XCTAssertEqual(target(days: 14, summaries: weekAt75), .oolong)
    }

    // MARK: - Oolong -> Matcha

    func testOolongWith20ActiveDaysDoesNotPromote() {
        XCTAssertNil(target(level: .oolong, days: 20))
    }

    func testOolongWith21ActiveDaysPromotesToMatcha() {
        XCTAssertEqual(target(level: .oolong, days: 21), .matcha)
    }

    func testOolongWith21DaysAt74PercentDoesNotPromote() {
        XCTAssertNil(target(level: .oolong, days: 21, summaries: weekAt74))
    }

    // MARK: - Sonstige Regeln

    func testAutoAdvanceOffNeverPromotes() {
        XCTAssertNil(target(autoAdvance: false, days: 30))
        XCTAssertNil(target(level: .oolong, autoAdvance: false, days: 30))
    }

    func testMatchaNeverPromotes() {
        XCTAssertNil(target(level: .matcha, days: 100))
    }

    func testDeferredPromotionWaitsUntilTargetDaysReached() {
        XCTAssertNil(target(days: 20, deferredUntil: 21))
        XCTAssertEqual(target(days: 21, deferredUntil: 21), .oolong)
    }
}
