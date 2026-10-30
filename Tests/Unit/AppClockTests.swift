import XCTest
@testable import MatchaMind

/// Prüft `FixedClock` (`App/AppClock.swift`): liefert exakt das gesetzte
/// Datum und lässt sich verschieben - Grundlage für simuliertes Datum in
/// UI-Test-Personas (siehe `MASTER-PROMPT.md`, Block B9 Aufgabe 2).
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort. Die hier verwendete Logik (Lock-geschütztes
/// `Date`, `set`, `advance`) wurde von Hand gegen `App/AppClock.swift`
/// geprüft.
final class AppClockTests: XCTestCase {

    private var referenceDate: Date {
        ISO8601DateFormatter().date(from: "2026-01-15T08:00:00Z")!
    }

    func testFixedClockReturnsExactlySetDate() {
        let clock = FixedClock(date: referenceDate)

        XCTAssertEqual(clock.now(), referenceDate)
    }

    func testFixedClockCanBeSetToANewDate() {
        let clock = FixedClock(date: referenceDate)
        let laterDate = ISO8601DateFormatter().date(from: "2026-02-01T08:00:00Z")!

        clock.set(laterDate)

        XCTAssertEqual(clock.now(), laterDate)
    }

    func testFixedClockCanBeAdvancedByFourteenDays() {
        let clock = FixedClock(date: referenceDate)
        let fourteenDays: TimeInterval = 60 * 60 * 24 * 14

        clock.advance(by: fourteenDays)

        XCTAssertEqual(clock.now(), referenceDate.addingTimeInterval(fourteenDays))
    }

    func testFixedClockCanBeAdvancedBackwards() {
        let clock = FixedClock(date: referenceDate)

        clock.advance(by: -3600)

        XCTAssertEqual(clock.now(), referenceDate.addingTimeInterval(-3600))
    }

    func testSystemClockReturnsATimeCloseToNow() {
        let clock = SystemClock()
        let before = Date()

        let result = clock.now()

        XCTAssertGreaterThanOrEqual(result, before)
        XCTAssertLessThan(result.timeIntervalSince(before), 1)
    }
}
