import XCTest
@testable import MatchaMind

/// Pflicht-Test aus MASTER-PROMPT.md Block B3 Gate: "Mosaik-Rätsel immer
/// genau eine Lösung (Test über 1.000 Generierungen je Stufe)". Für jede
/// der 3 Stufen werden 1.000 Rätsel erzeugt und jedes Mal
/// `solutionCount() == 1` geprüft - mit `capAt: 2` im Löser
/// (`MosaicBedSolver.countSolutions`) bricht die Zählung früh ab, sodass
/// 1.000 Durchläufe je Stufe performant bleiben.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class MosaicBedUniquenessTests: XCTestCase {
    private let game = MosaicBedGame()
    private let generationsPerLevel = 1000

    /// Einfacher, deterministischer Zufallszahlengenerator für
    /// reproduzierbare Testläufe (kein kryptographischer Anspruch).
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

    func testSenchaPuzzlesAlwaysHaveExactlyOneSolution() {
        assertAllGeneratedPuzzlesAreUnique(for: .sencha, seed: 1)
    }

    func testOolongPuzzlesAlwaysHaveExactlyOneSolution() {
        assertAllGeneratedPuzzlesAreUnique(for: .oolong, seed: 2)
    }

    func testMatchaPuzzlesAlwaysHaveExactlyOneSolution() {
        assertAllGeneratedPuzzlesAreUnique(for: .matcha, seed: 3)
    }

    private func assertAllGeneratedPuzzlesAreUnique(for level: TeaLevel, seed: UInt64) {
        guard let parameters = game.parameters[level] else {
            XCTFail("Keine Parameter für \(level)")
            return
        }
        var rng = SeededGenerator(seed: seed)

        for attempt in 0..<generationsPerLevel {
            guard let puzzle = MosaicBedGenerator.generateUniquePuzzle(parameters: parameters, using: &rng) else {
                XCTFail("Generierung Nr. \(attempt) für \(level) lieferte kein Rätsel")
                continue
            }
            XCTAssertEqual(
                puzzle.solutionCount(),
                1,
                "Rätsel Nr. \(attempt) für \(level) hat nicht genau 1 Lösung"
            )
        }
    }
}
