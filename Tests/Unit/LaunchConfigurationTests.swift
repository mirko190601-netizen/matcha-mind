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
}

#endif
