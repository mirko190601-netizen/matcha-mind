// BambooMathGame.swift
// Spiel 5 aus dem Spiele-Katalog (MASTER-PROMPT.md, Abschnitt 6):
// "Bambus-Rechnen" - Kopfrechnen nach dem Rechenketten-Prinzip. Eine Kette
// aus Start-Zahl und mehreren Operationen ("12 + 5 − 3 ...") wird komplett
// angezeigt, der Spieler gibt das Endergebnis ein (siehe
// `BambooMathGameView` fuer die genaue Interaktion).
//
// `PuzzleSolvable` wird hier bewusst NICHT verwendet (wie bei
// `TeapotRowGame`, siehe dessen Dokumentation): das Rechenergebnis ist durch
// die Kette eindeutig bestimmt, es gibt kein Raetsel mit mehreren moeglichen
// Loesungen.

import Foundation

/// Rechenzeichen einer Kette.
public enum BambooMathOperator: Sendable, Hashable, CaseIterable {
    case add
    case subtract
    case multiply
    case divide

    /// Rechenzeichen fuer die Anzeige der Kette ("12 + 5 − 3"). Mathematische
    /// Zeichen sind sprachunabhaengig und werden daher - wie die Zahlen
    /// selbst in keinem Spiel - nicht ueber den String Catalog lokalisiert.
    public var symbol: String {
        switch self {
        case .add: "+"
        case .subtract: "−"
        case .multiply: "×"
        case .divide: "÷"
        }
    }

    /// Gesprochenes Wort fuer VoiceOver: Rechenzeichen wie "−" oder "÷"
    /// werden von VoiceOver nicht zuverlaessig als "minus"/"geteilt durch"
    /// vorgelesen, daher eine eigene gesprochene Form je Sprache.
    public var spokenWord: String {
        switch self {
        case .add:
            String(localized: "game.bambooMath.operator.add", defaultValue: "plus")
        case .subtract:
            String(localized: "game.bambooMath.operator.subtract", defaultValue: "minus")
        case .multiply:
            String(localized: "game.bambooMath.operator.multiply", defaultValue: "mal")
        case .divide:
            String(localized: "game.bambooMath.operator.divide", defaultValue: "geteilt durch")
        }
    }
}

/// Ein einzelner Schritt der Kette: Rechenzeichen, der dabei verwendete
/// zweite Operand (z. B. der Summand bei `+`, der Divisor bei `÷`) und das
/// Zwischenergebnis NACH diesem Schritt.
public struct BambooMathStep: Sendable, Equatable {
    public let operatorKind: BambooMathOperator
    public let operand: Int
    public let result: Int

    public init(operatorKind: BambooMathOperator, operand: Int, result: Int) {
        self.operatorKind = operatorKind
        self.operand = operand
        self.result = result
    }
}

/// Eine vollstaendige Rechenkette: Start-Zahl plus eine Folge von Schritten.
public struct BambooMathChain: Sendable, Equatable {
    public let start: Int
    public let steps: [BambooMathStep]

    public init(start: Int, steps: [BambooMathStep]) {
        self.start = start
        self.steps = steps
    }

    /// Das gesuchte Endergebnis - das Zwischenergebnis des letzten Schritts,
    /// oder die Start-Zahl, falls die Kette (theoretisch) keine Schritte hat.
    public var finalResult: Int { steps.last?.result ?? start }

    /// Anzeige-Text der Kette ohne Endergebnis, z. B. "12 + 5 − 3".
    public var displayExpression: String {
        var parts = ["\(start)"]
        for step in steps {
            parts.append(step.operatorKind.symbol)
            parts.append("\(step.operand)")
        }
        return parts.joined(separator: " ")
    }

    /// Wie `displayExpression`, aber mit gesprochenen Rechenzeichen fuer
    /// VoiceOver (`BambooMathOperator.spokenWord`).
    public var accessibilityExpression: String {
        var parts = ["\(start)"]
        for step in steps {
            parts.append(step.operatorKind.spokenWord)
            parts.append("\(step.operand)")
        }
        return parts.joined(separator: " ")
    }
}

