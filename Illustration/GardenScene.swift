// GardenScene.swift
// Die Garten-Szene aus design/designsystem-README.md ("Gartenbereiche"):
// Teehaus & Koi-Teich (Sencha) · Bambushain (Oolong) · Mondbruecke (Matcha) ·
// Kirschbaum-Huegel (Deko). Setzt die Szene aus 4 Ebenen zusammen
// (MASTER-PROMPT.md B2 P6): Himmel-Hintergrundverlauf, dann Hintergrund-
// (Matcha), Mittelgrund- (Oolong) und Vordergrund-Elemente (Sencha), Deko
// dazwischen. Gesperrte Bereiche (Oolong/Matcha noch nicht erreicht) werden
// auf 45 % Deckkraft gedaemmt und mit einem Glas-Schloss-Chip ueberlagert
// ("Gesperrte Bereiche: 45 % Deckkraft + Schloss-Chip aus Glas mit
// 'ab Oolong'").

import SwiftUI

/// Text des Schloss-Chips je Gartenbereich, aus dem String Catalog
/// (`Resources/Localizable.xcstrings`, Schlüssel `garden.locked.*`). Als
/// Literal-Aufruf geschrieben (nicht über einen dynamischen Schlüssel),
/// damit sowohl `scripts/check_localization.py` als auch
/// `Tests/Unit/LocalizationCoverageTests.swift` den Schlüssel per Regex
/// finden.
public enum GardenLockLabel {
    case oolong
    case matcha

    var text: String {
        switch self {
        case .oolong:
            String(localized: "garden.locked.oolong", defaultValue: "ab Oolong")
        case .matcha:
            String(localized: "garden.locked.matcha", defaultValue: "ab Matcha")
        }
    }
}

/// Die Garten-Szene. `oolongUnlocked`/`matchaUnlocked` steuern, ob der
/// jeweilige Bereich gedaemmt und mit Schloss-Chip ueberlagert wird; Sencha
/// (Start-Stufe) und das Deko-Element sind immer frei sichtbar.
public struct GardenScene: View {
    private let oolongUnlocked: Bool
    private let matchaUnlocked: Bool
    private let growthStage: Int
    private let decorationIDs: Set<String>
    private let bonusBlossoms: Int

    /// - Parameters:
    ///   - growthStage: Wachstum 0-4 (`GardenGrowth.stage`): mehr und
    ///     groessere Pflanzen.
    ///   - decorationIDs: gekaufte Deko (`DecorationCatalog`), erscheint an
    ///     festen Plaetzen.
    ///   - bonusBlossoms: Anzahl Bonus-Bluetes (Wochenziel) als kleine Blueten.
    public init(
        oolongUnlocked: Bool,
        matchaUnlocked: Bool,
        growthStage: Int = 0,
        decorationIDs: Set<String> = [],
        bonusBlossoms: Int = 0
    ) {
        self.oolongUnlocked = oolongUnlocked
        self.matchaUnlocked = matchaUnlocked
        self.growthStage = growthStage
        self.decorationIDs = decorationIDs
        self.bonusBlossoms = bonusBlossoms
    }

    /// Feste Pflanzenplaetze (Bruchteile der Szene) und ihre Art; je Wachstums-
    /// stufe werden zwei weitere bewachsen (`GardenGrowth.visiblePlantCount`).
    private enum PlantKind { case moss, bamboo, blossom }
    private static let plantSpots: [(x: Double, y: Double, kind: PlantKind)] = [
        (0.10, 0.70, .moss), (0.30, 0.68, .bamboo), (0.68, 0.70, .blossom), (0.90, 0.72, .moss),
        (0.08, 0.90, .bamboo), (0.28, 0.92, .blossom), (0.72, 0.93, .moss), (0.92, 0.90, .blossom),
    ]
    private static let maxBonusBlossoms = 12

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                skyBackground

