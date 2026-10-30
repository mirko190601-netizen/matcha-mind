// CreatureIllustrations.swift
// Illustration v2 (design/designsystem-readme.md, Abschnitt "Illustration v2"):
// Kranich, Koi, Schmetterlinge und Kleintiere als Vektor-Bilder (SVG,
// "Preserve Vector Data") aus Illustration.xcassets. Jedes Bild hat eine
// Any- und eine Dark-Appearance (siehe Illustration.xcassets/*.imageset/
// Contents.json), daher reicht ein einzelner `Image(_:)`-Aufruf pro
// Pose/Variante - SwiftUI/Xcode waehlt die passende Darstellung je
// Farbschema automatisch. Gleiches Muster wie FoxIllustration.swift
// (MASTER-PROMPT.md B2 P1).

import SwiftUI

// MARK: - Kranich

/// Die zwei Posen des Kranichs (MASTER-PROMPT.md B2 P2).
public enum CranePose {
    case standing
    case landing

    /// Name des Image-Sets in `Illustration.xcassets`.
    var assetName: String {
        switch self {
        case .standing: "crane-standing"
        case .landing: "crane-landing"
        }
    }

    /// Deutsche Beschreibung der Pose aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `illustration.crane.*`). Als Literal-Aufruf geschrieben
    /// (nicht über einen dynamischen Schlüssel), damit sowohl
    /// `scripts/check_localization.py` als auch
    /// `Tests/Unit/LocalizationCoverageTests.swift` den Schlüssel per Regex
    /// finden.
    var accessibilityLabel: String {
        switch self {
        case .standing:
            String(localized: "illustration.crane.standing", defaultValue: "Kranich, stehend")
        case .landing:
            String(localized: "illustration.crane.landing", defaultValue: "Kranich, landend")
        }
    }
}

/// Zeigt den Kranich in der übergebenen Pose. Ohne feste Größe im
/// View-Code: `resizable()` + `scaledToFit()` lassen den Aufrufer die
/// Größe über `.frame(...)` bestimmen.
public struct CraneIllustration: View {
    private let pose: CranePose

    public init(pose: CranePose) {
        self.pose = pose
    }

    public var body: some View {
        Image(pose.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(pose.accessibilityLabel)
    }
}

// MARK: - Koi

/// Die drei Koi-Varianten (MASTER-PROMPT.md B2 P2).
public enum KoiVariant {
    case kohaku
    case showa
    case gold

    /// Name des Image-Sets in `Illustration.xcassets`.
    var assetName: String {
        switch self {
        case .kohaku: "koi-kohaku"
        case .showa: "koi-showa"
        case .gold: "koi-gold"
        }
    }

    /// Deutsche Beschreibung der Variante aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `illustration.koi.*`).
    var accessibilityLabel: String {
        switch self {
        case .kohaku:
            String(localized: "illustration.koi.kohaku", defaultValue: "Koi, weiß-rot (Kohaku)")
        case .showa:
            String(localized: "illustration.koi.showa", defaultValue: "Koi, schwarz-weiß-rot (Showa)")
        case .gold:
            String(localized: "illustration.koi.gold", defaultValue: "Koi, golden")
        }
    }
}

/// Zeigt den Koi in der übergebenen Farbvariante.
///
/// Bewegung (design/designsystem-README.md, "Illustration v2" -> "Bewegung
/// der Illustrationen", MASTER-PROMPT.md B2 P7): sanfte seitliche
/// Schwimmbewegung aus leichter Rotation + horizontalem Versatz. Dauer und
/// Verzoegerung werden einmalig beim Erscheinen gewuerfelt (`@State`,
/// nicht bei jedem Re-Render neu) und respektieren "Bewegung reduzieren"
/// (Standbild) ueber `DesignSystem/ReduceMotion.swift`.
public struct KoiIllustration: View {
    private let variant: KoiVariant

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSwimmingRight = false
    @State private var cycleDuration = Double.random(in: 3.5...5.5)
    @State private var cycleDelay = Double.random(in: 0...1.4)

