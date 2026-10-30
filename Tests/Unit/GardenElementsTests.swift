import XCTest
@testable import MatchaMind

/// Prüft die Enums aus `Illustration/GardenElements.swift`
/// (MASTER-PROMPT.md B2 P5): jedes Garten-Element muss auf das richtige
/// Image-Set in `Illustration.xcassets` zeigen und einen deutschen
/// Accessibility-Text liefern, der zum entsprechenden Schlüssel in
/// `Resources/Localizable.xcstrings` passt.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort. Die Zuordnung wurde von Hand gegen
/// `Illustration/GardenElements.swift` und `Resources/Localizable.xcstrings`
/// geprüft (analog `Tests/Unit/CreatureIllustrationsTests.swift`).
final class GardenElementsTests: XCTestCase {

    func testTeahouseUsesTeahouseAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.teahouse.assetName, "teahouse")
        XCTAssertEqual(GardenElementKind.teahouse.accessibilityLabel, "Teehaus")
    }

    func testStoneLanternUsesStoneLanternAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.stoneLantern.assetName, "stone-lantern")
        XCTAssertEqual(GardenElementKind.stoneLantern.accessibilityLabel, "Steinlaterne")
    }

    func testMoonBridgeUsesMoonBridgeAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.moonBridge.assetName, "moon-bridge")
        XCTAssertEqual(GardenElementKind.moonBridge.accessibilityLabel, "Mondbrücke")
    }

    func testBambooUsesBambooAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.bamboo.assetName, "bamboo")
        XCTAssertEqual(GardenElementKind.bamboo.accessibilityLabel, "Bambus")
    }

    func testCherryTreeUsesCherryTreeAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.cherryTree.assetName, "cherry-tree")
        XCTAssertEqual(GardenElementKind.cherryTree.accessibilityLabel, "Kirschbaum")
    }

    func testPondUsesPondAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.pond.assetName, "pond")
        XCTAssertEqual(GardenElementKind.pond.accessibilityLabel, "Teich")
    }

    func testSteppingStonesUsesSteppingStonesAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.steppingStones.assetName, "stepping-stones")
        XCTAssertEqual(GardenElementKind.steppingStones.accessibilityLabel, "Trittsteine")
    }

    func testBonsaiUsesBonsaiAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.bonsai.assetName, "bonsai")
        XCTAssertEqual(GardenElementKind.bonsai.accessibilityLabel, "Bonsai")
    }

    func testTeaBowlSenchaUsesTeaBowlSenchaAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.teaBowlSencha.assetName, "tea-bowl-sencha")
        XCTAssertEqual(GardenElementKind.teaBowlSencha.accessibilityLabel, "Teeschale, Sencha")
    }

    func testTeaBowlOolongUsesTeaBowlOolongAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.teaBowlOolong.assetName, "tea-bowl-oolong")
        XCTAssertEqual(GardenElementKind.teaBowlOolong.accessibilityLabel, "Teeschale, Oolong")
    }

    func testTeaBowlMatchaUsesTeaBowlMatchaAssetAndLabel() {
        XCTAssertEqual(GardenElementKind.teaBowlMatcha.assetName, "tea-bowl-matcha")
        XCTAssertEqual(GardenElementKind.teaBowlMatcha.accessibilityLabel, "Teeschale, Matcha")
    }

    func testAllGardenElementsHaveDistinctNonEmptyAssetNames() {
        let kinds: [GardenElementKind] = [
            .teahouse, .stoneLantern, .moonBridge, .bamboo, .cherryTree,
            .pond, .steppingStones, .bonsai, .teaBowlSencha, .teaBowlOolong,
            .teaBowlMatcha,
        ]
        let assetNames = kinds.map(\.assetName)
        XCTAssertTrue(assetNames.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(assetNames).count, assetNames.count)
    }

    func testAllGardenElementsHaveDistinctNonEmptyAccessibilityLabels() {
        let kinds: [GardenElementKind] = [
            .teahouse, .stoneLantern, .moonBridge, .bamboo, .cherryTree,
            .pond, .steppingStones, .bonsai, .teaBowlSencha, .teaBowlOolong,
            .teaBowlMatcha,
        ]
        let labels = kinds.map(\.accessibilityLabel)
        XCTAssertTrue(labels.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(labels).count, labels.count)
    }
}
