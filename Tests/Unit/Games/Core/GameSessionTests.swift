import XCTest
@testable import MatchaMind

/// Prüft `GameSession` (`Games/Core/GameSession.swift`): erlaubte
/// Zustandsübergänge, dass unerlaubte Übergänge ignoriert werden, und die
/// `accuracy`-Formel in `GameResult`.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class GameSessionTests: XCTestCase {

    private var referenceDate: Date {
        ISO8601DateFormatter().date(from: "2026-01-15T08:00:00Z")!
    }

    // MARK: - Zustandsübergänge

    func testStartMovesFromNotStartedToRunning() {
        let session = GameSession(clock: FixedClock(date: referenceDate))

        let didStart = session.start()

        XCTAssertTrue(didStart)
        XCTAssertEqual(session.state, .running)
    }

    func testStartIsIgnoredWhenAlreadyRunning() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()

        let didStartAgain = session.start()

        XCTAssertFalse(didStartAgain)
        XCTAssertEqual(session.state, .running)
    }

    func testPauseMovesFromRunningToPaused() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()

        let didPause = session.pause()

        XCTAssertTrue(didPause)
        XCTAssertEqual(session.state, .paused)
    }

    func testPauseIsIgnoredWhenNotRunning() {
        let session = GameSession(clock: FixedClock(date: referenceDate))

        let didPause = session.pause()

        XCTAssertFalse(didPause)
        XCTAssertEqual(session.state, .notStarted)
    }

    func testResumeMovesFromPausedToRunning() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()
        session.pause()

        let didResume = session.resume()

        XCTAssertTrue(didResume)
        XCTAssertEqual(session.state, .running)
    }

    func testResumeIsIgnoredWhenNotPaused() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()

        let didResume = session.resume()

        XCTAssertFalse(didResume)
        XCTAssertEqual(session.state, .running)
    }

    func testFinishFromRunningMovesToFinishedWithGivenResult() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()

        let didFinish = session.finish(hits: 7, misses: 3, duration: 60)

        XCTAssertTrue(didFinish)
        XCTAssertEqual(session.state, .finished(GameResult(hits: 7, misses: 3, duration: 60)))
    }

    func testFinishFromPausedMovesToFinished() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()
        session.pause()

        let didFinish = session.finish(hits: 5, misses: 0, duration: 45)

        XCTAssertTrue(didFinish)
        XCTAssertEqual(session.state, .finished(GameResult(hits: 5, misses: 0, duration: 45)))
    }

    func testFinishIsIgnoredWhenNotStarted() {
        let session = GameSession(clock: FixedClock(date: referenceDate))

        let didFinish = session.finish(hits: 1, misses: 0, duration: 10)

        XCTAssertFalse(didFinish)
        XCTAssertEqual(session.state, .notStarted)
    }

    func testStartIsIgnoredAfterFinish() {
        let session = GameSession(clock: FixedClock(date: referenceDate))
        session.start()
        session.finish(hits: 1, misses: 0, duration: 10)

        let didStartAgain = session.start()

        XCTAssertFalse(didStartAgain)
    }

    // MARK: - elapsedPlayTime

    func testElapsedPlayTimeExcludesPausedDuration() {
        let clock = FixedClock(date: referenceDate)
        let session = GameSession(clock: clock)
        session.start()

        clock.advance(by: 10)
        session.pause()
        clock.advance(by: 20) // Pausenzeit, darf nicht mitgezählt werden.
        session.resume()
        clock.advance(by: 15)

        XCTAssertEqual(session.elapsedPlayTime(), 25, accuracy: 0.001)
    }

    func testElapsedPlayTimeIsZeroBeforeStart() {
        let session = GameSession(clock: FixedClock(date: referenceDate))

        XCTAssertEqual(session.elapsedPlayTime(), 0)
    }

    // MARK: - GameResult.accuracy

    func testAccuracyIsHitsDividedByTotalAttempts() {
        let result = GameResult(hits: 8, misses: 2, duration: 72)

        XCTAssertEqual(result.accuracy, 0.8, accuracy: 0.0001)
    }

    func testAccuracyIsZeroWithNoAttempts() {
        let result = GameResult(hits: 0, misses: 0, duration: 0)

        XCTAssertEqual(result.accuracy, 0)
    }

    func testAccuracyIsOneWhenOnlyHits() {
        let result = GameResult(hits: 5, misses: 0, duration: 30)

        XCTAssertEqual(result.accuracy, 1.0)
    }

    func testAccuracyIsZeroWhenOnlyMisses() {
        let result = GameResult(hits: 0, misses: 4, duration: 30)

        XCTAssertEqual(result.accuracy, 0)
    }
}
