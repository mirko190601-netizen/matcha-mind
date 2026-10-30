import XCTest
@testable import MatchaMind

/// Prüft `FoxPose` (`Illustration/FoxIllustration.swift`, MASTER-PROMPT.md
/// B2 P1): jede Pose muss auf das richtige Image-Set in
/// `Illustration.xcassets` zeigen und einen deutschen
/// Accessibility-Text liefern, der zum entsprechenden Schlüssel in
/// `Resources/Localizable.xcstrings` passt.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene Punkte
/// in der Commit-Antwort. Die Zuordnung wurde von Hand gegen
/// `Illustration/FoxIllustration.swift` und
/// `Resources/Localizable.xcstrings` geprüft.
final class FoxIllustrationTests: XCTestCase {

    func testSittingPoseUsesSittingAssetAndLabel() {
        XCTAssertEqual(FoxPose.sitting.assetName, "fox-sitting")
        XCTAssertEqual(FoxPose.sitting.accessibilityLabel, "Fuchs, sitzend")
    }

    func testSleepingPoseUsesSleepingAssetAndLabel() {
        XCTAssertEqual(FoxPose.sleeping.assetName, "fox-sleeping")
        XCTAssertEqual(FoxPose.sleeping.accessibilityLabel, "Fuchs, schlafend")
    }

    func testTrottingPoseUsesTrottingAssetAndLabel() {
        XCTAssertEqual(FoxPose.trotting.assetName, "fox-trotting")
        XCTAssertEqual(FoxPose.trotting.accessibilityLabel, "Fuchs, schnürend")
    }

    /// Jede Pose muss ein eigenes, nicht-leeres Asset haben - verhindert ein
    /// versehentliches Zusammenfallen zweier Posen auf denselben Namen.
    func testAllPosesHaveDistinctNonEmptyAssetNames() {
        let assetNames = [FoxPose.sitting, .sleeping, .trotting].map(\.assetName)

        XCTAssertTrue(assetNames.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(assetNames).count, assetNames.count)
    }
}
