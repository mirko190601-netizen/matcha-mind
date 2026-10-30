// PuzzleSolvable.swift
// Gemeinsamer Spiel-Baukasten (MASTER-PROMPT.md, Block B3 Aufgabe 1,
// Punkt 7 - "Raetsel-Loeser-Pflicht"): jeder Raetsel-Generator (Mosaik-
// Beet, Meister-Mosaik, Gaertner-Muster, ... - kommen in P2/P3) muss ein
// Raetsel erst generieren und dann ueber dieses Protokoll pruefen, ob es
// genau eine Loesung hat. Nur dann wird es angezeigt, sonst neu generiert.

/// Ein generiertes Raetsel, das seine eigene Lösungsanzahl kennt.
public protocol PuzzleSolvable {
    /// Anzahl gueltiger Loesungen dieses Raetsels. Der konkrete
    /// Raetsel-Generator implementiert hier seinen eigenen Loeser.
    func solutionCount() -> Int
}

/// Generiert Raetsel, bis eines mit genau einer Loesung entsteht
/// (`solutionCount() == 1`), oder gibt nach `maxAttempts` erfolglosen
/// Versuchen `nil` zurueck, statt endlos weiterzuversuchen.
public func generateUnique<P: PuzzleSolvable>(
    maxAttempts: Int,
    generator: () -> P
) -> P? {
    for _ in 0..<maxAttempts {
        let candidate = generator()
        if candidate.solutionCount() == 1 {
            return candidate
        }
    }
    return nil
}
