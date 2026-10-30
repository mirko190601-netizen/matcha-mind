// GardenElements.swift
// Illustration v2 (design/designsystem-README.md, Abschnitt "Illustration v2",
// Gartenbereiche): die unbelebten Garten-Elemente als Vektor-Bilder (SVG,
// "Preserve Vector Data") aus Illustration.xcassets. Jedes Bild hat eine
// Any- und eine Dark-Appearance (siehe Illustration.xcassets/<name>.imageset/
// Contents.json), daher reicht ein einzelner `Image(_:)`-Aufruf pro Element -
// SwiftUI/Xcode waehlt die passende Darstellung je Farbschema automatisch.
// Gleiches Muster wie Illustration/CreatureIllustrations.swift
// (MASTER-PROMPT.md B2 P5).
//
// Farbtoken-Entscheidung Holz: `wood-500`/`wood-700` aus
// design/designsystem-tokens.json ("Holzrahmen von Spielbrettern,
// Teehaus-Elemente" / "Dunkle Holzdetails") - direkt fuer Teehaus, Mondbruecke,
// Bambus-Halme, Bonsai-Topf und -Stamm genutzt. Stein (Steinlaterne,
// Trittsteine) hat keinen eigenen Token; dafuer wird `koi-white` als helle
// neutrale Tonstufe verwendet (Schatten-Tonstufen daraus abgeleitet), siehe
// Kommentar in Scripts/gen_garden_svgs.js-Historie / Commit-Antwort.

import SwiftUI

/// Die unbelebten Garten-Elemente aus den vier Gartenbereichen
/// (MASTER-PROMPT.md B2 P5): Teehaus & Koi-Teich (Sencha), Bambushain
/// (Oolong), Mondbruecke (Matcha), Kirschbaum-Huegel (Deko), sowie die drei
/// Teeschalen je Teesorte.
public enum GardenElementKind {
    case teahouse
    case stoneLantern
    case moonBridge
    case bamboo
    case cherryTree
    case pond
    case steppingStones
    case bonsai
    case teaBowlSencha
    case teaBowlOolong
    case teaBowlMatcha

    /// Name des Image-Sets in `Illustration.xcassets`.
    var assetName: String {
        switch self {
        case .teahouse: "teahouse"
        case .stoneLantern: "stone-lantern"
        case .moonBridge: "moon-bridge"
        case .bamboo: "bamboo"
        case .cherryTree: "cherry-tree"
        case .pond: "pond"
        case .steppingStones: "stepping-stones"
        case .bonsai: "bonsai"
        case .teaBowlSencha: "tea-bowl-sencha"
        case .teaBowlOolong: "tea-bowl-oolong"
        case .teaBowlMatcha: "tea-bowl-matcha"
        }
    }

    /// Deutsche Beschreibung des Elements aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `illustration.garden.*`). Als Literal-Aufruf geschrieben
    /// (nicht über einen dynamischen Schlüssel), damit sowohl
    /// `scripts/check_localization.py` als auch
    /// `Tests/Unit/LocalizationCoverageTests.swift` den Schlüssel per Regex
    /// finden.
    var accessibilityLabel: String {
        switch self {
        case .teahouse:
            String(localized: "illustration.garden.teahouse", defaultValue: "Teehaus")
        case .stoneLantern:
            String(localized: "illustration.garden.stoneLantern", defaultValue: "Steinlaterne")
        case .moonBridge:
            String(localized: "illustration.garden.moonBridge", defaultValue: "Mondbrücke")
        case .bamboo:
            String(localized: "illustration.garden.bamboo", defaultValue: "Bambus")
        case .cherryTree:
            String(localized: "illustration.garden.cherryTree", defaultValue: "Kirschbaum")
        case .pond:
            String(localized: "illustration.garden.pond", defaultValue: "Teich")
        case .steppingStones:
            String(localized: "illustration.garden.steppingStones", defaultValue: "Trittsteine")
        case .bonsai:
            String(localized: "illustration.garden.bonsai", defaultValue: "Bonsai")
        case .teaBowlSencha:
            String(localized: "illustration.garden.teaBowlSencha", defaultValue: "Teeschale, Sencha")
        case .teaBowlOolong:
            String(localized: "illustration.garden.teaBowlOolong", defaultValue: "Teeschale, Oolong")
        case .teaBowlMatcha:
            String(localized: "illustration.garden.teaBowlMatcha", defaultValue: "Teeschale, Matcha")
        }
    }
}

/// Zeigt ein Garten-Element. Ohne feste Größe im View-Code: `resizable()` +
/// `scaledToFit()` lassen den Aufrufer die Größe über `.frame(...)`
/// bestimmen, passend zum jeweiligen Einsatzort (Garten-Szene, Platzhalter,
/// Vorschau).
///
/// Bewegung (design/designsystem-README.md, "Illustration v2" -> "Bewegung
/// der Illustrationen", MASTER-PROMPT.md B2 P7): nur der Bambus wiegt sich
/// (Rotation ±2,5° um die Basis) - alle anderen Garten-Elemente bleiben
/// unveraendert. Dauer und Verzoegerung werden einmalig beim Erscheinen
/// gewuerfelt (`@State`, nicht bei jedem Re-Render neu) und respektieren
/// "Bewegung reduzieren" (Standbild) ueber `DesignSystem/ReduceMotion.swift`.
public struct GardenElementIllustration: View {
    private let kind: GardenElementKind

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSwayingRight = false
    @State private var cycleDuration = Double.random(in: 3.0...5.0)
    @State private var cycleDelay = Double.random(in: 0...1.6)

