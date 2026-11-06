import XCTest

/// Gate-UI-Test Teepause komplett (MASTER-PROMPT.md, Block B4 Aufgabe 9):
/// Garten -> Uebersicht -> alle drei Spiele wirklich bis zum Ergebnis ->
/// Abschluss -> Garten. Der Tau-Stand steigt um 3 x 12; das ist die erste
/// Wachstumsstufe des Gartens (`GardenGrowth.thresholds[1]` = 36), der Garten
/// aendert sich also sichtbar. Screenshots `garden-before` und `garden-after`
/// bleiben immer erhalten.
///
/// Die Spiele sind per `-uitest-teabreak-games` festgelegt (kein Zufall), werden
/// aber nicht uebersprungen. Die Runden laufen an der Systemuhr (je 75 s); das
/// feste Datum aus `-uitest-date` beeinflusst sie nicht.
final class TeaBreakFlowUITests: UITestCase {
    /// Tau je Spiel (`PlayerStore.dewPerGame`) und erste Wachstumsstufe.
    private let dewPerGame = 12
    private let firstGrowthThreshold = 36

    func test_fullTeaBreakEarnsDewAndGrowsGarden() throws {
        // Bewusst echte 75-Sekunden-Runden: das ist der Gate-Nachweis.
        launchApp(roundSeconds: nil)
        openGardenTab()
        XCTAssertTrue(element("garden.scene").waitForExistence(timeout: 10), "Der Garten sollte sichtbar sein.")

        let dewBefore = dewAmount()
        XCTAssertEqual(dewBefore, 0, "Ein frischer Spielstand startet ohne Tau.")
        attachScreenshot("garden-before")

        startTeaBreak()
        playTeaBreakGames()
        closeTeaBreak()

        let dewAfter = dewAmount()
        XCTAssertEqual(
            dewAfter - dewBefore, Self.teaBreakGames.count * dewPerGame,
            "Jedes der drei Spiele bringt 12 Tau."
        )
        XCTAssertGreaterThanOrEqual(dewAfter, firstGrowthThreshold, "Der Garten sollte Wachstumsstufe 1 erreicht haben.")
        XCTAssertFalse(element("teabreak.start").exists, "Nach der Teepause steht der Einstieg nicht mehr da.")
        attachScreenshot("garden-after")
    }
}
