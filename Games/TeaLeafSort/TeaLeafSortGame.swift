// TeaLeafSortGame.swift
// Spiel 4 aus dem Spiele-Katalog (MASTER-PROMPT.md, Abschnitt 6, Zeile 4):
// "Teeblätter sortieren" - Flexibilität nach dem Wisconsin-Prinzip (Wisconsin
// Card Sorting Test): Karten haben drei unabhängige Eigenschaften (Farbe,
// Form, Anzahl). Der Spieler sortiert jede Karte zu einer von 3 festen
// Ablagen; welche Ablage richtig ist, bestimmt eine gerade geltende
// Eigenschaft ("Regel", z. B. "nach Farbe"). Nach einer festen Anzahl
// richtiger Zuordnungen in Folge wechselt die Regel - ob angekündigt
// (Sencha) oder nicht (Oolong/Matcha) und ob eine oder zwei Regeln
// gleichzeitig gelten (Matcha), siehe `TeaLeafSortParameters`.
//
// `PuzzleSolvable` wird hier NICHT benötigt (Auftrag): keine Rätsel-
// Eindeutigkeit, sondern eine Klassifikationsaufgabe mit per Definition
// immer genau einer richtigen Ablage je Karte (siehe `generateCard`).

import Foundation

/// Die drei unabhängigen Eigenschaften einer Teeblatt-Karte. Welche davon
/// gerade "die Regel" ist (bzw. bei Matcha: welche zwei), bestimmt
/// `TeaLeafSortGenerator.pickNewActiveDimensions`.
public enum TeaLeafDimension: CaseIterable, Hashable, Sendable {
    case color
    case shape
    case count
}

/// Eine einzelne Teeblatt-Karte. Jede Eigenschaft hat 3 mögliche Werte
/// (Index 0-2), unabhängig voneinander gewählt (siehe `generateCard`).
public struct TeaLeafCard: Equatable, Sendable {
    public let colorIndex: Int
    public let shapeIndex: Int
    public let countIndex: Int

    public init(colorIndex: Int, shapeIndex: Int, countIndex: Int) {
        self.colorIndex = colorIndex
        self.shapeIndex = shapeIndex
        self.countIndex = countIndex
    }

    public func valueIndex(for dimension: TeaLeafDimension) -> Int {
        switch dimension {
        case .color: colorIndex
        case .shape: shapeIndex
        case .count: countIndex
        }
    }
}

/// Parameter je Tee-Stufe (MASTER-PROMPT.md, Abschnitt 6, Zeile 4).
public struct TeaLeafSortParameters: Sendable {
    /// 1 (Sencha/Oolong) oder 2 (Matcha: "zwei Regeln gleichzeitig").
    public let activeDimensionCount: Int
    /// Sencha: Regelwechsel wird vorher angekündigt. Oolong/Matcha: nicht.
    public let announceRuleChange: Bool

    public init(activeDimensionCount: Int, announceRuleChange: Bool) {
        self.activeDimensionCount = activeDimensionCount
        self.announceRuleChange = announceRuleChange
    }
}

/// Definition des Spiels "Teeblätter sortieren" für den Spiel-Baukasten.
public struct TeaLeafSortGame: GameDefinition {
    public typealias Parameters = TeaLeafSortParameters

    public let id = "tea-leaf-sort"
    public let nameKey = "game.teaLeafSort.name"
    public let area: GameArea = .flexibility
    public let minLevel: TeaLevel = .sencha
    public let instructionPageCount = 3
    public let shortRuleKeys = [
        "game.teaLeafSort.rule1",
        "game.teaLeafSort.rule2",
        "game.teaLeafSort.rule3",
        "game.teaLeafSort.rule4",
    ]
    /// Laut Spiele-Katalog ist für dieses Spiel keine Proberunde vermerkt.
    public let hasTrialRound = false
    public let parameters: [TeaLevel: TeaLeafSortParameters] = [
        .sencha: TeaLeafSortParameters(activeDimensionCount: 1, announceRuleChange: true),
        .oolong: TeaLeafSortParameters(activeDimensionCount: 1, announceRuleChange: false),
        .matcha: TeaLeafSortParameters(activeDimensionCount: 2, announceRuleChange: false),
    ]

