import XCTest
@testable import MatchaMind

// `LaunchConfiguration` existiert nur in DEBUG-Builds (siehe
// MASTER-PROMPT.md Abschnitt 7.5) - dieser Test entsprechend auch.
#if DEBUG

/// Prüft `LaunchConfiguration` (`App/LaunchConfiguration.swift`): parst
/// `-uitest-persona` und `-uitest-date` aus einer Argumentliste.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class LaunchConfigurationTests: XCTestCase {

    func testParsesPersonaAndDateWhenBothArePresent() {
        let configuration = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-persona", "lena", "-uitest-date", "2026-01-15T08:00:00Z"]
        )

        XCTAssertEqual(configuration.personaID, "lena")
        XCTAssertEqual(
            configuration.clock?.now(),
            ISO8601DateFormatter().date(from: "2026-01-15T08:00:00Z")
        )
    }

    func testWithoutArgumentsYieldsNilPersonaAndNilClock() {
        let configuration = LaunchConfiguration.makeConfiguration(arguments: ["AppName"])

        XCTAssertNil(configuration.personaID)
        XCTAssertNil(configuration.clock)
    }

    func testPersonaFlagWithoutFollowingValueIsIgnored() {
        let configuration = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-persona"]
        )

        XCTAssertNil(configuration.personaID)
    }

    func testInvalidDateStringYieldsNilClockButKeepsPersona() {
        let configuration = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-persona", "tom", "-uitest-date", "not-a-date"]
        )

        XCTAssertEqual(configuration.personaID, "tom")
        XCTAssertNil(configuration.clock)
    }

    func testParsesGameLevelForEachValidValue() {
        for (argument, expected) in [("sencha", TeaLevel.sencha), ("oolong", .oolong), ("matcha", .matcha)] {
            let configuration = LaunchConfiguration.makeConfiguration(
                arguments: ["AppName", "-uitest-game-level", argument]
            )
            XCTAssertEqual(configuration.gameLevel, expected)
        }
    }

    func testWithoutGameLevelArgumentYieldsNil() {
        let configuration = LaunchConfiguration.makeConfiguration(arguments: ["AppName"])

        XCTAssertNil(configuration.gameLevel)
    }

    func testInvalidGameLevelStringYieldsNil() {
        let configuration = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-game-level", "not-a-level"]
        )

        XCTAssertNil(configuration.gameLevel)
    }

    // MARK: - Seed und feste Teepause-Spiele

    func testParsesSeedForEachValidValue() {
        for (argument, expected) in [("promotion-oolong", UITestSeed.promotionOolong), ("promotion-matcha", .promotionMatcha)] {
            let configuration = LaunchConfiguration.makeConfiguration(
                arguments: ["AppName", "-uitest-persona", "tea", "-uitest-seed", argument]
            )
            XCTAssertEqual(configuration.seed, expected)
            XCTAssertEqual(configuration.effectiveSeed, expected)
        }
    }

    func testUnknownOrMissingSeedYieldsNil() {
        XCTAssertNil(LaunchConfiguration.makeConfiguration(arguments: ["AppName", "-uitest-seed", "other"]).seed)
        XCTAssertNil(LaunchConfiguration.makeConfiguration(arguments: ["AppName", "-uitest-seed"]).seed)
        XCTAssertNil(LaunchConfiguration.makeConfiguration(arguments: ["AppName"]).seed)
    }

    func testSeedIsOnlyEffectiveWithPersona() {
        let configuration = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-seed", "promotion-oolong"]
        )

        XCTAssertEqual(configuration.seed, .promotionOolong)
        XCTAssertNil(configuration.effectiveSeed, "Ohne Persona waere der Speicher dateibasiert")
    }

    func testParsesTeaBreakGamesAsOrderedList() {
        let configuration = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-persona", "tea", "-uitest-teabreak-games", "teapot-row, firefly-pond,bamboo-math"]
        )

        XCTAssertEqual(configuration.teaBreakGameIDs, ["teapot-row", "firefly-pond", "bamboo-math"])
        XCTAssertEqual(configuration.effectiveTeaBreakGameIDs, ["teapot-row", "firefly-pond", "bamboo-math"])
    }

    func testTeaBreakGamesAreEmptyWithoutArgumentAndIgnoredWithoutPersona() {
        XCTAssertEqual(LaunchConfiguration.makeConfiguration(arguments: ["AppName"]).teaBreakGameIDs, [])

        let withoutPersona = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-teabreak-games", "teapot-row"]
        )
        XCTAssertEqual(withoutPersona.teaBreakGameIDs, ["teapot-row"])
        XCTAssertEqual(withoutPersona.effectiveTeaBreakGameIDs, [])
    }

    // MARK: - Rundendauer

    func testParsesRoundSecondsOnlyForPositiveNumbers() {
        func parse(_ value: String) -> TimeInterval? {
            LaunchConfiguration.makeConfiguration(
                arguments: ["AppName", "-uitest-persona", "tea", "-uitest-round-seconds", value]
            ).effectiveRoundSeconds
        }
        XCTAssertEqual(parse("10"), 10)
        XCTAssertEqual(parse("2.5"), 2.5)
        XCTAssertNil(parse("0"))
        XCTAssertNil(parse("-3"))
        XCTAssertNil(parse("abc"))
    }

    func testRoundSecondsAreIgnoredWithoutPersonaAndWithoutArgument() {
        let withoutPersona = LaunchConfiguration.makeConfiguration(
            arguments: ["AppName", "-uitest-round-seconds", "10"]
        )
        XCTAssertEqual(withoutPersona.roundSeconds, 10)
        XCTAssertNil(withoutPersona.effectiveRoundSeconds)
        XCTAssertNil(LaunchConfiguration.makeConfiguration(arguments: ["AppName"]).roundSeconds)
    }
}

#endif
