import XCTest
@testable import MatchaMind

/// Prüft die Enums aus `Illustration/CreatureIllustrations.swift`
/// (MASTER-PROMPT.md B2 P2-P4): jede Pose/Variante/Art/Kleintier-Kind
/// muss auf das richtige Image-Set in `Illustration.xcassets` zeigen und
/// einen deutschen Accessibility-Text liefern, der zum entsprechenden
/// Schlüssel in `Resources/Localizable.xcstrings` passt.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort. Die Zuordnung wurde von Hand gegen
/// `Illustration/CreatureIllustrations.swift` und
/// `Resources/Localizable.xcstrings` geprüft (analog
/// `Tests/Unit/FoxIllustrationTests.swift`).
final class CreatureIllustrationsTests: XCTestCase {

    // MARK: - Kranich

    func testStandingPoseUsesStandingAssetAndLabel() {
        XCTAssertEqual(CranePose.standing.assetName, "crane-standing")
        XCTAssertEqual(CranePose.standing.accessibilityLabel, "Kranich, stehend")
    }

    func testLandingPoseUsesLandingAssetAndLabel() {
        XCTAssertEqual(CranePose.landing.assetName, "crane-landing")
        XCTAssertEqual(CranePose.landing.accessibilityLabel, "Kranich, landend")
    }

    func testCranePosesHaveDistinctNonEmptyAssetNames() {
        let assetNames = [CranePose.standing, .landing].map(\.assetName)
        XCTAssertTrue(assetNames.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(assetNames).count, assetNames.count)
    }

    // MARK: - Koi

    func testKohakuVariantUsesKohakuAssetAndLabel() {
        XCTAssertEqual(KoiVariant.kohaku.assetName, "koi-kohaku")
        XCTAssertEqual(KoiVariant.kohaku.accessibilityLabel, "Koi, weiß-rot (Kohaku)")
    }

    func testShowaVariantUsesShowaAssetAndLabel() {
        XCTAssertEqual(KoiVariant.showa.assetName, "koi-showa")
        XCTAssertEqual(KoiVariant.showa.accessibilityLabel, "Koi, schwarz-weiß-rot (Showa)")
    }

    func testGoldVariantUsesGoldAssetAndLabel() {
        XCTAssertEqual(KoiVariant.gold.assetName, "koi-gold")
        XCTAssertEqual(KoiVariant.gold.accessibilityLabel, "Koi, golden")
    }

    func testKoiVariantsHaveDistinctNonEmptyAssetNames() {
        let assetNames = [KoiVariant.kohaku, .showa, .gold].map(\.assetName)
        XCTAssertTrue(assetNames.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(assetNames).count, assetNames.count)
    }

    // MARK: - Schmetterlinge

    func testLavenderSpeciesUsesButterfly1AssetAndLabel() {
        XCTAssertEqual(ButterflySpecies.lavender.assetName, "butterfly-1")
        XCTAssertEqual(ButterflySpecies.lavender.accessibilityLabel, "Schmetterling, lavendelfarben")
    }

    func testBlossomSpeciesUsesButterfly2AssetAndLabel() {
        XCTAssertEqual(ButterflySpecies.blossom.assetName, "butterfly-2")
        XCTAssertEqual(ButterflySpecies.blossom.accessibilityLabel, "Schmetterling, kirschblütenrosa")
    }

    func testGoldSpeciesUsesButterfly3AssetAndLabel() {
        XCTAssertEqual(ButterflySpecies.gold.assetName, "butterfly-3")
        XCTAssertEqual(ButterflySpecies.gold.accessibilityLabel, "Schmetterling, goldgelb")
    }

    func testButterflySpeciesHaveDistinctNonEmptyAssetNames() {
        let assetNames = [ButterflySpecies.lavender, .blossom, .gold].map(\.assetName)
        XCTAssertTrue(assetNames.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(assetNames).count, assetNames.count)
    }

    // MARK: - Kleintiere

    func testFireflyKindUsesFireflyAssetAndLabel() {
        XCTAssertEqual(SmallCreatureKind.firefly.assetName, "firefly")
        XCTAssertEqual(SmallCreatureKind.firefly.accessibilityLabel, "Glühwürmchen")
    }

    func testMothKindUsesMothAssetAndLabel() {
        XCTAssertEqual(SmallCreatureKind.moth.assetName, "moth")
        XCTAssertEqual(SmallCreatureKind.moth.accessibilityLabel, "Falter")
    }

    func testBeeKindUsesBeeAssetAndLabel() {
        XCTAssertEqual(SmallCreatureKind.bee.assetName, "bee")
        XCTAssertEqual(SmallCreatureKind.bee.accessibilityLabel, "Biene")
    }

    func testDragonflyKindUsesDragonflyAssetAndLabel() {
        XCTAssertEqual(SmallCreatureKind.dragonfly.assetName, "dragonfly")
        XCTAssertEqual(SmallCreatureKind.dragonfly.accessibilityLabel, "Libelle")
    }

    func testSmallCreatureKindsHaveDistinctNonEmptyAssetNames() {
        let assetNames = [SmallCreatureKind.firefly, .moth, .bee, .dragonfly].map(\.assetName)
        XCTAssertTrue(assetNames.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(assetNames).count, assetNames.count)
    }
}
