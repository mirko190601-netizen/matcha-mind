import XCTest
@testable import MatchaMind

/// Prüft `FineLevelTracker` (`Games/Core/FineLevel.swift`): 3 Erfolge in
/// Folge heben die Feinstufe an, 2 Fehlversuche in Folge senken sie, und
/// beide Richtungen bleiben an ihrer Grenze stehen.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class FineLevelTests: XCTestCase {

    func testStartsAtLowerBoundByDefault() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5)

        XCTAssertEqual(tracker.fineLevel, 1)
    }

    func testStartLevelIsClampedToBounds() {
        let tooHigh = FineLevelTracker(lowerBound: 1, upperBound: 5, startLevel: 99)
        let tooLow = FineLevelTracker(lowerBound: 1, upperBound: 5, startLevel: -3)

        XCTAssertEqual(tooHigh.fineLevel, 5)
        XCTAssertEqual(tooLow.fineLevel, 1)
    }

    func testThreeConsecutiveSuccessesRaiseFineLevelByOne() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5)

        tracker.recordSuccess()
        tracker.recordSuccess()
        XCTAssertEqual(tracker.fineLevel, 1, "Nach nur 2 Erfolgen darf sich noch nichts ändern")

        tracker.recordSuccess()
        XCTAssertEqual(tracker.fineLevel, 2)
    }

    func testSuccessCounterResetsAfterRaise() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5)

        tracker.recordSuccess()
        tracker.recordSuccess()
        tracker.recordSuccess() // -> Feinstufe 2, Zähler zurückgesetzt
        tracker.recordSuccess()
        tracker.recordSuccess()
        XCTAssertEqual(tracker.fineLevel, 2, "Erst nach erneut 3 Erfolgen darf wieder erhöht werden")

        tracker.recordSuccess()
        XCTAssertEqual(tracker.fineLevel, 3)
    }

    func testTwoConsecutiveFailuresLowerFineLevelByOne() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5, startLevel: 3)

        tracker.recordFailure()
        XCTAssertEqual(tracker.fineLevel, 3, "Nach nur 1 Fehlversuch darf sich noch nichts ändern")

        tracker.recordFailure()
        XCTAssertEqual(tracker.fineLevel, 2)
    }

    func testFineLevelDoesNotRiseAboveUpperBound() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 2, startLevel: 2)

        for _ in 0..<9 {
            tracker.recordSuccess()
        }

        XCTAssertEqual(tracker.fineLevel, 2)
    }

    func testFineLevelDoesNotFallBelowLowerBound() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5, startLevel: 1)

        for _ in 0..<6 {
            tracker.recordFailure()
        }

        XCTAssertEqual(tracker.fineLevel, 1)
    }

    func testSuccessAfterFailureResetsFailureCounter() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5, startLevel: 3)

        tracker.recordFailure()
        tracker.recordSuccess() // unterbricht die Fehlversuchs-Serie
        tracker.recordFailure()
        XCTAssertEqual(tracker.fineLevel, 3, "Einzelner Fehlversuch nach Unterbrechung darf nicht senken")
    }

    func testFailureAfterSuccessResetsSuccessCounter() {
        let tracker = FineLevelTracker(lowerBound: 1, upperBound: 5, startLevel: 3)

        tracker.recordSuccess()
        tracker.recordSuccess()
        tracker.recordFailure() // unterbricht die Erfolgs-Serie
        tracker.recordSuccess()
        tracker.recordSuccess()
        XCTAssertEqual(tracker.fineLevel, 3, "Erfolgs-Serie muss nach Unterbrechung neu beginnen")
    }
}