                // Ebene 1 (Hintergrund): Matcha-Bereich, Mondbruecke.
                matchaArea(isUnlocked: matchaUnlocked)
                    .frame(width: geo.size.width * 0.34)
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.26)

                // Ebene 2 (Mittelgrund): Oolong-Bereich, Bambushain.
                oolongArea(isUnlocked: oolongUnlocked)
                    .frame(width: geo.size.width * 0.3)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.46)

                // Deko (gekauft): feste Plaetze zwischen Mittel- und Vordergrund.
                ForEach(DecorationCatalog.items.filter { decorationIDs.contains($0.id) }) { item in
                    decoration(item, in: geo.size)
                }

                // Ebene 3 (Vordergrund): Sencha-Bereich, Teehaus + Koi-Teich.
                senchaArea(isUnlocked: true)
                    .frame(width: geo.size.width * 0.52)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.8)

                // Tierbesuche (MASTER-PROMPT.md B2 P8): rein dekorativ, siehe
                // `Illustration/AnimalVisit.swift`.
                // Wachstum und Bonus-Blueten liegen ueber dem Boden, unter den Tieren.
                growthLayer(in: geo.size)
                blossomLayer(in: geo.size)

                AnimalVisitOverlay()
            }
            .clipped()
        }
    }

    /// Ebene 0: Himmel-Hintergrundverlauf aus den Band-/Garten-Tokens.
    private var skyBackground: some View {
        LinearGradient(
            colors: [Color("bg-band"), Color("bg-garden")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Sencha: Teehaus + Koi-Teich

    private func senchaArea(isUnlocked: Bool) -> some View {
        gated(isUnlocked: isUnlocked, lockLabel: nil) {
            ZStack(alignment: .bottom) {
                GardenElementIllustration(kind: .pond)
                // Wasserringe (MASTER-PROMPT.md B2 P7): dezente, sich
                // wiederholende Kreis-Ausbreitung ueber dem Teich, siehe
                // `WaterRingEffect` in `Illustration/GardenElements.swift`.
                WaterRingEffect()
                    .frame(width: 60, height: 60)
                    .offset(y: -Space.space3)
                VStack(spacing: -Space.space4) {
                    GardenElementIllustration(kind: .teahouse)
                        .frame(width: 140)
                    HStack(spacing: Space.space3) {
                        KoiIllustration(variant: .kohaku)
                        KoiIllustration(variant: .gold)
                    }
                    .frame(width: 80)
                }
            }
        }
    }

    // MARK: - Oolong: Bambushain

    private func oolongArea(isUnlocked: Bool) -> some View {
        gated(isUnlocked: isUnlocked, lockLabel: .oolong) {
            HStack(spacing: -Space.space3) {
                GardenElementIllustration(kind: .bamboo)
                GardenElementIllustration(kind: .bamboo)
                    .frame(width: 70)
                    .offset(y: Space.space3)
            }
        }
    }

    // MARK: - Matcha: Mondbruecke

    private func matchaArea(isUnlocked: Bool) -> some View {
        gated(isUnlocked: isUnlocked, lockLabel: .matcha) {
            GardenElementIllustration(kind: .moonBridge)
        }
    }

    // MARK: - Deko (gekauft)

    @ViewBuilder
    private func decoration(_ item: DecorationItem, in size: CGSize) -> some View {
        switch item.id {
        case "stepping-stones":
            decoElement(.steppingStones, item: item, width: 0.2, x: 0.36, y: 0.62, in: size)
        case "stone-lantern":
            decoElement(.stoneLantern, item: item, width: 0.12, x: 0.88, y: 0.6, in: size)
        case "bonsai":
            decoElement(.bonsai, item: item, width: 0.14, x: 0.72, y: 0.6, in: size)
        case "cherry-tree":
            decoElement(.cherryTree, item: item, width: 0.26, x: 0.54, y: 0.3, in: size)
        case "lantern-chain":
            HStack(spacing: Space.space3) {
                ForEach(0..<5, id: .self) { _ in
                    Circle().fill(Color("gold-300")).frame(width: Space.space2, height: Space.space2)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.name)
            .position(x: size.width * 0.5, y: size.height * 0.08)
        case "moon-bridge-lantern":
            Circle()
                .fill(Color("gold-300"))
                .frame(width: Space.space4, height: Space.space4)
                .shadow(color: Color("gold-300"), radius: Space.space2)
                .accessibilityLabel(item.name)
                .position(x: size.width * 0.78, y: size.height * 0.12)
        default:
            EmptyView()
        }
    }

    private func decoElement(
        _ kind: GardenElementKind, item: DecorationItem,
        width: Double, x: Double, y: Double, in size: CGSize
    ) -> some View {
        GardenElementIllustration(kind: kind)
            .accessibilityLabel(item.name)
            .frame(width: size.width * width)
            .position(x: size.width * x, y: size.height * y)
    }

    // MARK: - Wachstum und Bonus-Blueten

    private func growthLayer(in size: CGSize) -> some View {
        let visible = min(GardenGrowth.visiblePlantCount(stage: growthStage), Self.plantSpots.count)
        let scale = 0.8 + 0.1 * Double(max(0, min(growthStage, GardenGrowth.maxStage)))
        return ZStack {
            ForEach(0..<visible, id: .self) { index in
                let spot = Self.plantSpots[index]
                plant(spot.kind)
                    .scaleEffect(scale)
                    .position(x: size.width * spot.x, y: size.height * spot.y)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func plant(_ kind: PlantKind) -> some View {
        switch kind {
        case .moss:
            Ellipse().fill(Color("matcha-300")).frame(width: Space.space8, height: Space.space3)
        case .bamboo:
            GardenElementIllustration(kind: .bamboo).frame(width: Space.space6)
        case .blossom:
            Circle().fill(Color("blossom-300")).frame(width: Space.space4, height: Space.space4)
        }
    }

    @ViewBuilder
    private func blossomLayer(in size: CGSize) -> some View {
        let count = max(0, min(bonusBlossoms, Self.maxBonusBlossoms))
        if count > 0 {
            ZStack {
                ForEach(0..<count, id: .self) { index in
                    ZStack {
                        Circle().fill(Color("blossom-300")).frame(width: Space.space3, height: Space.space3)
                        Circle().fill(Color("gold-300")).frame(width: Space.space1, height: Space.space1)
                    }
                    .position(
                        x: size.width * (0.08 + 0.07 * Double(index)),
                        y: size.height * (0.97 - 0.03 * Double(index % 2))
                    )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(format: String(localized: "garden.bonus.a11y", defaultValue: "%lld Bonus-Blüten"), count))
        }
    }

    /// Daemmt einen Bereich bei `isUnlocked == false` auf 45 % Deckkraft und
    /// legt einen Glas-Schloss-Chip darueber. `lockLabel` bleibt `nil`, wenn
    /// der Bereich keinen eigenen Freischalt-Text hat (Sencha).
    @ViewBuilder
    private func gated<Content: View>(
        isUnlocked: Bool,
        lockLabel: GardenLockLabel?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(isUnlocked ? 1 : 0.45)
            .overlay {
                if !isUnlocked, let lockLabel {
                    lockChip(lockLabel)
                }
            }
    }

    private func lockChip(_ label: GardenLockLabel) -> some View {
        GlassCard(radius: Radius.radiusLg, padding: Space.space3) {
            HStack(spacing: Space.space1) {
                Image(systemName: "lock.fill")
                    .font(.system(size: Size.iconHelp, weight: .medium))
                    .foregroundStyle(Color("text"))
                Text(label.text)
                    .font(.mmLabel)
                    .foregroundStyle(Color("text"))
            }
        }
    }
}

#Preview("Nur Sencha · Hell") {
    GardenScene(oolongUnlocked: false, matchaUnlocked: false)
        .frame(height: 420)
        .preferredColorScheme(.light)
}

#Preview("Nur Sencha · Dunkel") {
    GardenScene(oolongUnlocked: false, matchaUnlocked: false)
        .frame(height: 420)
        .preferredColorScheme(.dark)
}

#Preview("Sencha + Oolong · Hell") {
    GardenScene(oolongUnlocked: true, matchaUnlocked: false)
        .frame(height: 420)
        .preferredColorScheme(.light)
}

#Preview("Alles frei · Hell") {
    GardenScene(oolongUnlocked: true, matchaUnlocked: true)
        .frame(height: 420)
        .preferredColorScheme(.light)
}

#Preview("Alles frei · Dunkel") {
    GardenScene(oolongUnlocked: true, matchaUnlocked: true)
        .frame(height: 420)
        .preferredColorScheme(.dark)
}
