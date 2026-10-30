// MosaicBedGame.swift
// Spiel 3 aus dem Spiele-Katalog (MASTER-PROMPT.md, Abschnitt 6, Zeile 3):
// "Das Mosaik-Beet" - Logik, Platzierung nach Nachbarschaftsregeln.
//
// Gewähltes Regel-Set (Auftrag: "wähle 2-4 klare, kombinierbare Regeln ...
// dokumentiere dein gewähltes Regel-Set klar im Code-Kommentar"):
//   1. Zeilen-Regel: Jede Reihe enthält jede Pflanzenart genau einmal.
//   2. Spalten-Regel: Jede Spalte enthält jede Pflanzenart genau einmal.
//      (Regeln 1+2 zusammen ergeben ein lateinisches Quadrat - die Anzahl
//      Pflanzenarten entspricht deshalb immer der Rastergröße. Sencha
//      nutzt NUR diese 2 Regeln: Katalog "4×4, 2 Regeln".)
//   3. Nachbar-Verbot 1: ein festes Paar Pflanzenarten darf nie direkt
//      orthogonal (oben/unten/links/rechts) benachbart stehen. Ab Oolong,
//      3. Regel: Katalog "5×5, 3 Regeln".
//   4. Nachbar-Verbot 2: ein zweites, anderes Paar Pflanzenarten darf
//      ebenfalls nie direkt orthogonal benachbart stehen. Ab Matcha,
//      4. Regel: Katalog "6×6, 4 Regeln, ohne Hinweis".
//
// Diese Kombination ist klassisch eindeutig lösbar generierbar (lateinisches
// Quadrat + wenige Nachbarschafts-Einschränkungen) - siehe `MosaicBedSolver`
// und `MosaicBedGenerator` für den Beweis per Backtracking-Zähler.

import Foundation

/// Eine Pflanzenart im Mosaik-Beet. Form (SF-Symbol) ist pro Art immer
/// eindeutig; die Farbe wiederholt sich alle 3 Arten (siehe `colorToken`) -
/// das erfüllt das Designsystem-Gebot "Farben immer zusätzlich durch Form
/// unterscheidbar", weil die Form dadurch NIE allein von der Farbe abhängt.
public enum MosaicPlantType: Int, CaseIterable, Hashable, Sendable {
    case leaf
    case drop
    case sun
    case star
    case moon
    case flame

    /// SF-Symbol-Name für diese Pflanzenart (Form-Unterscheidung).
    public var symbolName: String {
        switch self {
        case .leaf: "leaf.fill"
        case .drop: "drop.fill"
        case .sun: "sun.max.fill"
        case .star: "star.fill"
        case .moon: "moon.fill"
        case .flame: "flame.fill"
        }
    }

    /// Farbtoken aus dem Designsystem (Rolle "Spielwelt",
    /// `design/designsystem-tokens.json`). Wiederholt sich alle 3 Arten -
    /// siehe Typ-Kommentar.
    public var colorToken: String {
        ["matcha-300", "blossom-300", "gold-300"][rawValue % 3]
    }
}

/// Ein verbotenes Nachbar-Paar (Regeln 3/4): die beiden genannten Arten
/// dürfen nie orthogonal direkt benachbart stehen. Ungeordnet - `forbids`
/// prüft beide Reihenfolgen.
public struct MosaicAdjacencyBan: Equatable, Sendable {
    public let first: MosaicPlantType
    public let second: MosaicPlantType

    public init(_ first: MosaicPlantType, _ second: MosaicPlantType) {
        self.first = first
        self.second = second
    }

    public func forbids(_ a: MosaicPlantType, _ b: MosaicPlantType) -> Bool {
        (a == first && b == second) || (a == second && b == first)
    }
}

/// Parameter je Tee-Stufe (MASTER-PROMPT.md, Abschnitt 6, Zeile 3).
public struct MosaicBedParameters: Sendable {
    /// Rastergröße (4, 5 oder 6) - zugleich Anzahl Pflanzenarten, siehe
    /// Regeln 1+2 oben.
    public let gridSize: Int
    /// Zusätzliche Nachbar-Verbote (Regeln 3/4); leer bei Sencha.
    public let forbiddenAdjacentPairs: [MosaicAdjacencyBan]
    /// Nur bei Sencha verfügbar (Katalog: "ohne Hinweis" ab Oolong/Matcha).
    public let hintAvailable: Bool

    public init(gridSize: Int, forbiddenAdjacentPairs: [MosaicAdjacencyBan], hintAvailable: Bool) {
        self.gridSize = gridSize
        self.forbiddenAdjacentPairs = forbiddenAdjacentPairs
        self.hintAvailable = hintAvailable
    }

    /// Pflanzenarten dieser Stufe: die ersten `gridSize` Fälle von
    /// `MosaicPlantType` (siehe Regel 1+2: Anzahl Arten == Rastergröße).
    public var plantTypes: [MosaicPlantType] {
        Array(MosaicPlantType.allCases.prefix(gridSize))
    }
}

/// Definition des Spiels "Das Mosaik-Beet" für den Spiel-Baukasten.
public struct MosaicBedGame: GameDefinition {
    public typealias Parameters = MosaicBedParameters

    public let id = "mosaic-bed"
    public let nameKey = "game.mosaicBed.name"
    public let area: GameArea = .logic
    public let minLevel: TeaLevel = .sencha
    public let instructionPageCount = 3
    public let shortRuleKeys = [
        "game.mosaicBed.rule1",
        "game.mosaicBed.rule2",
        "game.mosaicBed.rule3",
        "game.mosaicBed.rule4",
    ]
    /// Laut Spiele-Katalog ist für dieses Spiel keine Proberunde vermerkt.
    public let hasTrialRound = false
    public let parameters: [TeaLevel: MosaicBedParameters] = [
        .sencha: MosaicBedParameters(gridSize: 4, forbiddenAdjacentPairs: [], hintAvailable: true),
        .oolong: MosaicBedParameters(
            gridSize: 5,
            forbiddenAdjacentPairs: [MosaicAdjacencyBan(.sun, .moon)],
            hintAvailable: false
        ),
        .matcha: MosaicBedParameters(
            gridSize: 6,
            forbiddenAdjacentPairs: [MosaicAdjacencyBan(.sun, .moon), MosaicAdjacencyBan(.leaf, .flame)],
            hintAvailable: false
        ),
    ]

    public init() {}
}
