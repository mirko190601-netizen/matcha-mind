import XCTest
@testable import MatchaMind

/// Prueft `GameRound` (`Games/Core/GameRound.swift`): ohne Override gelten 75 s,
/// der DEBUG-Override verkuerzt sie, ungueltige Werte werden ignoriert.
final class GameRoundTests: XCTestCase {

    override func tearDown() {
        #if DEBUG
        GameRound.overrideSeconds = nil
        #endif
        super.tearDown()
    }

    func testStandardDurationIsSeventyFiveSecondsWithoutOverride() {
        XCTAssertEqual(GameRound.standardDuration, 75)
        XCTAssertEqual(GameRound.duration, 75)
        XCTAssertEqual(GameRound.timeScale, 1)
    }

    #if DEBUG
    func testOverrideShortensTheRound() {
        GameRound.overrideSeconds = 10

        XCTAssertEqual(GameRound.duration, 10)
        XCTAssertEqual(GameRound.timeScale, 10.0 / 75.0, accuracy: 0.0001)
    }

    func testNonPositiveOverrideIsIgnored() {
        GameRound.overrideSeconds = 0
        XCTAssertEqual(GameRound.duration, 75)
        GameRound.overrideSeconds = -5
        XCTAssertEqual(GameRound.duration, 75)
    }
    #endif
}
