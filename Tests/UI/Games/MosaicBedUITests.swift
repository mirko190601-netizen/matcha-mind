import Foundation
import XCTest

/// UI-Tests für das Spiel "Das Mosaik-Beet" (MASTER-PROMPT.md, Block B3
/// Aufgabe 5 / P5): a) Anleitung erscheint nur beim ersten Start eines
/// App-Laufs, b) ein Start-bis-Ergebnis-Durchlauf gelingt für alle 3
/// Tee-Stufen.
///
/// Teststrategie fuer eine Runde (siehe `Games/MosaicBed/MosaicBedGameView.swift`
/// und `Games/MosaicBed/MosaicBedGame.swift`): der Hinweis-Button existiert
/// nur bei Sencha (`hintAvailable`), bei Oolong/Matcha nicht - und ein
/// zufaellig befuelltes Gitter wird nie "komplett" (das Raetsel hat laut
/// Gate-Anforderung genau 1 Loesung), wodurch die Runde sonst nie enden
/// wuerde. Dieser Test liest daher die Vorgaben ("givens") jeder Runde über
/// die Accessibility-Labels der Gitterfelder aus und loest das Raetsel mit
/// einem eigenen, in diesem Test-Target bewusst eigenstaendigen
/// Backtracking-Loeser (kein Import des App-Moduls aus einem UI-Test-Target
/// heraus - das laeuft in einem eigenen Prozess). Das Regel-Set (Zeilen-/
/// Spalten-Regel + Nachbar-Verbote je Stufe) ist in `MosaicBedGame.swift`
/// dokumentiert und wird hier als stabile, oeffentliche Spezifikation
/// uebernommen; da jedes generierte Raetsel garantiert genau eine Loesung
/// hat, liefert dieser Loeser immer exakt dieselbe Belegung wie die App.
final class MosaicBedUITests: XCTestCase {
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
        app.launchArguments += ["-uitest-date", "2026-01-15T08:00:00Z"]
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
        let tile = app.buttons[String(localized: "game.mosaicBed.name", defaultValue: "Das Mosaik-Beet")]
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Kachel 'Das Mosaik-Beet' sollte vorhanden sein.")
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

    private func returnToLibrary() {
        continueButton.tap()
        XCTAssertTrue(
            senchaSectionTitle.waitForExistence(timeout: 5),
            "Nach 'Weiter' sollte wieder die Spiele-Bibliothek sichtbar sein."
        )
    }

    // MARK: - Pflanzenarten und Regel-Set je Stufe (siehe `MosaicBedGame.swift`)

    /// Deutsche Accessibility-Namen in fester Reihenfolge, siehe
    /// `MosaicBedGameView.plantAccessibilityName` - Pflanzenarten einer
    /// Stufe sind immer die ersten `gridSize` davon.
    private static let plantNamesInOrder = ["Blatt", "Tropfen", "Sonne", "Stern", "Mond", "Flamme"]

    private func gridSize(for level: String) -> Int {
        switch level {
        case "oolong": 5
        case "matcha": 6
        default: 4
        }
    }

    /// Verbotene Nachbar-Paare je Stufe (Regel 3/4 aus `MosaicBedGame.swift`).
    private func forbiddenAdjacentPairs(for level: String) -> [(String, String)] {
        switch level {
        case "oolong": [("Sonne", "Mond")]
        case "matcha": [("Sonne", "Mond"), ("Blatt", "Flamme")]
        default: []
        }
    }

    // MARK: - Raetsel lesen und loesen

