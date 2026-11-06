import XCTest

/// Gate-UI-Test der Mitteilungs-Abfrage (MASTER-PROMPT.md, Block B4 Aufgabe 7
/// und 9): bei Begruessung und auf dem Uhrzeit-Screen erscheint kein
/// Systemdialog, erst nach "Erinnerung festlegen" der echte Dialog (ueber
/// Springboard). Ablehnen laesst die App weiterlaufen, "Ohne Erinnerung" fragt nie.
///
/// Gestartet wird mit `-uitest-show-onboarding` UND `-uitest-persona` (ohne
/// Persona waere der Speicher dateibasiert). Der Dialog erscheint nur, solange
/// die Berechtigung des Simulators noch nicht entschieden ist (frisch pro
/// CI-Lauf); die Tests laufen alphabetisch, der Test mit Dialog zuerst.
final class NotificationPromptUITests: UITestCase {
    private var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    private func launchWithOnboarding() {
        launchApp(fixedGames: nil, extraArguments: ["-uitest-show-onboarding"], withDate: false)
    }

    func test_confirmingReminderTimeShowsSystemDialogOnlyThen() throws {
        launchWithOnboarding()

        // Begruessung: kein Systemdialog.
        XCTAssertTrue(element("onboarding.next").waitForExistence(timeout: 10), "Die Begruessung sollte erscheinen.")
        XCTAssertFalse(springboard.alerts.firstMatch.waitForExistence(timeout: 3), "Bei der Begruessung darf kein Systemdialog erscheinen.")

        // Uhrzeit-Screen: ebenfalls kein Systemdialog.
        tap("onboarding.next")
        XCTAssertTrue(element("onboarding.confirm").waitForExistence(timeout: 10), "Der Uhrzeit-Screen sollte erscheinen.")
        XCTAssertFalse(springboard.alerts.firstMatch.waitForExistence(timeout: 3), "Auf dem Uhrzeit-Screen darf kein Systemdialog erscheinen.")

        // Erst nach dem Bestaetigen kommt die echte Abfrage.
        tap("onboarding.confirm")
        let alert = springboard.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 15), "Nach dem Bestaetigen sollte der Systemdialog erscheinen.")
        attachScreenshot("notification-prompt")

        // Ablehnen ("Don't Allow" ist der erste Knopf).
        let deny = alert.buttons.matching(NSPredicate(
            format: "label IN %@", ["Don\u{2019}t Allow", "Don't Allow", "Nicht erlauben", "Ne pas autoriser"]
        )).firstMatch
        (deny.exists ? deny : alert.buttons.element(boundBy: 0)).tap()

        // Die App laeuft weiter und zeigt den Garten; die Zeit bleibt gespeichert.
        XCTAssertTrue(element("garden.scene").waitForExistence(timeout: 15), "Nach dem Ablehnen sollte der Garten erscheinen.")
        openProfileTab()
        XCTAssertTrue(element("profile.reminder.value").waitForExistence(timeout: 10), "Die gewaehlte Zeit bleibt im Profil.")
    }

    func test_skippingTheReminderShowsNoSystemDialog() throws {
        launchWithOnboarding()

        tap("onboarding.next")
        tap("onboarding.skip")

        XCTAssertTrue(element("garden.scene").waitForExistence(timeout: 15), "Nach 'Ohne Erinnerung' sollte der Garten erscheinen.")
        XCTAssertFalse(springboard.alerts.firstMatch.waitForExistence(timeout: 4), "Ohne Erinnerung darf kein Systemdialog erscheinen.")
    }
}
