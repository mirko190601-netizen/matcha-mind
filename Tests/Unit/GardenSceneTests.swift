import XCTest
@testable import MatchaMind

/// Prüft `GardenLockLabel` aus `Illustration/GardenScene.swift`
/// (MASTER-PROMPT.md B2 P6): Text der Schloss-Chips für die gesperrten
/// Gartenbereiche muss zu den Schlüsseln `garden.locked.oolong` und
/// `garden.locked.matcha` in `Resources/Localizable.xcstrings` passen.
/// Die Komposition von `GardenScene` selbst (ZStack-Ebenen, Positionierung,
/// Deckkraft) lässt sich ohne UI-Testframework/ViewInspector nicht aus der
/// Logik heraus prüfen - dieses Projekt führt dafür keine neue Abhängigkeit
/// ein (siehe MASTER-PROMPT.md "keine neuen Abhängigkeiten ohne
/// ausdrücklichen Auftrag"); außerdem steht in dieser Umgebung kein
/// macOS/Xcode zur Verfügung, daher konnte auch dieser Test nicht
/// kompiliert oder ausgeführt werden - siehe offene Punkte in der
/// Commit-Antwort.
final class GardenSceneTests: XCTestCase {

    func testOolongLockLabelMatchesStringCatalogValue() {
        XCTAssertEqual(GardenLockLabel.oolong.text, "ab Oolong")
    }

    func testMatchaLockLabelMatchesStringCatalogValue() {
        XCTAssertEqual(GardenLockLabel.matcha.text, "ab Matcha")
    }

    func testLockLabelsAreDistinctAndNonEmpty() {
        let texts = [GardenLockLabel.oolong, .matcha].map(\.text)
        XCTAssertTrue(texts.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(texts).count, texts.count)
    }

    func testGardenSceneInitStoresUnlockFlagsViaStableInit() {
        // GardenScene selbst hat keine oeffentlichen, lesbaren Properties
        // (SwiftUI View-Struct) - dieser Test belegt zumindest, dass der
        // oeffentliche Initializer mit beiden Bool-Kombinationen aufrufbar
        // bleibt (Kompilier-Stabilitaet des oeffentlichen API).
        _ = GardenScene(oolongUnlocked: false, matchaUnlocked: false)
        _ = GardenScene(oolongUnlocked: true, matchaUnlocked: false)
        _ = GardenScene(oolongUnlocked: false, matchaUnlocked: true)
        _ = GardenScene(oolongUnlocked: true, matchaUnlocked: true)
    }
}
