// FoxIllustration.swift
// Illustration v2 (design/designsystem-readme.md, Abschnitt "Illustration v2"):
// Fuchs in drei Posen, als Vektor-Bild (SVG, "Preserve Vector Data") aus
// Illustration.xcassets. Jedes Bild hat eine Any- und eine Dark-Appearance
// (siehe Illustration.xcassets/fox-*.imageset/Contents.json), daher reicht
// ein einzelner `Image(_:)`-Aufruf pro Pose - SwiftUI/Xcode waehlt die
// passende Variante je Farbschema automatisch.

import SwiftUI

/// Die drei Posen des Fuchses (MASTER-PROMPT.md B2 P1).
public enum FoxPose {
    case sitting
    case sleeping
    case trotting

    /// Name des Image-Sets in `Illustration.xcassets`.
    var assetName: String {
        switch self {
        case .sitting: "fox-sitting"
        case .sleeping: "fox-sleeping"
        case .trotting: "fox-trotting"
        }
    }

    /// Deutsche Beschreibung der Pose aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `illustration.fox.*`). Als Literal-Aufruf geschrieben
    /// (nicht über einen dynamischen Schlüssel), damit sowohl
    /// `scripts/check_localization.py` als auch
    /// `Tests/Unit/LocalizationCoverageTests.swift` den Schlüssel per Regex
    /// finden.
    var accessibilityLabel: String {
        switch self {
        case .sitting:
            String(localized: "illustration.fox.sitting", defaultValue: "Fuchs, sitzend")
        case .sleeping:
            String(localized: "illustration.fox.sleeping", defaultValue: "Fuchs, schlafend")
        case .trotting:
            String(localized: "illustration.fox.trotting", defaultValue: "Fuchs, schnürend")
        }
    }
}

/// Zeigt den Fuchs in der übergebenen Pose. Ohne feste Größe im View-Code:
/// `resizable()` + `scaledToFit()` lassen den Aufrufer die Größe über
/// `.frame(...)` bestimmen, passend zum jeweiligen Einsatzort (Garten-Szene,
/// Platzhalter, Vorschau).
///
/// Bewegung (design/designsystem-README.md, "Illustration v2" -> "Bewegung
/// der Illustrationen", MASTER-PROMPT.md B2 P7): leichtes Atmen (sanfte
/// Skalierung 1,0↔1,02), da das SVG als Ganzes ohne Schwanz-Teilung vorliegt
/// und eine Schwanzspitzen-Bewegung damit nicht separat animiert werden
/// kann (Vereinfachung laut Auftrag). Dauer und Verzoegerung werden einmalig
/// beim Erscheinen gewuerfelt (`@State`-Startwert, kein Neuwuerfeln bei
/// Re-Renders) und respektieren "Bewegung reduzieren" (Standbild) ueber
/// `DesignSystem/ReduceMotion.swift`.
public struct FoxIllustration: View {
    private let pose: FoxPose

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathingIn = false
    @State private var cycleDuration = Double.random(in: 3.2...4.6)
    @State private var cycleDelay = Double.random(in: 0...1.2)

    public init(pose: FoxPose) {
        self.pose = pose
    }

    public var body: some View {
        Image(pose.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(pose.accessibilityLabel)
            .scaleEffect(isBreathingIn ? 1.02 : 1.0)
            .onAppearStartGentleLoop(
                reduceMotion: reduceMotion,
                baseDuration: cycleDuration,
                delay: cycleDelay,
                isActive: $isBreathingIn
            )
    }
}

#Preview("Hell") {
    HStack(spacing: Space.space4) {
        FoxIllustration(pose: .sitting)
        FoxIllustration(pose: .sleeping)
        FoxIllustration(pose: .trotting)
    }
    .frame(height: 120)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    HStack(spacing: Space.space4) {
        FoxIllustration(pose: .sitting)
        FoxIllustration(pose: .sleeping)
        FoxIllustration(pose: .trotting)
    }
    .frame(height: 120)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}