    public init(kind: GardenElementKind) {
        self.kind = kind
    }

    public var body: some View {
        let image = Image(kind.assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(kind.accessibilityLabel)

        if case .bamboo = kind {
            image
                .rotationEffect(.degrees(isSwayingRight ? 2.5 : -2.5), anchor: .bottom)
                .onAppearStartGentleLoop(
                    reduceMotion: reduceMotion,
                    baseDuration: cycleDuration,
                    delay: cycleDelay,
                    isActive: $isSwayingRight
                )
        } else {
            image
        }
    }
}

/// Wasserringe-Effekt fuer den Koi-Teich (design/designsystem-README.md,
/// "Illustration v2" -> "Bewegung der Illustrationen", MASTER-PROMPT.md
/// B2 P7): ein einfacher, sich wiederholender, verblassender
/// Kreis-Ausbreitungseffekt. Rein dekorativ (kein Accessibility-Inhalt,
/// die Beschriftung des Teichs liefert `GardenElementIllustration(kind:
/// .pond)`). Ohne feste Größe im View-Code: der Aufrufer legt über
/// `.frame(...)` die Ausdehnung fest, typischerweise als Overlay auf
/// `GardenElementIllustration(kind: .pond)`.
///
/// Nutzt `autoreverses: false`: der Ring waechst einmal von klein/deckend
/// nach groß/durchsichtig und beginnt danach sofort wieder klein/deckend -
/// anders als das Hin-und-Her bei Atmen/Schwimmen/Wiegen/Glimmen. Dauer und
/// Verzoegerung werden einmalig beim Erscheinen gewuerfelt (`@State`, nicht
/// bei jedem Re-Render neu) und respektieren "Bewegung reduzieren"
/// (Standbild) ueber `DesignSystem/ReduceMotion.swift`.
public struct WaterRingEffect: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @State private var cycleDuration = Double.random(in: 2.5...4.0)
    @State private var cycleDelay = Double.random(in: 0...1.0)

    public init() {}

    public var body: some View {
        Circle()
            .strokeBorder(Color("line-art").opacity(isExpanded ? 0 : 0.5), lineWidth: 1.5)
            .scaleEffect(isExpanded ? 1.6 : 0.3)
            .onAppearStartGentleLoop(
                reduceMotion: reduceMotion,
                baseDuration: cycleDuration,
                delay: cycleDelay,
                autoreverses: false,
                isActive: $isExpanded
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Architektur · Hell") {
    HStack(spacing: Space.space4) {
        GardenElementIllustration(kind: .teahouse)
        GardenElementIllustration(kind: .stoneLantern)
        GardenElementIllustration(kind: .moonBridge)
    }
    .frame(height: 140)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Architektur · Dunkel") {
    HStack(spacing: Space.space4) {
        GardenElementIllustration(kind: .teahouse)
        GardenElementIllustration(kind: .stoneLantern)
        GardenElementIllustration(kind: .moonBridge)
    }
    .frame(height: 140)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}

#Preview("Pflanzen & Wasser · Hell") {
    HStack(spacing: Space.space4) {
        GardenElementIllustration(kind: .bamboo)
        GardenElementIllustration(kind: .cherryTree)
        GardenElementIllustration(kind: .pond)
        GardenElementIllustration(kind: .steppingStones)
        GardenElementIllustration(kind: .bonsai)
    }
    .frame(height: 120)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Pflanzen & Wasser · Dunkel") {
    HStack(spacing: Space.space4) {
        GardenElementIllustration(kind: .bamboo)
        GardenElementIllustration(kind: .cherryTree)
        GardenElementIllustration(kind: .pond)
        GardenElementIllustration(kind: .steppingStones)
        GardenElementIllustration(kind: .bonsai)
    }
    .frame(height: 120)
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}

#Preview("Teeschalen · Hell") {
    HStack(spacing: Space.space4) {
        GardenElementIllustration(kind: .teaBowlSencha)
        GardenElementIllustration(kind: .teaBowlOolong)
        GardenElementIllustration(kind: .teaBowlMatcha)
    }
    .frame(height: 90)
    .padding(Space.space6)
    .background(Color("bg-tea"))
    .preferredColorScheme(.light)
}

#Preview("Teeschalen · Dunkel") {
    HStack(spacing: Space.space4) {
        GardenElementIllustration(kind: .teaBowlSencha)
        GardenElementIllustration(kind: .teaBowlOolong)
        GardenElementIllustration(kind: .teaBowlMatcha)
    }
    .frame(height: 90)
    .padding(Space.space6)
    .background(Color("bg-tea"))
    .preferredColorScheme(.dark)
}
