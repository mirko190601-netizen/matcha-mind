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

    public init(oolongUnlocked: Bool, matchaUnlocked: Bool) {
        self.oolongUnlocked = oolongUnlocked
        self.matchaUnlocked = matchaUnlocked
    }

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

                // Deko: Kirschbaum-Huegel, immer sichtbar, zwischen Mittel-
                // und Vordergrund.
                decoArea
                    .frame(width: geo.size.width * 0.26)
                    .position(x: geo.size.width * 0.54, y: geo.size.height * 0.3)

                // Ebene 3 (Vordergrund): Sencha-Bereich, Teehaus + Koi-Teich.
                senchaArea(isUnlocked: true)
                    .frame(width: geo.size.width * 0.52)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.8)

                // Tierbesuche (MASTER-PROMPT.md B2 P8): rein dekorativ, siehe
                // `Illustration/AnimalVisit.swift`.
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

    // MARK: - Deko: Kirschbaum-Huegel

    private var decoArea: some View {
        GardenElementIllustration(kind: .cherryTree)
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
