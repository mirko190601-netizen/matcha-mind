// MosaicBedSolver.swift
// Löser für "Das Mosaik-Beet" (MASTER-PROMPT.md, Block B3 Aufgabe 1 Punkt 7
// und Aufgabe 2/5): Backtracking-Löser, der prüft, ob ein gegebenes Gitter
// (vollständig oder teilweise mit `givens` vorbelegt) die Regeln aus
// `MosaicBedGame.swift` erfüllen kann, und zählt gültige Belegungen -
// bricht ab `capAt` Lösungen früh ab (für `solutionCount() == 1` muss
// nicht gezählt werden, ob es 2 oder 2.000.000 Lösungen gibt).

import Foundation

/// Ein generiertes Mosaik-Beet-Rätsel: feste Vorgaben (`givens`, `nil` =
/// vom Spieler auszufüllen) plus die vollständige Lösung (für den
/// Hinweis-Button und zur Erfolgsprüfung während des Spiels).
public struct MosaicBedPuzzle: Sendable {
    public let gridSize: Int
    public let plantTypes: [MosaicPlantType]
    public let forbiddenAdjacentPairs: [MosaicAdjacencyBan]
    public let givens: [[MosaicPlantType?]]
    public let solution: [[MosaicPlantType]]

    public init(
        gridSize: Int,
        plantTypes: [MosaicPlantType],
        forbiddenAdjacentPairs: [MosaicAdjacencyBan],
        givens: [[MosaicPlantType?]],
        solution: [[MosaicPlantType]]
    ) {
        self.gridSize = gridSize
        self.plantTypes = plantTypes
        self.forbiddenAdjacentPairs = forbiddenAdjacentPairs
        self.givens = givens
        self.solution = solution
    }
}

extension MosaicBedPuzzle: PuzzleSolvable {
    /// Zählt gültige Belegungen dieses Rätsels (ausgehend von `givens`),
    /// bricht ab 2 Lösungen früh ab - für die Eindeutigkeitsprüfung reicht
    /// "genau 1", siehe `MosaicBedGenerator`.
    public func solutionCount() -> Int {
        MosaicBedSolver.countSolutions(
            gridSize: gridSize,
            plantTypes: plantTypes,
            forbiddenAdjacentPairs: forbiddenAdjacentPairs,
            givens: givens,
            capAt: 2
        )
    }
}

/// Reiner Backtracking-Löser für das Mosaik-Beet-Regel-Set (Zeilen-Regel,
/// Spalten-Regel, bis zu 2 Nachbar-Verbote - siehe `MosaicBedGame.swift`).
public enum MosaicBedSolver {
    /// Zählt gültige Belegungen des Gitters, Zellen für Zellen in
    /// Lesereihenfolge (Zeile für Zeile) aufgefüllt; vorbelegte Zellen
    /// (`givens`) werden übersprungen, leere (`nil`) werden mit jeder
    /// laut `plantTypes` erlaubten Art durchprobiert.
    public static func countSolutions(
        gridSize: Int,
        plantTypes: [MosaicPlantType],
        forbiddenAdjacentPairs: [MosaicAdjacencyBan],
        givens: [[MosaicPlantType?]],
        capAt: Int
    ) -> Int {
        var grid = givens
        var count = 0

        func isValid(_ type: MosaicPlantType, row: Int, col: Int) -> Bool {
            for c in 0..<gridSize where grid[row][c] == type { return false }
            for r in 0..<gridSize where grid[r][col] == type { return false }
            if row > 0, let up = grid[row - 1][col], forbiddenAdjacentPairs.contains(where: { $0.forbids(up, type) }) {
                return false
            }
            if col > 0, let left = grid[row][col - 1],
               forbiddenAdjacentPairs.contains(where: { $0.forbids(left, type) }) {
                return false
            }
            return true
        }

        func backtrack(_ index: Int) {
            guard count < capAt else { return }
            guard index < gridSize * gridSize else {
                count += 1
                return
            }
            let row = index / gridSize
            let col = index % gridSize

            if grid[row][col] != nil {
                backtrack(index + 1)
                return
            }

            for type in plantTypes {
                guard count < capAt else { return }
                guard isValid(type, row: row, col: col) else { continue }
                grid[row][col] = type
                backtrack(index + 1)
                grid[row][col] = nil
            }
        }

        backtrack(0)
        return count
    }
}