    public init(variant: KoiVariant) {
        self.variant = variant
    }

    public var body: some View {
        Image(variant.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(variant.accessibilityLabel)
            .rotationEffect(.degrees(isSwimmingRight ? 4 : -4))
            .offset(x: isSwimmingRight ? 3 : -3)
            .onAppearStartGentleLoop(
                reduceMotion: reduceMotion,
                baseDuration: cycleDuration,
                delay: cycleDelay,
                isActive: $isSwimmingRight
            )
    }
}

// MARK: - Schmetterlinge

/// Die drei Schmetterlings-Arten (MASTER-PROMPT.md B2 P3), benannt nach
/// ihrer Flügelfarbe aus der Spielwelt-Palette.
public enum ButterflySpecies {
    case lavender
    case blossom
    case gold

    /// Name des Image-Sets in `Illustration.xcassets`.
    var assetName: String {
        switch self {
        case .lavender: "butterfly-1"
        case .blossom: "butterfly-2"
        case .gold: "butterfly-3"
        }
    }

    /// Deutsche Beschreibung der Art aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `illustration.butterfly.*`).
    var accessibilityLabel: String {
        switch self {
        case .lavender:
            String(localized: "illustration.butterfly.lavender", defaultValue: "Schmetterling, lavendelfarben")
        case .blossom:
            String(localized: "illustration.butterfly.blossom", defaultValue: "Schmetterling, kirschblütenrosa")
        case .gold:
            String(localized: "illustration.butterfly.gold", defaultValue: "Schmetterling, goldgelb")
        }
    }
}

/// Zeigt den Schmetterling in der übergebenen Art.
///
/// Bewegung (design/designsystem-README.md, "Illustration v2" -> "Bewegung
/// der Illustrationen", MASTER-PROMPT.md B2 P7): Flügelschlag ist hier als
/// Gesamt-Pulsation + leichtes Auf-ab-Wackeln umgesetzt (Vereinfachung laut
/// Auftrag), da das SVG als Ganzes vorliegt und die Flügel nicht als
/// eigene Pfade animiert werden koennen. Dauer und Verzoegerung werden
/// einmalig beim Erscheinen gewuerfelt (`@State`, nicht bei jedem
/// Re-Render neu) und respektieren "Bewegung reduzieren" (Standbild) ueber
/// `DesignSystem/ReduceMotion.swift`.
public struct ButterflyIllustration: View {
    private let species: ButterflySpecies

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFluttering = false
    @State private var cycleDuration = Double.random(in: 2.2...3.6)
    @State private var cycleDelay = Double.random(in: 0...0.8)

    public init(species: ButterflySpecies) {
        self.species = species
    }

    public var body: some View {
        Image(species.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(species.accessibilityLabel)
            .scaleEffect(isFluttering ? 1.05 : 1.0)
            .rotationEffect(.degrees(isFluttering ? 3 : -3))
            .onAppearStartGentleLoop(
                reduceMotion: reduceMotion,
                baseDuration: cycleDuration,
                delay: cycleDelay,
                isActive: $isFluttering
            )
    }
}

// MARK: - Kleintiere

/// Die vier kleinen Spielfiguren (MASTER-PROMPT.md B2 P3): Glühwürmchen,
/// Falter, Biene, Libelle.
public enum SmallCreatureKind {
    case firefly
    case moth
    case bee
    case dragonfly

    /// Name des Image-Sets in `Illustration.xcassets`.
    var assetName: String {
        switch self {
        case .firefly: "firefly"
        case .moth: "moth"
        case .bee: "bee"
        case .dragonfly: "dragonfly"
        }
    }

