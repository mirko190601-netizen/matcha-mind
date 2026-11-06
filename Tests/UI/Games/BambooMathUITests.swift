import XCTest

/// UI-Tests für das Spiel "Bambus-Rechnen" (MASTER-PROMPT.md, Block B3
/// Aufgabe 5 / P5): a) Anleitung erscheint nur beim ersten Start eines
/// App-Laufs, b) ein Start-bis-Ergebnis-Durchlauf gelingt für alle 3
/// Tee-Stufen. Folgt dem Diagnose-Muster aus `Tests/UI/AppLaunchUITests.swift`
/// (Screenshot + Element-Hierarchie bei Fehlschlag).
///
/// Teststrategie fuer eine Runde (siehe `Games/BambooMath/BambooMathGameView.swift`):
/// die Zifferntasten haben kein eigenes Accessibility-Label - SwiftUI nutzt
/// automatisch den angezeigten `Text`-Inhalt ("0", "1", ... "9") als Label,
/// das reicht als stabiler Selektor. Eine falsche Antwort zaehlt nur als
/// Fehler, blockiert aber nicht den Rundenfortschritt - es reicht, wiederholt
/// die Ziffer "0" einzugeben und "Prüfen" zu tippen.
final class BambooMathUITests: XCTestCase {
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

    // MARK: - Navigation

    private func launch(gameLevel: String? = nil) {
        app = XCUIApplication()
        app.launchArguments += ["-uitest-date", "2026-01-15T08:00:00Z", "-uitest-persona", "tea", "-uitest-round-seconds", "10"]
        if let gameLevel {
            app.launchArguments += ["-uitest-game-level", gameLevel]
        }
        app.launch()
    }

    private func openGamesTab() {
        let gamesTab = app.buttons.matching(
            NSPredicate(format: "label == %@", String(localized: "tab.games.title", defaultValue: "Spiele"))
        ).firstMatch
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 5), "Tab 'Spiele' sollte vorhanden sein.")
        gamesTab.tap()

        XCTAssertTrue(
            senchaSectionTitle.waitForExistence(timeout: 5),
            "Spiele-Bibliothek sollte nach dem Tab-Wechsel sichtbar sein."
        )
    }

    private func openGameTile() {
        let tile = app.buttons[String(localized: "game.bambooMath.name", defaultValue: "Bambus-Rechnen")]
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Kachel 'Bambus-Rechnen' sollte vorhanden sein.")
        tile.tap()
    }

    private var senchaSectionTitle: XCUIElement {
        app.staticTexts[String(localized: "games.section.sencha", defaultValue: "Sencha")]
    }

    private var skipInstructionsButton: XCUIElement {
        app.buttons[String(localized: "game.instruction.skip", defaultValue: "Überspringen")]
    }

    private func skipInstructions() {
        XCTAssertTrue(
            skipInstructionsButton.waitForExistence(timeout: 5),
            "Anleitung sollte beim ersten Start dieses Spiels sichtbar sein."
        )
        skipInstructionsButton.tap()
    }

    private var resultTitle: XCUIElement {
        app.staticTexts[String(localized: "game.result.title", defaultValue: "Runde geschafft")]
    }

    private var continueButton: XCUIElement {
        app.buttons[String(localized: "game.result.continue", defaultValue: "Weiter")]
    }

    private func playOneRoundToResult(timeout: TimeInterval) {
        let submitLabel = String(localized: "game.bambooMath.submit", defaultValue: "Prüfen")
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if resultTitle.waitForExistence(timeout: 0.5) { return }

            let digitZero = app.buttons["0"]
            if digitZero.exists, digitZero.isHittable {
                digitZero.tap()
            }

            let submit = app.buttons[submitLabel]
            if submit.exists, submit.isEnabled, submit.isHittable {
                submit.tap()
            }
        }

        XCTFail("Ergebnis-Screen 'Runde geschafft' wurde nicht innerhalb von \(timeout)s sichtbar.")
    }

    private func returnToLibrary() {
        continueButton.tap()
        XCTAssertTrue(
            senchaSectionTitle.waitForExistence(timeout: 5),
            "Nach 'Weiter' sollte wieder die Spiele-Bibliothek sichtbar sein."
        )
    }

    // MARK: - Tests

    func test_instructionsShowOnlyOnFirstStartPerAppRun() throws {
        launch()
        openGamesTab()
        openGameTile()
        skipInstructions()

        playOneRoundToResult(timeout: 150)
        returnToLibrary()

        openGameTile()
        XCTAssertFalse(
            skipInstructionsButton.waitForExistence(timeout: 2),
            "Anleitung sollte beim zweiten Start in diesem App-Lauf nicht mehr erscheinen."
        )
    }

    func test_senchaRoundCompletes() throws {
        try runFullRound(gameLevel: "sencha")
    }

    func test_oolongRoundCompletes() throws {
        try runFullRound(gameLevel: "oolong")
    }

    func test_matchaRoundCompletes() throws {
        try runFullRound(gameLevel: "matcha")
    }

    private func runFullRound(gameLevel: String) throws {
        launch(gameLevel: gameLevel)
        openGamesTab()
        openGameTile()
        skipInstructions()
        playOneRoundToResult(timeout: 150)
        returnToLibrary()
    }
}
