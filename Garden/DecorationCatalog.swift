// DecorationCatalog.swift
// Deko-Shop (MASTER-PROMPT.md, Block B4 Aufgabe 4.5): die kaeuflichen
// Garten-Stuecke mit Preis in Tau. Reine Foundation-Logik; gekauft wird
// ueber `PlayerStore.purchaseDecoration(id:)`.

import Foundation

struct DecorationItem: Identifiable, Equatable, Sendable {
    let id: String
    /// Preis in Tautropfen.
    let price: Int

    /// Name aus dem String Catalog (`garden.shop.item.*`). Als Literal-Aufrufe
    /// geschrieben, damit die Lokalisierungs-Pruefung die Schluessel findet.
    var name: String {
        switch id {
        case "stepping-stones": String(localized: "garden.shop.item.stepping-stones", defaultValue: "Trittsteine")
        case "stone-lantern": String(localized: "garden.shop.item.stone-lantern", defaultValue: "Steinlaterne")
        case "bonsai": String(localized: "garden.shop.item.bonsai", defaultValue: "Bonsai")
        case "lantern-chain": String(localized: "garden.shop.item.lantern-chain", defaultValue: "Laternenkette")
        case "moon-bridge-lantern": String(localized: "garden.shop.item.moon-bridge-lantern", defaultValue: "Mondbrücken-Laterne")
        case "cherry-tree": String(localized: "garden.shop.item.cherry-tree", defaultValue: "Kirschbaum")
        default: id
        }
    }
}

enum DecorationCatalog {
    static let items: [DecorationItem] = [
        DecorationItem(id: "stepping-stones", price: 24),
        DecorationItem(id: "stone-lantern", price: 36),
        DecorationItem(id: "bonsai", price: 48),
        DecorationItem(id: "lantern-chain", price: 60),
        DecorationItem(id: "moon-bridge-lantern", price: 84),
        DecorationItem(id: "cherry-tree", price: 120),
    ]

    static func item(id: String) -> DecorationItem? {
        items.first { $0.id == id }
    }
}
