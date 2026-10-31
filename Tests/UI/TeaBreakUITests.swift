import XCTest

/// UI-Test für die Teepause (MASTER-PROMPT.md, Block B4 Aufgabe 3): vom
/// Garten-Tab über den Knopf "Teepause starten" zur Übersicht mit drei
/// Spielkarten, weiter mit "Los geht's" bis das erste Spiel erscheint.
///
/// Startet mit `-uitest-persona tea` (Spielerdaten nur im Arbeitsspeicher, siehe
/// `App/MatchaMindApp.swift`), damit der Lauf unabhängig von früheren
/// Läufen ist. Folgt dem Diagnose-Muster der anderen UI-Tests (Screenshot
/// und Element-Hierarchie bei Fehlschlag).
final class TeaBreakUITests: XCTestCase {
    private var app: XCUIApplication!
    private var testFailed = false

    override func record(_ issue: XCTIssue) {
        testFailed = true
        super.record(issue)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        if testFailed {
            attachFailureDiagnostics()
        }
        super.tearDown()
    }

    private func attachFailureDiagnostics() {
        guard let app else { return }

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "failure-screenshot"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "failure-element-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    /// Element über seinen Accessibility-Identifier, unabhängig vom Elementtyp.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func test_teaBreakShowsOverviewWithThreeCardsAndStartsFirstGame() throws {
        app.launchArguments += [
            "-uitest-date", "2026-01-15T08:00:00Z",
            "-uitest-persona", "tea",
        ]
        app.launch()

        // Garten-Tab ist der Startbildschirm; sicherheitshalber antippen.
        let gardenTab = app.buttons.matching(
            NSPredicate(format: "label == %@", String(localized: "tab.garden.title", defaultValue: "Garten"))
        ).firstMatch
        XCTAssertTrue(gardenTab.waitForExistence(timeout: 5), "Tab 'Garten' sollte vorhanden sein.")
        gardenTab.tap()

        let startButton = element("teabreak.start")
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Knopf 'Teepause starten' sollte sichtbar sein.")
        startButton.tap()

        let overviewTitle = app.staticTexts[
            String(localized: "teabreak.overview.title", defaultValue: "Deine Teepause")
        ]
        XCTAssertTrue(overviewTitle.waitForExistence(timeout: 5), "Übersicht der Teepause sollte erscheinen.")

        XCTAssertTrue(element("teabreak.card").waitForExistence(timeout: 5))
        let cards = app.descendants(matching: .any).matching(identifier: "teabreak.card")
        XCTAssertEqual(cards.count, 3, "Die Teepause sollte genau drei Spiele zeigen.")

        let goButton = element("teabreak.go")
        XCTAssertTrue(goButton.waitForExistence(timeout: 5), "Knopf 'Los geht's' sollte vorhanden sein.")
        goButton.tap()

        // Alle fünf Spiele zeigen beim ersten Start die Anleitung mit "Überspringen".
        let skipButton = app.buttons[String(localized: "game.instruction.skip", defaultValue: "Überspringen")]
        XCTAssertTrue(
            skipButton.waitForExistence(timeout: 5),
            "Das erste Spiel sollte mit seiner Anleitung erscheinen."
        )
    }
}
