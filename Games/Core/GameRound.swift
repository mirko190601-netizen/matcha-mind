// GameRound.swift
// Rundendauer der Spiele an einer Stelle. Im Release immer 75 Sekunden. In
// DEBUG-Builds kann ein UI-Test sie verkuerzen (`LaunchConfiguration`,
// Argument fuer die Rundensekunden), damit die Gate-Laeufe in der CI kurz bleiben.

import Foundation

enum GameRound {
    /// Zielspieldauer einer Runde in Sekunden.
    static let standardDuration: TimeInterval = 75

    #if DEBUG
    /// Nur DEBUG: verkuerzte Rundendauer, einmal beim App-Start gesetzt.
    nonisolated(unsafe) static var overrideSeconds: TimeInterval?
    #endif

    /// Aktuelle Rundendauer (Release: immer `standardDuration`).
    static var duration: TimeInterval {
        #if DEBUG
        if let overrideSeconds, overrideSeconds > 0 { return overrideSeconds }
        #endif
        return standardDuration
    }

    /// Verhaeltnis zur Standarddauer, fuer Spiele mit fester Anzahl Schritte
    /// (Gluehwuermchen): deren Taktzeiten werden damit gleich gestaucht.
    static var timeScale: Double { duration / standardDuration }
}
