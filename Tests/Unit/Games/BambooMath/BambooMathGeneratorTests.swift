import XCTest
@testable import MatchaMind

/// Prüft `BambooMathChainGenerator` und die Katalog-Parameter von
/// `BambooMathGame` (`Games/BambooMath/BambooMathGame.swift`,
/// MASTER-PROMPT.md Block B3 Aufgabe 2, Abschnitt 6 Zeile 5): je Stufe
/// stimmen Schrittzahl, Zahlen-Obergrenze und erlaubte Rechenzeichen mit
/// dem Katalog überein, jedes Zwischenergebnis bleibt im gültigen Bereich
/// (nie negativ, nie über der Obergrenze), und `÷`-Schritte liefern immer
/// ein ganzzahliges Ergebnis - nie gerundet.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class BambooMathGeneratorTests: XCTestCase {
    private let game = BambooMathGame()

    /// Einfacher, deterministischer Zufallszahlengenerator für
    /// reproduzierbare Testläufe (kein kryptographischer Anspruch) - wie in
    /// `TeapotRowGeneratorTests`.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0xdead_beef : seed
        }

        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    // MARK: - Katalog-Parameter je Stufe

    func testSenchaParametersMatchCatalog() {
        guard let parameters = game.parameters[.sencha] else {
            return XCTFail("Keine Parameter für Sencha")
        }
        XCTAssertEqual(parameters.stepCountRange, 3...3)
        XCTAssertEqual(parameters.numberUpperBound, 20)
        XCTAssertEqual(Set(parameters.allowedOperators), [.add, .subtract])
    }

    func testOolongParametersMatchCatalog() {
        guard let parameters = game.parameters[.oolong] else {
            return XCTFail("Keine Parameter für Oolong")
        }
        XCTAssertEqual(parameters.stepCountRange, 4...5)
        XCTAssertEqual(parameters.numberUpperBound, 50)
        XCTAssertEqual(Set(parameters.allowedOperators), [.add, .subtract, .multiply])
    }

    func testMatchaParametersMatchCatalog() {
        guard let parameters = game.parameters[.matcha] else {
            return XCTFail("Keine Parameter für Matcha")
        }
        XCTAssertEqual(parameters.stepCountRange, 6...6)
        XCTAssertEqual(parameters.numberUpperBound, 100)
        XCTAssertEqual(Set(parameters.allowedOperators), [.add, .subtract, .multiply, .divide])
    }

    // MARK: - Wertebereich über viele Generierungen

    func testSenchaChainsStayWithinBounds() {
        assertChainsStayWithinBounds(for: .sencha, iterations: 500, seed: 1)
    }

    func testOolongChainsStayWithinBounds() {
        assertChainsStayWithinBounds(for: .oolong, iterations: 500, seed: 2)
    }

    func testMatchaChainsStayWithinBounds() {
        assertChainsStayWithinBounds(for: .matcha, iterations: 500, seed: 3)
    }

    /// Erzeugt `iterations` Ketten für `level` (mit beiden Enden des
    /// Schrittzahl-Bereichs) und prüft, dass Start-Zahl und jedes
    /// Zwischenergebnis in `0...numberUpperBound` liegen und die
    /// Schrittzahl stimmt.
    private func assertChainsStayWithinBounds(for level: TeaLevel, iterations: Int, seed: UInt64) {
        guard let parameters = game.parameters[level] else {
            return XCTFail("Keine Parameter für \(level)")
        }
        var rng = SeededGenerator(seed: seed)

        for stepCount in [parameters.stepCountRange.lowerBound, parameters.stepCountRange.upperBound] {
            for _ in 0..<iterations {
                let chain = BambooMathChainGenerator.generate(stepCount: stepCount, parameters: parameters, using: &rng)

                XCTAssertEqual(chain.steps.count, stepCount, "Schrittzahl muss \(stepCount) sein (\(level))")
                XCTAssertTrue(
                    (0...parameters.numberUpperBound).contains(chain.start),
                    "Start \(chain.start) außerhalb 0...\(parameters.numberUpperBound) (\(level))"
                )
                for step in chain.steps {
                    XCTAssertTrue(
                        (0...parameters.numberUpperBound).contains(step.result),
                        "Zwischenergebnis \(step.result) außerhalb 0...\(parameters.numberUpperBound) (\(level))"
                    )
                }
            }
        }
    }

    // MARK: - Ganzzahligkeit bei Division (nur Matcha)

    func testMatchaDivisionStepsAlwaysProduceIntegerResults() {
        guard let parameters = game.parameters[.matcha] else {
            return XCTFail("Keine Parameter für Matcha")
        }
        var rng = SeededGenerator(seed: 4)

        var sawAtLeastOneDivision = false
        for _ in 0..<1000 {
            let chain = BambooMathChainGenerator.generate(
                stepCount: parameters.stepCountRange.upperBound,
                parameters: parameters,
                using: &rng
            )
            var valueBeforeStep = chain.start
            for step in chain.steps {
                if step.operatorKind == .divide {
                    sawAtLeastOneDivision = true
                    XCTAssertEqual(
                        valueBeforeStep % step.operand,
                        0,
                        "÷-Schritt \(valueBeforeStep) ÷ \(step.operand) muss ganzzahlig sein"
                    )
                    XCTAssertEqual(step.result * step.operand, valueBeforeStep, "Division darf nicht gerundet werden")
                }
                valueBeforeStep = step.result
            }
        }
        XCTAssertTrue(sawAtLeastOneDivision, "Über 1000 Matcha-Ketten sollte mindestens eine Division vorkommen")
    }

    func testSenchaAndOolongNeverDivide() {
        var rng = SeededGenerator(seed: 5)
        for level in [TeaLevel.sencha, .oolong] {
            guard let parameters = game.parameters[level] else {
                XCTFail("Keine Parameter für \(level)")
                continue
            }
            for _ in 0..<200 {
                let chain = BambooMathChainGenerator.generate(
                    stepCount: parameters.stepCountRange.upperBound,
                    parameters: parameters,
                    using: &rng
                )
                XCTAssertFalse(
                    chain.steps.contains { $0.operatorKind == .divide },
                    "\(level) darf laut Katalog kein ÷ enthalten"
                )
            }
        }
    }

    func testOolongNeverDividesButMayMultiply() {
        guard let parameters = game.parameters[.oolong] else {
            return XCTFail("Keine Parameter für Oolong")
        }
        var rng = SeededGenerator(seed: 6)
        var sawAtLeastOneMultiplication = false
        for _ in 0..<500 {
            let chain = BambooMathChainGenerator.generate(
                stepCount: parameters.stepCountRange.upperBound,
                parameters: parameters,
                using: &rng
            )
            if chain.steps.contains(where: { $0.operatorKind == .multiply }) {
                sawAtLeastOneMultiplication = true
            }
        }
        XCTAssertTrue(sawAtLeastOneMultiplication, "Über 500 Oolong-Ketten sollte mindestens eine Multiplikation vorkommen")
    }

    // MARK: - Darstellung

    func testFinalResultEqualsLastStepResult() {
        let chain = BambooMathChain(
            start: 12,
            steps: [
                BambooMathStep(operatorKind: .add, operand: 5, result: 17),
                BambooMathStep(operatorKind: .subtract, operand: 3, result: 14),
            ]
        )
        XCTAssertEqual(chain.finalResult, 14)
    }

    func testDisplayExpressionFormatsChainWithSymbols() {
        let chain = BambooMathChain(
            start: 12,
            steps: [
                BambooMathStep(operatorKind: .add, operand: 5, result: 17),
                BambooMathStep(operatorKind: .subtract, operand: 3, result: 14),
            ]
        )
        XCTAssertEqual(chain.displayExpression, "12 + 5 − 3")
    }
}
