// IllustrationGalleryView.swift
// P9 (MASTER-PROMPT.md B2 P9, "Snapshot-Tests in CI"): zeigt alle
// Illustrationen in einem Grid, rein fuer Debug-/Test-Zwecke, daher hinter
// `#if DEBUG`. Es gibt noch keinen Navigationsweg zu den Illustrationen in
// der eigentlichen App (kein verstecktes Tab, keine
// `-uitest-...`-Umgebungsvariable in `App/LaunchConfiguration.swift`), und
// das Anlegen einer solchen Testroute wuerde App-Startpfad-Dateien
// aendern, die nicht Teil dieses Auftrags sind. Deshalb wurde die im
// Auftrag genannte Ausweich-Loesung gewaehlt: nur diese Galerie-View bauen,
// OHNE UI-Test-Integration (`Tests/UI/IllustrationSnapshotUITests.swift`
// wurde bewusst NICHT angelegt). Offener Punkt fuer Opus: eine
// `-uitest-...`-Testroute in `App/ContentView.swift` /
// `App/LaunchConfiguration.swift` ergaenzen, die diese View zeigt, und
// darauf aufbauend den eigentlichen Snapshot-UI-Test schreiben.

#if DEBUG
import SwiftUI

/// Debug-Galerie aller Illustrationen (Fuchs, Kranich, Koi, Schmetterlinge,
/// Kleintiere, Garten-Elemente) in einem Grid - fuer visuelle Pruefung
/// (hell/dunkel) und als Grundlage fuer einen spaeteren Snapshot-UI-Test.
/// Nicht Teil des normalen App-Navigationsflusses.
public struct IllustrationGalleryView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 120))], spacing: Space.space4) {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    entry.view
                        .frame(width: 80, height: 80)
                }
            }
            .padding(Space.space6)
        }
        .background(Color("bg-garden"))
    }

    private struct Entry: Identifiable {
        let id: String
        let view: AnyView
    }

    private var entries: [Entry] {
        [
            Entry(id: "fox-sitting", view: AnyView(FoxIllustration(pose: .sitting))),
            Entry(id: "fox-sleeping", view: AnyView(FoxIllustration(pose: .sleeping))),
            Entry(id: "fox-trotting", view: AnyView(FoxIllustration(pose: .trotting))),
            Entry(id: "crane-standing", view: AnyView(CraneIllustration(pose: .standing))),
            Entry(id: "crane-landing", view: AnyView(CraneIllustration(pose: .landing))),
            Entry(id: "koi-kohaku", view: AnyView(KoiIllustration(variant: .kohaku))),
            Entry(id: "koi-showa", view: AnyView(KoiIllustration(variant: .showa))),
            Entry(id: "koi-gold", view: AnyView(KoiIllustration(variant: .gold))),
            Entry(id: "butterfly-lavender", view: AnyView(ButterflyIllustration(species: .lavender))),
            Entry(id: "butterfly-blossom", view: AnyView(ButterflyIllustration(species: .blossom))),
            Entry(id: "butterfly-gold", view: AnyView(ButterflyIllustration(species: .gold))),
            Entry(id: "firefly", view: AnyView(SmallCreatureIllustration(kind: .firefly))),
            Entry(id: "moth", view: AnyView(SmallCreatureIllustration(kind: .moth))),
            Entry(id: "bee", view: AnyView(SmallCreatureIllustration(kind: .bee))),
            Entry(id: "dragonfly", view: AnyView(SmallCreatureIllustration(kind: .dragonfly))),
            Entry(id: "teahouse", view: AnyView(GardenElementIllustration(kind: .teahouse))),
            Entry(id: "stone-lantern", view: AnyView(GardenElementIllustration(kind: .stoneLantern))),
            Entry(id: "moon-bridge", view: AnyView(GardenElementIllustration(kind: .moonBridge))),
            Entry(id: "bamboo", view: AnyView(GardenElementIllustration(kind: .bamboo))),
            Entry(id: "cherry-tree", view: AnyView(GardenElementIllustration(kind: .cherryTree))),
            Entry(id: "pond", view: AnyView(GardenElementIllustration(kind: .pond))),
            Entry(id: "stepping-stones", view: AnyView(GardenElementIllustration(kind: .steppingStones))),
            Entry(id: "bonsai", view: AnyView(GardenElementIllustration(kind: .bonsai))),
            Entry(id: "tea-bowl-sencha", view: AnyView(GardenElementIllustration(kind: .teaBowlSencha))),
            Entry(id: "tea-bowl-oolong", view: AnyView(GardenElementIllustration(kind: .teaBowlOolong))),
            Entry(id: "tea-bowl-matcha", view: AnyView(GardenElementIllustration(kind: .teaBowlMatcha))),
        ]
    }
}

#Preview("Galerie · Hell") {
    IllustrationGalleryView()
        .preferredColorScheme(.light)
}

#Preview("Galerie · Dunkel") {
    IllustrationGalleryView()
        .preferredColorScheme(.dark)
}
#endif
