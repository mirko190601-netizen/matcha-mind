import XCTest
@testable import MatchaMind

/// Prüft `MosaicBedSolver`/`MosaicBedGenerator` unabhängig vom
/// Eindeutigkeits-Pflichttest (`MosaicBedUniquenessTests.swift`): Katalog-
/// Parameter je Stufe (MASTER-PROMPT.md Abschnitt 6, Zeile 3), die
/// Grundform des erzeugten Rätsels (Rastergröße, Zeilen-/Spalten-Regel,
/// Nachbar-Verbote) und dass der Löser offensichtlich ungültige Gitter
/// ablehnt.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class MosaicBedGeneratorTests: XCTestCase {
    private let game = MosaicBedGame()

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

    func testSenchaUsesFourByFourGridWithNoAdjacencyBans() {
        XCTAssertEqual(game.parameters[.sencha]?.gridSize, 4)
        XCTAssertEqual(game.parameters[.sencha]?.forbiddenAdjacentPairs.count, 0)
        XCTAssertEqual(game.parameters[.sencha]?.hintAvailable, true)
    }

    func testOolongUsesFiveByFiveGridWithOneAdjacencyBan() {
        XCTAssertEqual(game.parameters[.oolong]?.gridSize, 5)
        XCTAssertEqual(game.parameters[.oolong]?.forbiddenAdjacentPairs.count, 1)
        XCTAssertEqual(game.parameters[.oolong]?.hintAvailable, false)
    }

    func testMatchaUsesSixBySixGridWithTwoAdjacencyBans() {
        XCTAssertEqual(game.parameters[.matcha]?.gridSize, 6)
        XCTAssertEqual(game.parameters[.matcha]?.forbiddenAdjacentPairs.count, 2)
        XCTAssertEqual(game.parameters[.matcha]?.hintAvailable, false)
    }

    func testGeneratedPuzzleSolutionSatisfiesRowAndColumnRule() {
        guard let parameters = game.parameters[.oolong] else {
            XCTFail("Keine Parameter für Oolong")
            return
        }
        var rng = SeededGenerator(seed: 11)
        let puzzle = MosaicBedGenerator.generate(parameters: parameters, using: &rng)

        for row in puzzle.solution {
            XCTAssertEqual(Set(row).count, puzzle.gridSize, "Jede Reihe muss jede Pflanzenart genau einmal enthalten")
        }
        for col in 0..<puzzle.gridSize {
            let column = puzzle.solution.map { $0[col] }
            XCTAssertEqual(Set(column).count, puzzle.gridSize, "Jede Spalte muss jede Pflanzenart genau einmal enthalten")
        }
    }

    func testGeneratedPuzzleSolutionRespectsAdjacencyBans() {
        guard let parameters = game.parameters[.matcha] else {
            XCTFail("Keine Parameter für Matcha")
            return
        }
        var rng = SeededGenerator(seed: 12)
        let puzzle = MosaicBedGenerator.generate(parameters: parameters, using: &rng)

        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                let current = puzzle.solution[row][col]
                if row > 0 {
                    let up = puzzle.solution[row - 1][col]
                    XCTAssertFalse(parameters.forbiddenAdjacentPairs.contains { $0.forbids(up, current) })
                }
                if col > 0 {
                    let left = puzzle.solution[row][col - 1]
                    XCTAssertFalse(parameters.forbiddenAdjacentPairs.contains { $0.forbids(left, current) })
                }
            }
        }
    }

    func testGeneratedPuzzleLeavesAtLeastOneCellEmpty() {
        guard let parameters = game.parameters[.sencha] else {
            XCTFail("Keine Parameter für Sencha")
            return
        }
        var rng = SeededGenerator(seed: 13)
        let puzzle = MosaicBedGenerator.generate(parameters: parameters, using: &rng)
        let emptyCount = puzzle.givens.flatMap { $0 }.filter { $0 == nil }.count
        XCTAssertGreaterThan(emptyCount, 0, "Ein vollständig vorbelegtes Rätsel wäre kein Rätsel")
    }

    func testSolverRejectsGridWithDuplicateInRow() {
        // 2x2-Spielzeug-Fall mit offensichtlich ungültiger Vorbelegung:
        // beide Felder der ersten Reihe fest auf dieselbe Art gesetzt -
        // das kann die Zeilen-Regel nie erfüllen, also 0 Lösungen.
        let plantTypes: [MosaicPlantType] = [.leaf, .drop]
        let givens: [[MosaicPlantType?]] = [
            [.leaf, .leaf],
            [nil, nil],
        ]
        let count = MosaicBedSolver.countSolutions(
            gridSize: 2,
            plantTypes: plantTypes,
            forbiddenAdjacentPairs: [],
            givens: givens,
            capAt: 2
        )
        XCTAssertEqual(count, 0)
    }

    func testSolverFindsExactlyOneSolutionForFullyGivenValidGrid() {
        let plantTypes: [MosaicPlantType] = [.leaf, .drop]
        let givens: [[MosaicPlantType?]] = [
            [.leaf, .drop],
            [.drop, .leaf],
        ]
        let count = MosaicBedSolver.countSolutions(
            gridSize: 2,
            plantTypes: plantTypes,
            forbiddenAdjacentPairs: [],
            givens: givens,
            capAt: 2
        )
        XCTAssertEqual(count, 1)
    }
}