    private func cellButton(row: Int, col: Int) -> XCUIElement {
        let prefix = String(
            format: String(localized: "game.mosaicBed.cellPosition", defaultValue: "Feld Reihe %lld, Spalte %lld"),
            row + 1,
            col + 1
        )
        return app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// Liest die aktuellen Vorgaben ("givens") des sichtbaren Raetsels aus
    /// den Accessibility-Labels der Gitterfelder (siehe
    /// `MosaicBedGameView.accessibilityLabel(row:col:value:isGiven:)`: ein
    /// vorgegebenes Feld endet auf " vorgegeben").
    private func readGivens(gridSize: Int) -> [[String?]] {
        var givens: [[String?]] = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        let vorgegebenSuffix = " vorgegeben"

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = cellButton(row: row, col: col)
                guard cell.exists, cell.label.hasSuffix(vorgegebenSuffix) else { continue }

                let withoutSuffix = String(cell.label.dropLast(vorgegebenSuffix.count))
                guard let lastComma = withoutSuffix.lastIndex(of: ",") else { continue }
                let plantName = String(withoutSuffix[withoutSuffix.index(after: lastComma)...])
                    .trimmingCharacters(in: .whitespaces)
                givens[row][col] = plantName
            }
        }
        return givens
    }

    /// Eigenstaendiger Backtracking-Loeser (siehe Datei-Kommentar oben):
    /// findet die (laut Gate-Anforderung eindeutige) vollstaendige Belegung,
    /// die zu den gegebenen `givens` passt.
    private func solve(
        gridSize: Int,
        givens: [[String?]],
        forbiddenPairs: [(String, String)]
    ) -> [[String]]? {
        let plantTypes = Array(Self.plantNamesInOrder.prefix(gridSize))
        var grid = givens

        func forbids(_ a: String, _ b: String) -> Bool {
            forbiddenPairs.contains { $0.0 == a && $0.1 == b || $0.0 == b && $0.1 == a }
        }

        func isValid(_ type: String, row: Int, col: Int) -> Bool {
            for c in 0..<gridSize where grid[row][c] == type { return false }
            for r in 0..<gridSize where grid[r][col] == type { return false }
            if row > 0, let up = grid[row - 1][col], forbids(up, type) { return false }
            if col > 0, let left = grid[row][col - 1], forbids(left, type) { return false }
            return true
        }

        func backtrack(_ index: Int) -> Bool {
            guard index < gridSize * gridSize else { return true }
            let row = index / gridSize
            let col = index % gridSize

            if grid[row][col] != nil {
                return backtrack(index + 1)
            }
            for type in plantTypes {
                guard isValid(type, row: row, col: col) else { continue }
                grid[row][col] = type
                if backtrack(index + 1) { return true }
                grid[row][col] = nil
            }
            return false
        }

        guard backtrack(0) else { return nil }
        return grid.map { row in row.map { $0! } }
    }

    /// Zyklus-Position des aktuell angezeigten Werts eines Feldes: 0 = leer,
    /// sonst 1-basierter Index in `plantTypes` + 1 (siehe
    /// `MosaicBedGameView.nextPlantType`: leer -> erste Art -> ... -> wieder
    /// leer). Wird gebraucht, weil `playUntilResult` dieselbe Runde mehrfach
    /// neu abzutippen versucht, bis der Ergebnis-Screen erscheint - ohne
    /// diese Ist-Abfrage würde ein zweiter Aufruf jede schon korrekt
    /// gefüllte Zelle einfach weiterdrehen und damit wieder falsch machen.
    private func cyclePosition(row: Int, col: Int, plantTypes: [String]) -> Int {
        let cell = cellButton(row: row, col: col)
        guard cell.exists, let lastComma = cell.label.lastIndex(of: ",") else { return 0 }
        var value = String(cell.label[cell.label.index(after: lastComma)...]).trimmingCharacters(in: .whitespaces)
        if value.hasSuffix(" vorgegeben") {
            value = String(value.dropLast(" vorgegeben".count))
        }
        guard let index = plantTypes.firstIndex(of: value) else { return 0 }
        return index + 1
    }

    /// Liest das aktuell sichtbare Raetsel, loest es, und tippt jedes leere
    /// Feld so oft an, wie es - ausgehend von seinem AKTUELLEN Zyklus-Stand,
    /// nicht von "leer" - bis zur Loesungsart braucht. Idempotent: ein
    /// erneuter Aufruf auf demselben (ggf. teilweise gefuellten) Raetsel
    /// tippt nur noch den fehlenden Rest, statt bereits korrekte Felder zu
    /// verstellen.
    private func solveAndFillCurrentPuzzle(level: String) {
        let size = gridSize(for: level)
        let plantTypes = Array(Self.plantNamesInOrder.prefix(size))
        let givens = readGivens(gridSize: size)
        let cycleLength = plantTypes.count + 1

        guard let solution = solve(gridSize: size, givens: givens, forbiddenPairs: forbiddenAdjacentPairs(for: level)) else {
            XCTFail("Konnte kein gültiges Mosaik-Beet-Rätsel (Rastergröße \(size)) lösen.")
            return
        }

        for row in 0..<size {
            for col in 0..<size where givens[row][col] == nil {
                guard let targetIndex = plantTypes.firstIndex(of: solution[row][col]) else { continue }
                let targetPosition = targetIndex + 1
                let currentPosition = cyclePosition(row: row, col: col, plantTypes: plantTypes)
                let tapsNeeded = ((targetPosition - currentPosition) % cycleLength + cycleLength) % cycleLength
                guard tapsNeeded > 0 else { continue }

                // Frisch abfragen statt eine Referenz wiederzuverwenden: das
                // Label (und damit u. U. die Trefferflaeche) aendert sich
                // nach jedem Tipp.
                for _ in 0..<tapsNeeded {
                    let cell = cellButton(row: row, col: col)
                    guard cell.exists, cell.isHittable else { break }
                    cell.tap()
                }
            }
        }
    }

    /// Loest wiederholt neue Raetsel (siehe `MosaicBedGameView.checkCompletion()`:
    /// nach jedem geloesten Raetsel startet automatisch das naechste, solange
    /// die Zielspieldauer noch nicht erreicht ist), bis der Ergebnis-Screen
    /// sichtbar ist.
    private func playUntilResult(level: String, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if resultTitle.waitForExistence(timeout: 1) { return }
            solveAndFillCurrentPuzzle(level: level)
        }

        XCTFail("Ergebnis-Screen 'Runde geschafft' wurde nicht innerhalb von \(timeout)s sichtbar (Mosaik-Beet, \(level)).")
    }

    // MARK: - Tests

    func test_instructionsShowOnlyOnFirstStartPerAppRun() throws {
        launch()
        openGamesTab()
        openGameTile()
        skipInstructions()

        playUntilResult(level: "sencha", timeout: 150)
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
        playUntilResult(level: gameLevel, timeout: 150)
        returnToLibrary()
    }
}
