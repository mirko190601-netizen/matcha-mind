import XCTest

/// Gate aus `MASTER-PROMPT.md`, Block B1 Aufgabe 8: "App startet, alle 4 Tabs
/// oeffnen" - auf iPhone (Tab-Leiste) und iPad (Seitenleiste, Stil
/// `.sidebarAdaptable`, siehe `App/ContentView.swift`).
///
/// Startet die App mit einem festen `-uitest-date`, damit der Lauf
/// deterministisch ist (Infrastruktur dafuer existiert bereits in
/// `App/LaunchConfiguration.swift`, nur im DEBUG-Build aktiv).
final class AppLaunchUITests: XCTestCase {
    /// Tab-Titel und der eindeutige Beschreibungstext des zugehoerigen
    /// Platzhalter-Screens (siehe `App/*PlaceholderView.swift`). Wird von
    /// beiden Testmethoden dieser Klasse verwendet, damit die Liste nicht
    /// doppelt gepflegt werden muss.
    private var tabs: [(title: String, bodyText: String)] {
        [
            (
                String(localized: "tab.garden.title", defaultValue: "Garten"),
                String(localized: "placeholder.garden.body", defaultValue: "Hier wächst bald dein Garten.")
            ),
            // Seit B3 P4 zeigt der "Spiele"-Tab die echte `GamesLibraryView`
            // (keinen Platzhalter mehr) - Erkennungsmerkmal ist deren
            // Sencha-Abschnittstitel, der beim Laden immer sichtbar ist.
            (
                String(localized: "tab.games.title", defaultValue: "Spiele"),
                String(localized: "games.section.sencha", defaultValue: "Sencha")
            ),
            (
                String(localized: "tab.history.title", defaultValue: "Verlauf"),
                String(localized: "placeholder.history.body", defaultValue: "Hier siehst du bald deinen Verlauf.")
            ),
            (
                String(localized: "tab.profile.title", defaultValue: "Profil"),
                String(localized: "placeholder.profile.body", defaultValue: "Hier findest du bald dein Profil.")
            ),
        ]
    }

    /// Instanzvariable statt lokaler Konstante (siehe `MASTER-PROMPT.md`
    /// Abschnitt 3.8 Punkt 1, "Fehler beheben ohne Stillstand"): nur so kann
    /// `tearDown()` bei einem Fehlschlag noch auf dieselbe `XCUIApplication`
    /// zugreifen, um Screenshot und Element-Hierarchie anzuhaengen.
    private var app: XCUIApplication!

    /// Wird von `record(_:)` gesetzt, sobald irgendeine Assertion in diesem
    /// Testlauf fehlschlaegt. Zuverlässiger als `testRun?.hasSucceeded` in
    /// `tearDown()`: das meldete im ersten CI-Lauf dieser Datei faelschlich
    /// "nicht erfolgreich" fuer einen tatsaechlich bestandenen Test (vermutlich
    /// wird `hasSucceeded` erst NACH `tearDown()` final gesetzt), wodurch
    /// `attachFailureDiagnostics()` einen Screenshot vom bereits per
    /// `app.terminate()` beendeten Prozess wollte und selbst fehlschlug.
    private var testFailed = false

