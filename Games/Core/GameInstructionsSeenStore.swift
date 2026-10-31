// GameInstructionsSeenStore.swift
// Gemeinsamer Spiel-Baukasten (MASTER-PROMPT.md, Block B3 Aufgabe 5, Gate
// "Anleitung nur beim ersten Start"): merkt sich pro Spiel, ob dessen
// Anleitung in diesem App-Lauf schon mindestens einmal gesehen oder
// übersprungen wurde.
//
// Ohne `backing` reine Prozesslaufzeit-Markierung (Vorschauen, Unit-Tests):
// bei jedem Neustart gilt jede Anleitung wieder als ungesehen. Block B4
// setzt beim App-Start `backing` auf den `PlayerStore`; dann wird jede
// Markierung zusätzlich dauerhaft gespeichert und überlebt Neustarts.
//
// `@MainActor` statt Actor/Lock: alle Zugriffe (Lesen beim Erzeugen einer
// Spiel-View, Schreiben bei "Überspringen"/letzter Anleitungsseite)
// passieren ausschließlich von der Haupt-UI aus - ein eigener Actor wäre
// hier nur zusätzliche asynchrone Umstände ohne echten Nutzen.

import Foundation

@MainActor
public enum GameInstructionsSeenStore {
    private static var seenGameIDs: Set<String> = []

    /// Dauerhafter Speicher (beim App-Start gesetzt). `nil` = nur Laufzeit.
    static var backing: PlayerStore?

    /// Ob die Anleitung für `gameID` in diesem App-Lauf schon mindestens
    /// einmal gesehen oder übersprungen wurde.
    public static func hasSeenInstructions(gameID: String) -> Bool {
        seenGameIDs.contains(gameID) || (backing?.instructionsSeen(gameID: gameID) ?? false)
    }

    /// Markiert die Anleitung für `gameID` als gesehen.
    public static func markSeen(gameID: String) {
        seenGameIDs.insert(gameID)
        backing?.markInstructionsSeen(gameID: gameID)
    }
}