/// Parameter je Tee-Stufe (MASTER-PROMPT.md, Abschnitt 6, Zeile 5):
/// Anzahl Schritte, Obergrenze der vorkommenden Zahlen (Untergrenze ist
/// stets 0 - "nie negativ") und erlaubte Rechenzeichen.
public struct BambooMathParameters: Sendable {
    public let stepCountRange: ClosedRange<Int>
    public let numberUpperBound: Int
    public let allowedOperators: [BambooMathOperator]

    public init(stepCountRange: ClosedRange<Int>, numberUpperBound: Int, allowedOperators: [BambooMathOperator]) {
        self.stepCountRange = stepCountRange
        self.numberUpperBound = numberUpperBound
        self.allowedOperators = allowedOperators
    }
}

/// Definition des Spiels "Bambus-Rechnen" fuer den Spiel-Baukasten.
public struct BambooMathGame: GameDefinition {
    public typealias Parameters = BambooMathParameters

    public let id = "bamboo-math"
    public let nameKey = "game.bambooMath.name"
    public let area: GameArea = .mentalMath
    public let minLevel: TeaLevel = .sencha
    public let instructionPageCount = 3
    public let shortRuleKeys = [
        "game.bambooMath.rule1",
        "game.bambooMath.rule2",
        "game.bambooMath.rule3",
    ]
    /// Laut Spiele-Katalog ist für dieses Spiel keine Proberunde vermerkt.
    public let hasTrialRound = false
    public let parameters: [TeaLevel: BambooMathParameters] = [
        .sencha: BambooMathParameters(stepCountRange: 3...3, numberUpperBound: 20, allowedOperators: [.add, .subtract]),
        .oolong: BambooMathParameters(
            stepCountRange: 4...5,
            numberUpperBound: 50,
            allowedOperators: [.add, .subtract, .multiply]
        ),
        .matcha: BambooMathParameters(
            stepCountRange: 6...6,
            numberUpperBound: 100,
            allowedOperators: [.add, .subtract, .multiply, .divide]
        ),
    ]

    /// Seiten der Spielanleitung. Oeffentlich auf dem Spiel selbst (statt
    /// nur lokal in `BambooMathGameView`), damit die Spiele-Bibliothek
    /// (`Games/Core/GameCatalog.swift`) dieselben Seiten fuer "langes
    /// Druecken zeigt die Anleitung" wiederverwenden kann, ohne die Texte
    /// doppelt zu pflegen.
    public let instructionPages: [GameInstructionPage] = [
        GameInstructionPage(
            id: 0,
            titleKey: "game.bambooMath.instruction.page1.title",
            bodyKey: "game.bambooMath.instruction.page1.body"
        ),
        GameInstructionPage(
            id: 1,
            titleKey: "game.bambooMath.instruction.page2.title",
            bodyKey: "game.bambooMath.instruction.page2.body"
        ),
        GameInstructionPage(
            id: 2,
            titleKey: "game.bambooMath.instruction.page3.title",
            bodyKey: "game.bambooMath.instruction.page3.body"
        ),
    ]

    public init() {}
}

/// Generiert eine Rechenkette Schritt fuer Schritt. Nach jedem Schritt
/// steht fest, dass das Zwischenergebnis gueltig ist (0...`numberUpperBound`,
/// bei `÷` ganzzahlig) - es wird nie nachtraeglich gerundet oder korrigiert.
///
/// Strategie je Schritt: ein zufaellig gewaehltes, fuer diese Stufe
/// erlaubtes Rechenzeichen wird bis zu `maxAttemptsPerStep`-mal versucht;
/// schlaegt ein Rechenzeichen fehl (z. B. `÷` ohne passenden Teiler), wird
/// ein anderes versucht. Gelingt in all den Versuchen keiner (bei den
/// Katalog-Obergrenzen 20/50/100 praktisch nie der Fall), greift ein
/// garantiert gueltiger Rückfall: `+1`, solange Luft nach oben ist, sonst
/// `−1`. Dieser Rückfall nutzt immer `+`/`−`, die auf jeder Stufe erlaubt
/// sind - der Generator bleibt also nie stecken.
public enum BambooMathChainGenerator {
    private static let maxAttemptsPerStep = 30

