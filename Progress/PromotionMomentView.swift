// PromotionMomentView.swift
// Aufstiegs-Moment (MASTER-PROMPT.md, Block B4 Aufgabe 2): ein ruhiges Angebot,
// keine Pflicht. Zeigt den Garten mit dem neu geoeffneten Bereich, dessen Namen
// und die Spiele, die dazukommen. "Weiter mit ..." uebernimmt die Stufe,
// "Lieber noch bleiben" verschiebt das Angebot (siehe `PlayerStore`).
// Kein Zaehler, kein Druck.

import SwiftUI

struct PromotionMomentView: View {
    @Environment(PlayerStore.self) private var playerStore

    /// Stufe, auf die das Angebot lautet (Oolong oder Matcha).
    let target: TeaLevel
    /// Aufruf nach der Entscheidung (Sheet schliessen).
    let onDone: () -> Void

    /// Spiele, die mit der Ziel-Stufe dazukommen, auch noch nicht gebaute.
    private var newGames: [GameCatalogEntry] {
        GameCatalog.games(for: target)
    }

    private var areaName: String {
        switch target {
        case .sencha:
            ""
        case .oolong:
            String(localized: "promotion.area.oolong", defaultValue: "Bambushain")
        case .matcha:
            String(localized: "promotion.area.matcha", defaultValue: "Mondbrücke")
        }
    }

    private var acceptTitle: String {
        switch target {
        case .sencha:
            ""
        case .oolong:
            String(localized: "promotion.accept.oolong", defaultValue: "Weiter mit Oolong")
        case .matcha:
            String(localized: "promotion.accept.matcha", defaultValue: "Weiter mit Matcha")
        }
    }

    private var promotionBody: String {
        String(localized: "promotion.body", defaultValue: "Du hast dich gut eingespielt. Wenn du magst, geht es jetzt etwas weiter.")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Space.space6) {
                GardenScene(
                    oolongUnlocked: target >= .oolong,
                    matchaUnlocked: target >= .matcha
                )
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: Radius.radiusXl))
                .accessibilityHidden(true)

                VStack(spacing: Space.space2) {
                    Text(String(localized: "promotion.title", defaultValue: "Ein neuer Bereich öffnet sich"))
                        .font(.mmTitle)
                        .foregroundStyle(Color("ink"))
                        .multilineTextAlignment(.center)
                    Text(areaName)
                        .font(.mmHeadline)
                        .foregroundStyle(Color("ink"))
                    Text(promotionBody)
                        .font(.mmBody)
                        .foregroundStyle(Color("text"))
                        .multilineTextAlignment(.center)
                }

                GlassCard(radius: Radius.radiusLg) {
                    VStack(alignment: .leading, spacing: Space.space2) {
                        Text(String(localized: "promotion.newGames", defaultValue: "Neu dabei"))
                            .font(.mmCallout)
                            .foregroundStyle(Color("ink"))
                        ForEach(newGames) { entry in
                            Text(LocalizedStringKey(entry.nameKey))
                                .font(.mmBody)
                                .foregroundStyle(Color("text"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: Space.space3) {
                    PrimaryButton(acceptTitle) {
                        playerStore.acceptPromotion(to: target)
                        onDone()
                    }
                    .accessibilityIdentifier("promotion.accept")
                    GlassButton(String(localized: "promotion.defer", defaultValue: "Lieber noch bleiben")) {
                        playerStore.deferPromotion()
                        onDone()
                    }
                    .accessibilityIdentifier("promotion.defer")
                }
            }
            .frame(maxWidth: Size.readingMax)
            .padding(Space.space6)
            .frame(maxWidth: .infinity)
        }
        .background(Color("bg-tea"))
    }
}

#Preview("Hell") {
    PromotionMomentView(target: .oolong, onDone: {})
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    PromotionMomentView(target: .matcha, onDone: {})
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
