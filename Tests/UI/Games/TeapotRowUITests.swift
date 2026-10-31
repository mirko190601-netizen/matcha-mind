import XCTest

/// UI-Tests für das Spiel "Teekannen-Reihe" (MASTER-PROMPT.md, Block B3
/// Aufgabe 5 / P5): a) Anleitung erscheint nur beim ersten Start eines
/// App-Laufs, b) ein Start-bis-Ergebnis-Durchlauf gelingt für alle 3
/// Tee-Stufen. Folgt dem Diagnose-Muster aus `Tests/UI/AppLaunchUITests.swift`
/// (Screenshot + Element-Hierarchie bei Fehlschlag).
///
/// Teststrategie fuer eine Runde (siehe `Games/TeapotRow/TeapotRowGameView.swift`):
/// es reicht, wiederholt auf Position 1 ("Kanne 1") zu tippen, solange sie
/// antippbar ist - falsche Tipps zaehlen nur gegen die Feinstufe, blockieren
/// den Rundenfortschritt aber nicht. Die Runde endet automatisch, sobald die
/// echte Spielzeit (Systemuhr, siehe `Games/Core/GameSession.swift`) die
/// Zielspieldauer (75 s) erreicht.
final class TeapotRowUITests: XCTestCase {
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
        app.launchArguments += ["-uitest-date", "2026-01-15T08:00:00Z", "-uitest-persona", "tea"]
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
        let tile = app.buttons[String(localized: "game.teapotRow.name", defaultValue: "Teekannen-Reihe")]
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Kachel 'Teekannen-Reihe' sollte vorhanden sein.")
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
        let position1Label = String(
            format: String(localized: "game.teapotRow.position", defaultValue: "Kanne %lld"),
            1
        )
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if resultTitle.waitForExistence(timeout: 1) { return }
            let teapot = app.buttons[position1Label]
            if teapot.exists, teapot.isEnabled, teapot.isHittable {
                teapot.tap()
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