    public static func generate<RNG: RandomNumberGenerator>(
        stepCount: Int,
        parameters: BambooMathParameters,
        using rng: inout RNG
    ) -> BambooMathChain {
        precondition(stepCount > 0, "Schrittzahl muss positiv sein")
        precondition(parameters.numberUpperBound > 0, "Obergrenze muss positiv sein")
        precondition(!parameters.allowedOperators.isEmpty, "Mindestens ein Rechenzeichen nötig")

        let start = Int.random(in: 1...parameters.numberUpperBound, using: &rng)
        var current = start
        var steps: [BambooMathStep] = []
        steps.reserveCapacity(stepCount)

        for _ in 0..<stepCount {
            let step = nextStep(current: current, parameters: parameters, using: &rng)
            steps.append(step)
            current = step.result
        }
        return BambooMathChain(start: start, steps: steps)
    }

    /// Bequemlichkeits-Überladung mit der echten Systemzufallsquelle für
    /// den produktiven Einsatz (Tests nutzen die `rng:`-Variante mit einem
    /// festen Seed).
    public static func generate(stepCount: Int, parameters: BambooMathParameters) -> BambooMathChain {
        var rng = SystemRandomNumberGenerator()
        return generate(stepCount: stepCount, parameters: parameters, using: &rng)
    }

    private static func nextStep<RNG: RandomNumberGenerator>(
        current: Int,
        parameters: BambooMathParameters,
        using rng: inout RNG
    ) -> BambooMathStep {
        for _ in 0..<maxAttemptsPerStep {
            guard let operatorKind = parameters.allowedOperators.randomElement(using: &rng) else { break }
            if let step = candidateStep(
                operatorKind: operatorKind,
                current: current,
                upperBound: parameters.numberUpperBound,
                using: &rng
            ) {
                return step
            }
        }
        return fallbackStep(current: current, upperBound: parameters.numberUpperBound)
    }

    /// Versucht einen einzelnen Schritt mit dem gegebenen Rechenzeichen.
    /// Liefert `nil`, wenn dieses Rechenzeichen beim aktuellen
    /// Zwischenergebnis keinen gültigen nächsten Schritt erlaubt (z. B. `÷`
    /// ohne Teiler, oder `+`, wenn bereits an der Obergrenze).
    private static func candidateStep<RNG: RandomNumberGenerator>(
        operatorKind: BambooMathOperator,
        current: Int,
        upperBound: Int,
        using rng: inout RNG
    ) -> BambooMathStep? {
        switch operatorKind {
        case .add:
            let room = upperBound - current
            guard room >= 1 else { return nil }
            let operand = Int.random(in: 1...room, using: &rng)
            return BambooMathStep(operatorKind: .add, operand: operand, result: current + operand)

        case .subtract:
            guard current >= 1 else { return nil }
            let operand = Int.random(in: 1...current, using: &rng)
            return BambooMathStep(operatorKind: .subtract, operand: operand, result: current - operand)

        case .multiply:
            guard current >= 1 else { return nil }
            // Faktor auf 2...9 begrenzt (einstellige Zahl): haelt die
            // Multiplikation als Kopfrechenschritt machbar, statt z. B.
            // "× 37" zu erzeugen.
            let maxFactor = upperBound / current
            guard maxFactor >= 2 else { return nil }
            let factor = Int.random(in: 2...min(maxFactor, 9), using: &rng)
            return BambooMathStep(operatorKind: .multiply, operand: factor, result: current * factor)

        case .divide:
            guard current >= 2 else { return nil }
            let divisors = (2...current).filter { current % $0 == 0 }
            guard let divisor = divisors.randomElement(using: &rng) else { return nil }
            return BambooMathStep(operatorKind: .divide, operand: divisor, result: current / divisor)
        }
    }

    /// Garantiert gültiger Rückfall, siehe Dokumentation oben.
    private static func fallbackStep(current: Int, upperBound: Int) -> BambooMathStep {
        if current < upperBound {
            return BambooMathStep(operatorKind: .add, operand: 1, result: current + 1)
        } else {
            return BambooMathStep(operatorKind: .subtract, operand: 1, result: max(current - 1, 0))
        }
    }
}
