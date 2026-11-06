import XCTest

/// Spiele, die der Teepause-Treiber wirklich bis zum Ergebnis spielt. Die
/// Kennungen sind die Werte von `-uitest-teabreak-games`. Mosaik-Beet und
/// Teeblaetter fehlen bewusst: ihre Treiber (Loeser, Regelwechsel) bleiben in
/// den eigenen Spiel-Tests; hier geht es um den Ablauf der Teepause.
enum TeaBreakGame: String {
    case teapotRow = "teapot-row"
    case fireflyPond = "firefly-pond"
    case bambooMath = "bamboo-math"
}

/// Treiber fuer die Teepause im UI-Test: Garten -> Uebersicht -> drei Spiele
/// (jeweils Anleitung ueberspringen, Runde spielen, Ergebnis bestaetigen) ->
/// Abschluss. Die Runden enden an der echten Systemuhr (75 s je Spiel, siehe
/// `GameSession` mit `SystemClock`); das feste Datum aus `-uitest-date` laesst
/// den Rundenfortschritt unberuehrt. Die Spiel-Treiber entsprechen denen in
/// `Tests/UI/Games/`.
extension UITestCase {
    private static let roundTimeout: TimeInterval = 150

    private var skipInstructionsButton: XCUIElement {
        app.buttons[String(localized: "game.instruction.skip", defaultValue: "Überspringen")]
    }

    private var resultTitle: XCUIElement {
        app.staticTexts[String(localized: "game.result.title", defaultValue: "Runde geschafft")]
    }

    private var resultContinueButton: XCUIElement {
        app.buttons[String(localized: "game.result.continue", defaultValue: "Weiter")]
    }

    // MARK: - Ablauf

    /// Garten -> "Teepause starten" -> Uebersicht mit drei Karten -> "Los geht's".
    func startTeaBreak() {
        openGardenTab()
        tap("teabreak.start")

        XCTAssertTrue(element("teabreak.card").waitForExistence(timeout: 10), "Uebersicht der Teepause sollte erscheinen.")
        let cards = app.descendants(matching: .any).matching(identifier: "teabreak.card")
        XCTAssertEqual(cards.count, 3, "Die Teepause sollte genau drei Spiele zeigen.")

        tap("teabreak.go")
    }

    /// Spielt die Spiele der Reihe nach bis zum Ergebnis und bestaetigt jedes.
    func playTeaBreakGames(_ games: [TeaBreakGame] = UITestCase.teaBreakGames) {
        for game in games {
            playGameToResult(game)
            XCTAssertTrue(resultContinueButton.waitForExistence(timeout: 10), "'Weiter' nach dem Ergebnis fehlt.")
            resultContinueButton.tap()
        }
    }

    /// Abschluss -> "Zurueck in den Garten".
    func closeTeaBreak() {
        tap("teabreak.back")
        XCTAssertTrue(element("garden.scene").waitForExistence(timeout: 10), "Der Garten sollte wieder sichtbar sein.")
    }

    // MARK: - Tau

    /// Tau-Stand aus dem Label der Tau-Anzeige ("12 Tautropfen"); sprachunabhaengig
    /// ueber die enthaltenen Ziffern gelesen.
    func dewAmount(file: StaticString = #filePath, line: UInt = #line) -> Int {
        let chip = element("garden.dew")
        XCTAssertTrue(chip.waitForExistence(timeout: 10), "Tau-Anzeige fehlt.", file: file, line: line)
        let digits = chip.label.filter(\.isNumber)
        guard let amount = Int(digits) else {
            XCTFail("Kein Tau-Stand im Label '\(chip.label)'.", file: file, line: line)
            return -1
        }
        return amount
    }

    // MARK: - Spiele

    private func playGameToResult(_ game: TeaBreakGame) {
        XCTAssertTrue(
            skipInstructionsButton.waitForExistence(timeout: 10),
            "Anleitung von '\(game.rawValue)' sollte beim ersten Start erscheinen."
        )
        skipInstructionsButton.tap()

        switch game {
        case .teapotRow:
            playTeapotRow()
        case .fireflyPond:
            // Passives Spiel: die Runde endet von selbst, getippt werden muss nichts.
            XCTAssertTrue(
                resultTitle.waitForExistence(timeout: Self.roundTimeout),
                "Ergebnis von 'Gluehwuermchen' wurde nicht innerhalb von \(Self.roundTimeout)s sichtbar."
            )
        case .bambooMath:
            playBambooMath()
        }
    }

    /// Wiederholt auf "Kanne 1" tippen; falsche Tipps blockieren den Fortschritt nicht.
    private func playTeapotRow() {
        let position1Label = String(
            format: String(localized: "game.teapotRow.position", defaultValue: "Kanne %lld"),
            1
        )
        let deadline = Date().addingTimeInterval(Self.roundTimeout)
        while Date() < deadline {
            if resultTitle.waitForExistence(timeout: 1) { return }
            let teapot = app.buttons[position1Label]
            if teapot.exists, teapot.isEnabled, teapot.isHittable {
                teapot.tap()
            }
        }
        XCTFail("Ergebnis von 'Teekannen-Reihe' wurde nicht innerhalb von \(Self.roundTimeout)s sichtbar.")
    }

    /// Ziffer 0 eingeben und pruefen; falsche Antworten blockieren den Fortschritt nicht.
    private func playBambooMath() {
        let submitLabel = String(localized: "game.bambooMath.submit", defaultValue: "Prüfen")
        let deadline = Date().addingTimeInterval(Self.roundTimeout)
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
        XCTFail("Ergebnis von 'Bambus-Rechnen' wurde nicht innerhalb von \(Self.roundTimeout)s sichtbar.")
    }
}
