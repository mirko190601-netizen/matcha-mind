import XCTest
@testable import MatchaMind

/// Prüft `AppEnvironment` (`App/AppEnvironment.swift`): Standardwerte und
/// Injektion von Clock/Persona.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class AppEnvironmentTests: XCTestCase {

    func testDefaultEnvironmentUsesSystemClockAndIsNotUITesting() {
        let environment = AppEnvironment()

        XCTAssertTrue(environment.clock is SystemClock)
        XCTAssertFalse(environment.isUITesting)
        XCTAssertNil(environment.personaID)
    }

    func testCustomClockAndPersonaAreInjected() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T08:00:00Z")!
        let clock = FixedClock(date: date)

        let environment = AppEnvironment(clock: clock, isUITesting: true, personaID: "lena")

        XCTAssertEqual(environment.clock.now(), date)
        XCTAssertTrue(environment.isUITesting)
        XCTAssertEqual(environment.personaID, "lena")
    }

    #if DEBUG
    func testDefaultEnvironmentHasNoForcedTeaBreakGames() {
        XCTAssertEqual(AppEnvironment().forcedTeaBreakGameIDs, [])
    }

    func testForcedTeaBreakGamesComeFromLaunchArgumentsOnlyWithPersona() {
        let withPersona = AppEnvironment.make(from: LaunchConfiguration.makeConfiguration(
            arguments: ["App", "-uitest-persona", "tea", "-uitest-teabreak-games", "teapot-row,bamboo-math"]
        ))
        XCTAssertEqual(withPersona.forcedTeaBreakGameIDs, ["teapot-row", "bamboo-math"])

        let withoutPersona = AppEnvironment.make(from: LaunchConfiguration.makeConfiguration(
            arguments: ["App", "-uitest-teabreak-games", "teapot-row,bamboo-math"]
        ))
        XCTAssertEqual(withoutPersona.forcedTeaBreakGameIDs, [])
    }
    #endif
}
