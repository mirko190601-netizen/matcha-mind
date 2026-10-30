// GameInstructionsSeenStore.swift
// Gemeinsamer Spiel-Baukasten (MASTER-PROMPT.md, Block B3 Aufgabe 5, Gate
// "Anleitung nur beim ersten Start"): merkt sich pro Spiel, ob dessen
// Anleitung in diesem App-Lauf schon mindestens einmal gesehen oder
// übersprungen wurde.
//
// Reine Prozesslaufzeit-Markierung, bewusst OHNE Persistenz (kein
// SwiftData/UserDefaults, siehe `FineLevel.swift` für dieselbe
// Dokumentations-Konvention bei bewusst fehlender Persistenz): bei jedem
// App-Neustart gilt jede Anleitung wieder als ungesehen. Echte, über
// Neustarts hinweg gültige Persistenz folgt erst in Block B4.
//
// `@MainActor` statt Actor/Lock: alle Zugriffe (Lesen beim Erzeugen einer
// Spiel-View, Schreiben bei "Überspringen"/letzter Anleitungsseite)
// passieren ausschließlich von der Haupt-UI aus - ein eigener Actor wäre
// hier nur zusätzliche asynchrone Umstände ohne echten Nutzen.

import Foundation

@MainActor
public enum GameInstructionsSeenStore {
    private static var seenGameIDs: Set<String> = []

    /// Ob die Anleitung für `gameID` in diesem App-Lauf schon mindestens
    /// einmal gesehen oder übersprungen wurde.
    public static func hasSeenInstructions(gameID: String) -> Bool {
        seenGameIDs.contains(gameID)
    }

    /// Markiert die Anleitung für `gameID` als gesehen.
    public static func markSeen(gameID: String) {
        seenGameIDs.insert(gameID)
    }
}