    public init() {}
}

/// Generiert Karten und verwaltet, welche Eigenschaft(en) aktuell "die
/// Regel" sind.
public enum TeaLeafSortGenerator {
    /// Mögliche Werte je Eigenschaft (3 Ablagen, siehe Datei-Kommentar).
    public static let valueCount = 3

    /// Anzahl richtiger Zuordnungen in Folge, nach der die Regel wechselt
    /// (Auftrag: "nach einer bestimmten Anzahl richtiger Zuordnungen
    /// wechselt die Regel"). Bewusst stufenunabhängig konstant - der
    /// Katalog gibt hierfür keinen Wert vor; die Schwierigkeit entsteht
    /// durch Ankündigung (Sencha/Oolong) bzw. Regel-Anzahl (Matcha), nicht
    /// durch diese Schwelle.
    public static let switchAfterCorrectCount = 5

    /// Erzeugt eine Karte, deren Wert auf jeder aktiven Eigenschaft genau
    /// `targetPileIndex` ist - dadurch passt IMMER genau eine der 3
    /// Ablagen (die mit Index `targetPileIndex`, siehe
    /// `TeaLeafSortGameView.referenceCards`), unabhängig davon, ob 1 oder
    /// 2 Eigenschaften gerade aktiv sind. Inaktive Eigenschaften werden
    /// zufällig befüllt und sind reine Ablenkung.
    public static func generateCard<RNG: RandomNumberGenerator>(
        targetPileIndex: Int,
        activeDimensions: Set<TeaLeafDimension>,
        using rng: inout RNG
    ) -> TeaLeafCard {
        var colorIndex = Int.random(in: 0..<valueCount, using: &rng)
        var shapeIndex = Int.random(in: 0..<valueCount, using: &rng)
        var countIndex = Int.random(in: 0..<valueCount, using: &rng)
        if activeDimensions.contains(.color) { colorIndex = targetPileIndex }
        if activeDimensions.contains(.shape) { shapeIndex = targetPileIndex }
        if activeDimensions.contains(.count) { countIndex = targetPileIndex }
        return TeaLeafCard(colorIndex: colorIndex, shapeIndex: shapeIndex, countIndex: countIndex)
    }

    /// Bequemlichkeits-Überladung mit der echten Systemzufallsquelle.
    public static func generateCard(targetPileIndex: Int, activeDimensions: Set<TeaLeafDimension>) -> TeaLeafCard {
        var rng = SystemRandomNumberGenerator()
        return generateCard(targetPileIndex: targetPileIndex, activeDimensions: activeDimensions, using: &rng)
    }

    /// Alle möglichen Eigenschafts-Kombinationen der gewünschten Größe (1
    /// oder 2 von insgesamt 3 Eigenschaften) - fest aufgezählt statt
    /// allgemeiner Kombinatorik, da es dafür nur diese zwei Fälle gibt.
    public static func possibleActiveDimensionSets(count: Int) -> [Set<TeaLeafDimension>] {
        switch count {
        case 1:
            return TeaLeafDimension.allCases.map { Set([$0]) }
        case 2:
            return [[.color, .shape], [.color, .count], [.shape, .count]]
        default:
            return [Set(TeaLeafDimension.allCases)]
        }
    }

    /// Wählt eine neue aktive Eigenschafts-Menge, die sich von `previous`
    /// unterscheidet (sonst wäre es kein Wechsel).
    public static func pickNewActiveDimensions<RNG: RandomNumberGenerator>(
        count: Int,
        excluding previous: Set<TeaLeafDimension>,
        using rng: inout RNG
    ) -> Set<TeaLeafDimension> {
        let candidates = possibleActiveDimensionSets(count: count).filter { $0 != previous }
        return candidates.randomElement(using: &rng) ?? previous
    }

    /// Bequemlichkeits-Überladung mit der echten Systemzufallsquelle.
    public static func pickNewActiveDimensions(count: Int, excluding previous: Set<TeaLeafDimension>) -> Set<TeaLeafDimension> {
        var rng = SystemRandomNumberGenerator()
        return pickNewActiveDimensions(count: count, excluding: previous, using: &rng)
    }
}
