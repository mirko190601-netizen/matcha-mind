import XCTest
@testable import MatchaMind

/// Prüft `illustrationAnimationDuration(reduceMotion:baseDuration:)` aus
/// `DesignSystem/ReduceMotion.swift` (MASTER-PROMPT.md B2 P7, "Bewegung der
/// Illustrationen" / "Bei 'Bewegung reduzieren': Standbild."). Reine
/// Funktion ohne UI-Rendering, daher ohne XCUITest testbar: Ist
/// `accessibilityReduceMotion == true`, muss die Dauer `nil` sein (kein
/// aktiver `.animation(...)`-Zyklus, also Standbild); sonst muss die
/// übergebene Dauer unverändert zurückkommen.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort. Die Logik wurde von Hand gegen
/// `DesignSystem/ReduceMotion.swift` geprüft (analog
/// `Tests/Unit/FoxIllustrationTests.swift`).
final class ReduceMotionTests: XCTestCase {

    func testReturnsNilWhenReduceMotionIsActive() {
        XCTAssertNil(illustrationAnimationDuration(reduceMotion: true, baseDuration: 3.0))
    }

    func testReturnsNilWhenReduceMotionIsActiveRegardlessOfBaseDuration() {
        XCTAssertNil(illustrationAnimationDuration(reduceMotion: true, baseDuration: 0.1))
        XCTAssertNil(illustrationAnimationDuration(reduceMotion: true, baseDuration: 6.0))
    }

    func testReturnsBaseDurationWhenReduceMotionIsInactive() {
        XCTAssertEqual(illustrationAnimationDuration(reduceMotion: false, baseDuration: 3.0), 3.0)
    }

    func testReturnsBaseDurationUnchangedForDifferentCycleLengths() {
        for duration in [2.0, 3.5, 4.2, 6.0] {
            XCTAssertEqual(illustrationAnimationDuration(reduceMotion: false, baseDuration: duration), duration)
        }
    }
}
