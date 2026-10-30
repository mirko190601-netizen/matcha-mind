// MosaicBedGenerator.swift
// Generator für "Das Mosaik-Beet" (MASTER-PROMPT.md, Block B3 Aufgabe 1
// Punkt 7 - "Rätsel-Generatoren mit Löser" - und die harte Gate-Anforderung
// "Mosaik-Rätsel immer genau eine Lösung").
//
// Klassisches "unique puzzle generation"-Muster (siehe Auftrag):
//   1. Eine vollständige, gültige Lösung zufällig erzeugen
//      (`generateSolution`: randomisiertes Backtracking über die Regeln
//      aus `MosaicBedGame.swift`).
//   2. Felder schrittweise in zufälliger Reihenfolge leeren; nach jedem
//      Leeren mit `MosaicBedSolver` prüfen, ob weiterhin genau 1 Lösung
//      existiert - wenn nicht, die Vorgabe wieder einsetzen (`generate`).
//   3. Zur Sicherheit nutzt `generateUniquePuzzle` zusätzlich
//      `generateUnique` aus `Games/Core/PuzzleSolvable.swift` und prüft
//      `solutionCount() == 1`, bevor ein Rätsel zurückgegeben wird - genau
//      das verlangt die Gate-Anforderung.

import Foundation

public enum MosaicBedGenerator {
    /// Erzeugt eine zufällige, vollständige Belegung, die alle Regeln
    /// dieser Stufe erfüllt. Nutzt echtes Backtracking (nicht nur
    /// gierig-zufällig), damit eine Lösung garantiert gefunden wird, falls
    /// die Regel-Kombination überhaupt lösbar ist (das Regel-Set in
    /// `MosaicBedGame.swift` ist so gewählt, dass das immer der Fall ist).
    static func generateSolution<RNG: RandomNumberGenerator>(
        gridSize: Int,
        plantTypes: [MosaicPlantType],
        forbiddenAdjacentPairs: [MosaicAdjacencyBan],
        using rng: inout RNG
    ) -> [[MosaicPlantType]] {
        var grid: [[MosaicPlantType?]] = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)

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

        @discardableResult
        func backtrack(_ index: Int) -> Bool {
            guard index < gridSize * gridSize else { return true }
            let row = index / gridSize
            let col = index % gridSize

            for type in plantTypes.shuffled(using: &rng) {
                guard isValid(type, row: row, col: col) else { continue }
                grid[row][col] = type
                if backtrack(index + 1) { return true }
                grid[row][col] = nil
            }
            return false
        }

        let found = backtrack(0)
        precondition(found, "Keine gültige Mosaik-Beet-Belegung für dieses Regel-Set gefunden")
        return grid.map { row in row.map { $0! } }
    }

    /// Baut ein Rätsel: volle Lösung erzeugen, dann möglichst viele Felder
    /// in zufälliger Reihenfolge leeren, solange danach weiterhin genau 1
    /// Lösung existiert (siehe Datei-Kommentar, Schritt 2).
    public static func generate<RNG: RandomNumberGenerator>(
        parameters: MosaicBedParameters,
        using rng: inout RNG
    ) -> MosaicBedPuzzle {
        let gridSize = parameters.gridSize
        let plantTypes = parameters.plantTypes
        let solution = generateSolution(
            gridSize: gridSize,
            plantTypes: plantTypes,
            forbiddenAdjacentPairs: parameters.forbiddenAdjacentPairs,
            using: &rng
        )

        var givens: [[MosaicPlantType?]] = solution.map { row in row.map { Optional($0) } }
        var cellOrder = (0..<(gridSize * gridSize)).map { ($0 / gridSize, $0 % gridSize) }
        cellOrder.shuffle(using: &rng)

        for (row, col) in cellOrder {
            let backup = givens[row][col]
            givens[row][col] = nil
            let solutionCount = MosaicBedSolver.countSolutions(
                gridSize: gridSize,
                plantTypes: plantTypes,
                forbiddenAdjacentPairs: parameters.forbiddenAdjacentPairs,
                givens: givens,
                capAt: 2
            )
            if solutionCount != 1 {
                givens[row][col] = backup
            }
        }

        return MosaicBedPuzzle(
            gridSize: gridSize,
            plantTypes: plantTypes,
            forbiddenAdjacentPairs: parameters.forbiddenAdjacentPairs,
            givens: givens,
            solution: solution
        )
    }

    /// Öffentliche Einstiegsstelle: generiert ein Rätsel und stellt über
    /// `generateUnique` (`Games/Core/PuzzleSolvable.swift`) sicher, dass
    /// nur eines mit `solutionCount() == 1` zurückgegeben wird (Gate-
    /// Anforderung). `generate` hält diese Eigenschaft bereits durch
    /// Konstruktion ein; `generateUnique` ist die zusätzliche Absicherung
    /// und wiederholt im seltenen Fehlerfall bis zu `maxAttempts`-mal.
    public static func generateUniquePuzzle<RNG: RandomNumberGenerator>(
        parameters: MosaicBedParameters,
        maxAttempts: Int = 20,
        using rng: inout RNG
    ) -> MosaicBedPuzzle? {
        generateUnique(maxAttempts: maxAttempts) {
            generate(parameters: parameters, using: &rng)
        }
    }

    /// Bequemlichkeits-Überladung mit der echten Systemzufallsquelle für
    /// den produktiven Einsatz (Tests nutzen die `rng:`-Variante mit einem
    /// festen Seed).
    public static func generateUniquePuzzle(parameters: MosaicBedParameters) -> MosaicBedPuzzle? {
        var rng = SystemRandomNumberGenerator()
        return generateUniquePuzzle(parameters: parameters, using: &rng)
    }
}
