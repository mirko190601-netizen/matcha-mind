import XCTest

/// Gemeinsame Basis der Gate-UI-Tests aus Block B4 (Teepause, Aufstieg, Stufen,
/// Mitteilungs-Abfrage, Verlauf, Profil). Bringt das Diagnose-Muster der
/// anderen UI-Tests mit (Screenshot und Element-Hierarchie bei Fehlschlag)
/// sowie kleine Hilfen fuer Start, Tabs, Identifier und Screenshots.
///
/// Alle Tests starten mit `-uitest-persona tea`: Spielerdaten liegen dann nur
/// im Arbeitsspeicher, jeder Lauf beginnt leer (oder mit einem Seed).
class UITestCase: XCTestCase {
    var app: XCUIApplication!
    private var testFailed = false

    /// Drei Spiele ohne Zufall, mit einfachen Treibern (siehe `TeaBreakDriver`).
    static let teaBreakGames: [TeaBreakGame] = [.teapotRow, .fireflyPond, .bambooMath]

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

    // MARK: - Start

    /// Startet die App mit Persona und festem Datum.
    /// - Parameters:
    ///   - seed: Wert fuer `-uitest-seed` (`promotion-oolong`, `promotion-matcha`).
    ///   - fixedGames: legt die Spiele der Teepause fest (Standard: `teaBreakGames`).
    ///   - extraArguments: weitere Startargumente (z. B. `-uitest-show-onboarding`).
    ///   - withDate: setzt `-uitest-date`; der Erststart-Test braucht die Systemzeit.
    ///   - roundSeconds: verkuerzte Rundendauer (Standard 10 s); `nil` = echte 75 s.
    func launchApp(
        seed: String? = nil,
        fixedGames: [TeaBreakGame]? = UITestCase.teaBreakGames,
        extraArguments: [String] = [],
        withDate: Bool = true,
        roundSeconds: Int? = 10
    ) {
        var arguments = ["-uitest-persona", "tea"]
        if withDate {
            arguments += ["-uitest-date", "2026-01-15T08:00:00Z"]
        }
        if let roundSeconds {
            arguments += ["-uitest-round-seconds", String(roundSeconds)]
        }
        if let seed {
            arguments += ["-uitest-seed", seed]
        }
        if let fixedGames {
            arguments += ["-uitest-teabreak-games", fixedGames.map(\.rawValue).joined(separator: ",")]
        }
        app.launchArguments += arguments + extraArguments
        app.launch()
    }

    // MARK: - Elemente

    /// Element ueber seinen Accessibility-Identifier, unabhaengig vom Elementtyp.
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Wartet auf ein Element und tippt es an.
    func tap(_ identifier: String, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: timeout), "'\(identifier)' sollte sichtbar sein.", file: file, line: line)
        target.tap()
    }

    // MARK: - Tabs (iPhone: Tab-Leiste, iPad: Seitenleiste; beides sind Buttons mit dem Titel)

    func openTab(_ title: String) {
        let tab = app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Tab '\(title)' sollte vorhanden sein.")
        tab.tap()
    }

    func openGardenTab() {
        openTab(String(localized: "tab.garden.title", defaultValue: "Garten"))
    }

    func openHistoryTab() {
        openTab(String(localized: "tab.history.title", defaultValue: "Verlauf"))
    }

    func openProfileTab() {
        openTab(String(localized: "tab.profile.title", defaultValue: "Profil"))
    }

    // MARK: - Stufen-Screen

    /// Profil -> Stufe (der Stufen-Screen liegt hinter einem Navigationslink).
    func openLevelSettings() {
        openProfileTab()
        // Der Navigationsstapel des Profil-Tabs bleibt beim Tab-Wechsel erhalten.
        if !element("level.option.0").waitForExistence(timeout: 2) {
            tap("profile.level")
        }
        XCTAssertTrue(element("level.option.0").waitForExistence(timeout: 10), "Stufen-Screen sollte erscheinen.")
    }

    /// Pruefung der gewaehlten Stufe (0 Sencha, 1 Oolong, 2 Matcha) im Stufen-Screen.
    func assertSelectedLevel(_ rawValue: Int, file: StaticString = #filePath, line: UInt = #line) {
        openLevelSettings()
        for candidate in 0...2 {
            let option = element("level.option.\(candidate)")
            XCTAssertEqual(
                option.isSelected, candidate == rawValue,
                "Stufe \(candidate) sollte \(candidate == rawValue ? "" : "nicht ")gewaehlt sein.",
                file: file, line: line
            )
        }
    }

    /// Schaltet einen Schalter auf den gewuenschten Zustand. Getippt wird am
    /// rechten Rand (dort sitzt der Schalter), danach in der Mitte, falls noetig.
    func setSwitch(_ identifier: String, on: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[identifier]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Schalter '\(identifier)' fehlt.", file: file, line: line)
        let wanted = on ? "1" : "0"
        if (toggle.value as? String) != wanted {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        }
        if (toggle.value as? String) != wanted {
            toggle.tap()
        }
        XCTAssertEqual(toggle.value as? String, wanted, "Schalter '\(identifier)' hat den falschen Zustand.", file: file, line: line)
    }

    // MARK: - Screenshots

    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
