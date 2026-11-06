import XCTest

/// Gate-UI-Test fuer Verlauf und Profil (MASTER-PROMPT.md, Block B4 Aufgabe 8
/// und 9): beide Tabs oeffnen, die wichtigsten Identifier sind vorhanden,
/// Screenshots `history` und `profile` bleiben immer erhalten.
final class ScreensUITests: UITestCase {

    func test_historyShowsWeeksAndEmptyState() throws {
        launchApp()
        openHistoryTab()

        XCTAssertTrue(element("history.week.0").waitForExistence(timeout: 10), "Die aktuelle Woche fehlt im Verlauf.")
        XCTAssertTrue(element("history.empty").exists, "Ohne Spiele zeigt der Verlauf den ruhigen Leerzustand.")
        attachScreenshot("history")
    }

    func test_profileShowsItsSettings() throws {
        launchApp()
        openProfileTab()

        for identifier in ["profile.level", "profile.autoAdvance", "profile.reminder", "profile.sound", "profile.haptics"] {
            XCTAssertTrue(element(identifier).waitForExistence(timeout: 10), "'\(identifier)' fehlt im Profil.")
        }
        attachScreenshot("profile")
    }
}
