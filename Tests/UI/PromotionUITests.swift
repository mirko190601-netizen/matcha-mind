import XCTest

/// Gate-UI-Tests des Aufstiegs (MASTER-PROMPT.md, Block B4 Aufgabe 2 und 9):
/// per `-uitest-seed` und `-uitest-date` steht der Spieler einen Tag vor dem
/// Aufstieg; die Teepause wird wirklich gespielt, dann erscheint der
/// Aufstiegs-Moment. Dazu "Lieber noch bleiben", manuelle Stufenwahl und
/// ausgeschalteter Auto-Aufstieg.
///
/// Stufen im Stufen-Screen: 0 Sencha, 1 Oolong, 2 Matcha.
final class PromotionUITests: UITestCase {

    func test_senchaPlayerIsOfferedOolongAndAccepts() throws {
        launchApp(seed: "promotion-oolong")
        startTeaBreak()
        playTeaBreakGames()

        tap("promotion.accept")
        closeTeaBreak()

        assertSelectedLevel(1)
    }

    func test_oolongPlayerIsOfferedMatchaAndAccepts() throws {
        launchApp(seed: "promotion-matcha")
        startTeaBreak()
        playTeaBreakGames()

        tap("promotion.accept")
        closeTeaBreak()

        assertSelectedLevel(2)
    }

    func test_decliningThePromotionKeepsTheLevel() throws {
        launchApp(seed: "promotion-oolong")
        startTeaBreak()
        playTeaBreakGames()

        tap("promotion.defer")
        closeTeaBreak()

        assertSelectedLevel(0)
    }

    func test_autoAdvanceOffShowsNoOfferAfterTeaBreak() throws {
        launchApp(seed: "promotion-oolong")

        // Schalter im Stufen-Screen ausschalten, dann die Teepause spielen.
        openLevelSettings()
        setSwitch("level.auto", on: false)

        startTeaBreak()
        playTeaBreakGames()

        XCTAssertTrue(element("teabreak.back").waitForExistence(timeout: 10), "Der Abschluss der Teepause fehlt.")
        XCTAssertFalse(element("promotion.accept").waitForExistence(timeout: 3), "Mit Auto-Aufstieg aus gibt es kein Angebot.")
        closeTeaBreak()

        assertSelectedLevel(0)
    }

    func test_manualLevelChoiceIsKeptAndAutoSwitchWorks() throws {
        launchApp()
        openLevelSettings()

        tap("level.option.1")
        XCTAssertTrue(element("level.option.1").isSelected, "Oolong sollte gewaehlt sein.")
        XCTAssertFalse(element("level.option.0").isSelected)

        tap("level.option.2")
        XCTAssertTrue(element("level.option.2").isSelected, "Matcha sollte gewaehlt sein.")
        XCTAssertFalse(element("level.option.1").isSelected)

        setSwitch("level.auto", on: false)
        setSwitch("level.auto", on: true)

        // Die Wahl bleibt nach einem Wechsel des Tabs bestehen.
        openGardenTab()
        assertSelectedLevel(2)
    }
}
