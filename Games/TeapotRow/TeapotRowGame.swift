// TeapotRowGame.swift
// Spiel 1 aus dem Spiele-Katalog (MASTER-PROMPT.md, Abschnitt 6):
// "Teekannen-Reihe" - Räumliches Gedächtnis nach dem Corsi-Block-Prinzip.
// Eine zufällige Sequenz von Teekannen-Positionen leuchtet auf, der Spieler
// tippt sie danach in der geforderten Reihenfolge nach (Sencha/Oolong
// vorwärts, Matcha rückwärts - siehe `TeapotRowParameters.direction`).
//
// `PuzzleSolvable` wird hier bewusst NICHT verwendet (siehe Auftrag,
// Block B3 Aufgabe 2): es handelt sich um eine Merkaufgabe, nicht um ein
// Logikrätsel mit mehreren möglichen Lösungen - jede generierte Sequenz
// ist "die" Lösung.

import Foundation

/// Reihenfolge, in der die aufgeleuchtete Sequenz nachgetippt werden muss.
public enum TeapotRowDirection: Equatable, Sendable {
    /// Sencha und Oolong: in der gezeigten Reihenfolge.
    case forward
    /// Matcha: in umgekehrter Reihenfolge (zuletzt gezeigte Position zuerst).
    case backward
}

/// Parameter je Tee-Stufe (MASTER-PROMPT.md, Abschnitt 6, Zeile 1).
public struct TeapotRowParameters: Sendable {
    /// Erlaubte Sequenzlänge dieser Stufe; `FineLevelTracker.lowerBound`/
    /// `upperBound` übernehmen genau diesen Bereich, die aktuelle
    /// `FineLevelTracker.fineLevel` ist direkt die Länge der naechsten Runde.
    public let sequenceLengthRange: ClosedRange<Int>
    public let direction: TeapotRowDirection

    public init(sequenceLengthRange: ClosedRange<Int>, direction: TeapotRowDirection) {
        self.sequenceLengthRange = sequenceLengthRange
        self.direction = direction
    }
}

/// Definition des Spiels "Teekannen-Reihe" für den Spiel-Baukasten
/// (`Games/Core/GameDefinition.swift`).
public struct TeapotRowGame: GameDefinition {
    public typealias Parameters = TeapotRowParameters

    /// Anzahl der Teekannen-Positionen im Raster, über alle Stufen gleich
    /// (3×3-Raster). Die Schwierigkeit kommt aus der Sequenzlänge und der
    /// Richtung (siehe `TeapotRowParameters`), nicht aus der Rastergröße.
    public static let positionCount = 9

    public let id = "teapot-row"
    public let nameKey = "game.teapotRow.name"
    public let area: GameArea = .spatialMemory
    public let minLevel: TeaLevel = .sencha
    public let instructionPageCount = 3
    public let shortRuleKeys = [
        "game.teapotRow.rule1",
        "game.teapotRow.rule2",
        "game.teapotRow.rule3",
    ]
    /// Laut Spiele-Katalog ist für dieses Spiel keine Proberunde vermerkt.
    public let hasTrialRound = false
    public let parameters: [TeaLevel: TeapotRowParameters] = [
        .sencha: TeapotRowParameters(sequenceLengthRange: 3...5, direction: .forward),
        .oolong: TeapotRowParameters(sequenceLengthRange: 5...7, direction: .forward),
        .matcha: TeapotRowParameters(sequenceLengthRange: 7...9, direction: .backward),
    ]

    public init() {}
}

/// Generiert die zufällige Positions-Sequenz einer Merk-Runde.
///
/// Entscheidung zur Wiederholung (siehe Auftrag: "ohne Wiederholung direkt
/// hintereinander ist ok, aber dokumentiere deine Wahl"): dieselbe Position
/// darf in der Sequenz mehrfach vorkommen, aber nicht zweimal direkt
/// hintereinander - zwei gleiche Positionen in Folge sähen beim Aufleuchten
/// wie ein einzelner, länger leuchtender Punkt aus und wären nicht als
/// zwei getrennte Schritte erkennbar.
public enum TeapotRowSequenceGenerator {
    /// - Parameters:
    ///   - length: Sequenzlänge (siehe `TeapotRowParameters.sequenceLengthRange`).
    ///   - positionCount: Anzahl verfügbarer Positionen (`TeapotRowGame.positionCount`).
    ///   - rng: Injizierbarer Zufallszahlengenerator für deterministische Tests.
    public static func generate<RNG: RandomNumberGenerator>(
        length: Int,
        positionCount: Int,
        using rng: inout RNG
    ) -> [Int] {
        precondition(length > 0, "Sequenzlänge muss positiv sein")
        precondition(positionCount > 1, "Mindestens 2 Positionen nötig, um direkte Wiederholung zu vermeiden")

        var sequence: [Int] = []
        sequence.reserveCapacity(length)
        var previous = -1
        for _ in 0..<length {
            var next = Int.random(in: 0..<positionCount, using: &rng)
            while next == previous {
                next = Int.random(in: 0..<positionCount, using: &rng)
            }
            sequence.append(next)
            previous = next
        }
        return sequence
    }

    /// Bequemlichkeits-Überladung mit der echten Systemzufallsquelle für
    /// den produktiven Einsatz (Tests nutzen die `rng:`-Variante mit einem
    /// festen Seed).
    public static func generate(length: Int, positionCount: Int) -> [Int] {
        var rng = SystemRandomNumberGenerator()
        return generate(length: length, positionCount: positionCount, using: &rng)
    }
}
