// DecorationShopView.swift
// Deko-Shop (MASTER-PROMPT.md, Block B4 Aufgabe 4.5): Sheet mit einer
// Glas-Karte je Deko-Stueck aus `DecorationCatalog`. Kauf ueber
// `PlayerStore.purchaseDecoration(id:)`. Zu wenig Tau: der Knopf ist
// deaktiviert, ein ruhiger Hinweis nennt, wie viel fehlt (kein Rot, kein Druck).

import SwiftUI

struct DecorationShopView: View {
    @Environment(PlayerStore.self) private var playerStore
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Space.space4) {
                Text(String(localized: "garden.shop.title", defaultValue: "Deko-Shop"))
                    .font(.mmTitle)
                    .foregroundStyle(Color("ink"))
                DewChip(amount: playerStore.dewDrops)
                ForEach(DecorationCatalog.items) { item in
                    row(for: item)
                }
                GlassButton(String(localized: "garden.shop.close", defaultValue: "Fertig"), action: onClose)
                    .accessibilityIdentifier("shop.close")
            }
            .padding(Space.space4)
            .frame(maxWidth: Size.readingMax)
            .frame(maxWidth: .infinity)
        }
        .background(Color("bg-garden"))
        .accessibilityIdentifier("garden.shop")
    }

    private func row(for item: DecorationItem) -> some View {
        let owned = playerStore.ownedDecorationIDs.contains(item.id)
        let missing = item.price - playerStore.dewDrops
        return GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            VStack(alignment: .leading, spacing: Space.space2) {
                HStack {
                    Text(item.name)
                        .font(.mmHeadline)
                        .foregroundStyle(Color("ink"))
                    Spacer()
                    Text(String(format: String(localized: "garden.dew.label", defaultValue: "%lld Tau"), item.price))
                        .font(.mmLabel)
                        .foregroundStyle(Color("text"))
                }
                if owned {
                    Text(String(localized: "garden.shop.owned", defaultValue: "Steht in deinem Garten"))
                        .font(.mmBody)
                        .foregroundStyle(Color("text"))
                } else {
                    if missing > 0 {
                        Text(String(format: String(localized: "garden.shop.needMore", defaultValue: "Dir fehlen noch %lld Tau. Spiel einfach in Ruhe weiter."), missing))
                            .font(.mmCaption)
                            .foregroundStyle(Color("text-muted"))
                    }
                    GlassButton(String(localized: "garden.shop.buy", defaultValue: "Kaufen")) {
                        playerStore.purchaseDecoration(id: item.id)
                    }
                    .disabled(missing > 0)
                    .accessibilityIdentifier("shop.buy.\(item.id)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Tau-Anzeige als Glas-Chip (Garten-Startseite und Shop).
struct DewChip: View {
    let amount: Int

    var body: some View {
        GlassCard(radius: Radius.radiusPill, padding: Space.space3) {
            HStack(spacing: Space.space1) {
                Image(systemName: "drop.fill")
                    .foregroundStyle(Color("tau-700"))
                Text(String(format: String(localized: "garden.dew.label", defaultValue: "%lld Tau"), amount))
                    .font(.mmLabel)
                    .foregroundStyle(Color("text"))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "garden.dew.a11y", defaultValue: "%lld Tautropfen"), amount))
        .accessibilityIdentifier("garden.dew")
    }
}

#Preview("Shop") {
    DecorationShopView(onClose: {})
        .environment(PlayerStore.preview())
}
