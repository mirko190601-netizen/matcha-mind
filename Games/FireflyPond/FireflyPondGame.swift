// FireflyPondGame.swift
// Spiel 2 aus dem Spiele-Katalog (MASTER-PROMPT.md, Abschnitt 6):
// "Glühwürmchen am Teich" - Fokus nach dem Go/No-Go-Prinzip. Glühwürmchen
// in der Zielfarbe erscheinen (Go: antippen), Falter und andersfarbige
// Glühwürmchen sind Ablenkung (No-Go: nicht antippen).
//
// `PuzzleSolvable` wird hier nicht benoetigt: es ist kein Logikraetsel mit
// mehreren moeglichen Loesungen, sondern eine Reihe unabhaengiger
// Go/No-Go-Entscheidungen.

import Foundation

/// Farbvarianten der Glühwürmchen. Da die vorhandene Illustration
/// (`Illustration/CreatureIllustrations.swift`, `SmallCreatureIllustration`)
/// nur eine feste Farbgebung mitbringt, wird die "Zielfarbe" durch Einfärben
/// derselben Illustration mit einem vorhandenen Welt-Farbtoken dargestellt
/// (`design/designsystem-tokens.json`, Rolle "Spielwelt") - keine neue
/// Illustration, kein neues Token.
public enum FireflyColor: CaseIterable, Equatable, Sendable {
    case gold
    case blossom
    case matcha

    /// Name des Farbtokens aus dem Designsystem (Rolle "Spielwelt").
    public var colorToken: String {
        switch self {
        case .gold: "gold-300"
        case .blossom: "blossom-300"
        case .matcha: "matcha-300"
        }
    }
}

/// Parameter je Tee-Stufe (MASTER-PROMPT.md, Abschnitt 6, Zeile 2).
public struct FireflyPondParameters: Sendable {
    /// Farben, die in dieser Stufe als Glühwürmchen vorkommen können. Die
    /// Zielfarbe ist je Runde eine davon; alle übrigen sind - zusammen mit
    /// dem Falter - Ablenkung.
    public let availableColors: [FireflyColor]

    /// Anteil der Objekte insgesamt, die KEIN Zielfarbe-Glühwürmchen sind
    /// (Falter + andersfarbige Glühwürmchen zusammen). Sencha 0.3 (30 %),
    /// Oolong/Matcha 0.5 (50 %) - siehe Katalog.
    public let distractionRatio: Double

    /// Matcha: die Zielfarbe wechselt einmal in der Mitte der Runde.
    public let targetSwitchesMidRound: Bool

    public init(availableColors: [FireflyColor], distractionRatio: Double, targetSwitchesMidRound: Bool) {
        self.availableColors = availableColors
        self.distractionRatio = distractionRatio
        self.targetSwitchesMidRound = targetSwitchesMidRound
    }
}

/// Definition des Spiels "Glühwürmchen am Teich" für den Spiel-Baukasten.
public struct FireflyPondGame: GameDefinition {
    public typealias Parameters = FireflyPondParameters

    public let id = "firefly-pond"
    public let nameKey = "game.fireflyPond.name"
    public let area: GameArea = .focus
    public let minLevel: TeaLevel = .sencha
    public let instructionPageCount = 3
    public let shortRuleKeys = [
        "game.fireflyPond.rule1",
        "game.fireflyPond.rule2",
        "game.fireflyPond.rule3",
    ]
    /// Laut Spiele-Katalog ist für dieses Spiel keine Proberunde vermerkt.
    public let hasTrialRound = false
    public let parameters: [TeaLevel: FireflyPondParameters] = [
        .sencha: FireflyPondParameters(availableColors: [.gold], distractionRatio: 0.3, targetSwitchesMidRound: false),
        .oolong: FireflyPondParameters(
            availableColors: [.gold, .blossom, .matcha],
            distractionRatio: 0.5,
            targetSwitchesMidRound: false
        ),
        .matcha: FireflyPondParameters(
            availableColors: [.gold, .blossom, .matcha],
            distractionRatio: 0.5,
            targetSwitchesMidRound: true
        ),
    ]

    public init() {}
}

/// Ein einzelnes erscheinendes Objekt: entweder ein Glühwürmchen in einer
/// bestimmten Farbe oder ein Falter.
public enum FireflyPondObjectKind: Equatable, Sendable {
    case firefly(FireflyColor)
    case moth
}

/// Generiert die Abfolge erscheinender Objekte einer Runde (oder
/// Rundenhälfte, siehe `targetSwitchesMidRound`).
///
/// Mathematik hinter `distractionRatio` (siehe Auftrag: "50 % Ablenkung"):
/// über alle erzeugten Objekte gemittelt ist die Wahrscheinlichkeit, dass
/// ein Objekt NICHT die Zielfarbe trägt - egal ob Falter oder eine andere
/// Glühwürmchen-Farbe -, gleich `distractionRatio`. Diese Wahrscheinlichkeit
/// wird gleichmäßig auf alle Ablenkungs-Arten verteilt (Falter + jede
/// Nicht-Zielfarbe), damit keine einzelne Ablenkungsart bevorzugt auftritt.
public enum FireflyPondSpawnGenerator {
    public static func generate<RNG: RandomNumberGenerator>(
        count: Int,
        parameters: FireflyPondParameters,
        targetColor: FireflyColor,
        using rng: inout RNG
    ) -> [FireflyPondObjectKind] {
        precondition(count > 0, "Anzahl muss positiv sein")
        precondition(
            parameters.availableColors.contains(targetColor),
            "targetColor muss zu den Farben dieser Stufe gehören"
        )

        let distractorKinds: [FireflyPondObjectKind] = [.moth] + parameters.availableColors
            .filter { $0 != targetColor }
            .map { .firefly($0) }

        var result: [FireflyPondObjectKind] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            if Double.random(in: 0..<1, using: &rng) < parameters.distractionRatio {
                result.append(distractorKinds.randomElement(using: &rng) ?? .moth)
            } else {
                result.append(.firefly(targetColor))
            }
        }
        return result
    }

    /// Bequemlichkeits-Überladung mit der echten Systemzufallsquelle für
    /// den produktiven Einsatz (Tests nutzen die `rng:`-Variante mit einem
    /// festen Seed).
    public static func generate(
        count: Int,
        parameters: FireflyPondParameters,
        targetColor: FireflyColor
    ) -> [FireflyPondObjectKind] {
        var rng = SystemRandomNumberGenerator()
        return generate(count: count, parameters: parameters, targetColor: targetColor, using: &rng)
    }
}
