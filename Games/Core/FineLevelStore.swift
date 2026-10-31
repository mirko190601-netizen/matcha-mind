// FineLevelStore.swift
// Spielerdaten (MASTER-PROMPT.md, Block B4 Aufgabe 1): reicht die Feinstufe
// je Spiel an den `PlayerStore` durch, damit sie App-Neustarts uebersteht.
// Analog zu `GameInstructionsSeenStore` bleibt die Aufruf-Schnittstelle
// statisch; `backing` wird beim App-Start gesetzt. Ohne `backing` (z. B. in
// Vorschauen und Unit-Tests) wird nichts gemerkt, `startLevel` liefert
// `nil` und `FineLevelTracker` beginnt wie bisher bei seiner Untergrenze.

import Foundation

@MainActor
enum FineLevelStore {
    static var backing: PlayerStore?

    /// Gespeicherte Feinstufe fuer `gameID`, `nil` wenn noch keine vorliegt.
    static func startLevel(gameID: String) -> Int? {
        backing?.fineLevel(gameID: gameID)
    }

    /// Speichert die aktuelle Feinstufe fuer `gameID`.
    static func save(gameID: String, level: Int) {
        backing?.saveFineLevel(gameID: gameID, level: level)
    }
}