    override func record(_ issue: XCTIssue) {
        testFailed = true
        super.record(issue)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Haengt bei jedem Fehlschlag automatisch zwei Diagnose-Anhaenge an das
    /// Testergebnis an (`MASTER-PROMPT.md` 3.8 Punkt 1): einen Screenshot
    /// zum Fehlerzeitpunkt und die Element-Hierarchie (`app.debugDescription`)
    /// als Text-Attachment. So laesst sich die Ursache aus dem
    /// `.xcresult`-Bundle diagnostizieren, ohne den Lauf erneut starten zu
    /// muessen.
    override func tearDown() {
        if testFailed {
            attachFailureDiagnostics()
        }
        super.tearDown()
    }

    private func attachFailureDiagnostics() {
        guard let app else { return }

        attachScreenshot(of: app, named: "failure-screenshot")

        let hierarchyAttachment = XCTAttachment(string: app.debugDescription)
        hierarchyAttachment.name = "failure-element-hierarchy"
        hierarchyAttachment.lifetime = .keepAlways
        add(hierarchyAttachment)
    }

    func test_appStartsAndAllFourTabsOpen() throws {
        app.launchArguments += ["-uitest-date", "2026-01-15T08:00:00Z"]
        app.launch()

        XCTAssertEqual(
            app.state,
            .runningForeground,
            "App sollte nach dem Start ohne Absturz im Vordergrund laufen."
        )

        try openAllTabsAndVerifyPlaceholders(in: app)
    }

    /// Gate-Punkt aus `MASTER-PROMPT.md` Block B1 ("Screenshots hell +
    /// dunkel, iPhone + iPad geprueft: richtige Farben, Schriften, Glas").
    /// Startet die App zweimal - einmal mit erzwungenem hellem, einmal mit
    /// erzwungenem dunklem Farbschema (`-uitest-appearance`, siehe
    /// `App/LaunchConfiguration.swift`) - und haengt nach dem Start sowie
    /// nach jedem Tab-Wechsel einen Screenshot an, damit er im
    /// `.xcresult`-Bundle landet (von `ci.yml` bereits per
    /// `actions/upload-artifact` hochgeladen).
    func test_screenshotsForLightAndDarkAppearance() throws {
        for appearance in ["light", "dark"] {
            app = XCUIApplication()
            app.launchArguments += [
                "-uitest-date", "2026-01-15T08:00:00Z",
                "-uitest-appearance", appearance,
            ]
            app.launch()

            XCTAssertEqual(
                app.state,
                .runningForeground,
                "App sollte mit Farbschema '\(appearance)' ohne Absturz im Vordergrund laufen."
            )

            attachScreenshot(of: app, named: "garden-\(appearance)")

            try openAllTabsAndVerifyPlaceholders(in: app) { tabIndex, tabTitle in
                guard tabIndex == self.tabs.count - 1 else { return }
                attachScreenshot(of: app, named: "\(tabTitle)-\(appearance)")
            }

            app.terminate()
        }
    }

    /// Tippt der Reihe nach alle vier Tabs an und prueft, dass jeweils der
    /// zugehoerige Platzhalter-Screen sichtbar wird. `afterEachTab` wird
    /// nach jedem erfolgreichen Tab-Wechsel mit dem nullbasierten Index und
    /// dem (fuer Dateinamen taeglichen) englischen Kurznamen des Tabs
    /// aufgerufen - zum Beispiel, um gezielt Screenshots anzuhaengen.
    private func openAllTabsAndVerifyPlaceholders(
        in app: XCUIApplication,
        afterEachTab: (Int, String) -> Void = { _, _ in }
    ) throws {
        let shortNames = ["garden", "games", "history", "profile"]

        // Zweiter Fund auf dem CI-Runner: `.isSelected` nach dem Tippen ist
        // zwischen Tab-Leiste (iPhone) und Seitenleiste (iPad) nicht
        // einheitlich zuverlaessig (unterschiedliche UIKit-Elementtypen
        // hinter `.sidebarAdaptable`). Stattdessen wird direkt das
        // eigentliche Gate geprueft: Nach dem Tippen auf einen Tab muss der
        // zugehoerige Platzhalter-Screen sichtbar sein - erkennbar an
        // seinem eindeutigen Beschreibungstext (siehe `App/*PlaceholderView.swift`).
        for (index, tab) in tabs.enumerated() {
            // Auf `.button` eingeschraenkt statt `.any`: sowohl der
            // Tab-Leisten-Button (iPhone) als auch die Seitenleisten-Zeile
            // (iPad) tragen die `.button`-Accessibility-Trait, waehrend
            // `.any` auch das innere Label/Icon ohne Tipp-/Auswahlsemantik
            // treffen kann. `.firstMatch` statt der strikten
            // Eindeutigkeits-Abfrage (`app.buttons[title]`): auf dem iPad
            // (Seitenleiste) meldet die Accessibility-Hierarchie zusaetzlich
            // zur Seitenleisten-Zeile noch ein weiteres Element mit
            // demselben Label (z. B. ein Navigationstitel), wodurch die
            // strikte Abfrage mit "Multiple matching elements found"
            // scheiterte.
            let tabControl = app.buttons.matching(NSPredicate(format: "label == %@", tab.title)).firstMatch
            XCTAssertTrue(
                tabControl.waitForExistence(timeout: 5),
                "Tab '\(tab.title)' sollte in Tab-Leiste (iPhone) oder Seitenleiste (iPad) vorhanden sein."
            )

            tabControl.tap()

            let bodyText = app.staticTexts[tab.bodyText]
            XCTAssertTrue(
                bodyText.waitForExistence(timeout: 5),
                "Nach dem Tippen auf Tab '\(tab.title)' sollte dessen Platzhalter-Screen (Text '\(tab.bodyText)') sichtbar sein."
            )

            afterEachTab(index, shortNames[index])
        }
    }

    /// Erzeugt einen Screenshot der App und haengt ihn als `XCTAttachment`
    /// mit `.lifetime = .keepAlways` an, damit er im `.xcresult`-Bundle
    /// erhalten bleibt (Gate-Punkt "Screenshots hell + dunkel geprueft" aus
    /// `MASTER-PROMPT.md` Block B1).
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