    /// Deutsche Beschreibung aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `illustration.creature.*`).
    var accessibilityLabel: String {
        switch self {
        case .firefly:
            String(localized: "illustration.creature.firefly", defaultValue: "Glühwürmchen")
        case .moth:
            String(localized: "illustration.creature.moth", defaultValue: "Falter")
        case .bee:
            String(localized: "illustration.creature.bee", defaultValue: "Biene")
        case .dragonfly:
            String(localized: "illustration.creature.dragonfly", defaultValue: "Libelle")
        }
    }
}

/// Zeigt eine kleine Spielfigur (Glühwürmchen, Falter, Biene, Libelle).
///
/// Bewegung (design/designsystem-README.md, "Illustration v2" -> "Bewegung
/// der Illustrationen", MASTER-PROMPT.md B2 P7): nur das Glühwürmchen
/// glimmt (Opazität pulsierend 0,5↔1,0) - Falter, Biene und Libelle bleiben
/// unveraendert. Dauer und Verzoegerung werden einmalig beim Erscheinen
/// gewuerfelt (`@State`, nicht bei jedem Re-Render neu) und respektieren
/// "Bewegung reduzieren" (Standbild) ueber `DesignSystem/ReduceMotion.swift`.
public struct SmallCreatureIllustration: View {
    private let kind: SmallCreatureKind

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isGlowing = false
    @State private var cycleDuration = Double.random(in: 2.0...3.4)
    @State private var cycleDelay = Double.random(in: 0...1.0)

    public init(kind: SmallCreatureKind) {
        self.kind = kind
    }

    public var body: some View {
        let image = Image(kind.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(kind.accessibilityLabel)

        if case .firefly = kind {
            image
                .opacity(isGlowing ? 1.0 : 0.5)
                .onAppearStartGentleLoop(
                    reduceMotion: reduceMotion,
                    baseDuration: cycleDuration,
                    delay: cycleDelay,
                    isActive: $isGlowing
                )
        } else {
            image
        }
    }
}

// MARK: - Previews

#Preview("Kranich · Hell") {
    HStack(spacing: Space.space4) {
        CraneIllustration(pose: .standing)
        CraneIllustration(pose: .landing)
    }
    .frame(height: 120)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Kranich · Dunkel") {
    HStack(spacing: Space.space4) {
        CraneIllustration(pose: .standing)
        CraneIllustration(pose: .landing)
    }
    .frame(height: 120)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}

#Preview("Koi · Hell") {
    HStack(spacing: Space.space4) {
        KoiIllustration(variant: .kohaku)
        KoiIllustration(variant: .showa)
        KoiIllustration(variant: .gold)
    }
    .frame(height: 100)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Koi · Dunkel") {
    HStack(spacing: Space.space4) {
        KoiIllustration(variant: .kohaku)
        KoiIllustration(variant: .showa)
        KoiIllustration(variant: .gold)
    }
    .frame(height: 100)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}

#Preview("Schmetterlinge · Hell") {
    HStack(spacing: Space.space4) {
        ButterflyIllustration(species: .lavender)
        ButterflyIllustration(species: .blossom)
        ButterflyIllustration(species: .gold)
    }
    .frame(height: 90)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Schmetterlinge · Dunkel") {
    HStack(spacing: Space.space4) {
        ButterflyIllustration(species: .lavender)
        ButterflyIllustration(species: .blossom)
        ButterflyIllustration(species: .gold)
    }
    .frame(height: 90)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}

#Preview("Kleintiere · Hell") {
    HStack(spacing: Space.space4) {
        SmallCreatureIllustration(kind: .firefly)
        SmallCreatureIllustration(kind: .moth)
        SmallCreatureIllustration(kind: .bee)
        SmallCreatureIllustration(kind: .dragonfly)
    }
    .frame(height: 44)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Kleintiere · Dunkel") {
    HStack(spacing: Space.space4) {
        SmallCreatureIllustration(kind: .firefly)
        SmallCreatureIllustration(kind: .moth)
        SmallCreatureIllustration(kind: .bee)
        SmallCreatureIllustration(kind: .dragonfly)
    }
    .frame(height: 44)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}
