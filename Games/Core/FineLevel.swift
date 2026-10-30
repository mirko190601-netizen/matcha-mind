// FineLevel.swift
// Gemeinsamer Spiel-Baukasten (MASTER-PROMPT.md, Block B3 Aufgabe 1):
// Feinstufen-Logik innerhalb einer Tee-Stufe. Nach 3 aufeinanderfolgenden
// Erfolgen wird eine Feinstufe schwerer, nach 2 aufeinanderfolgenden
// Fehlversuchen eine leichter - jeweils begrenzt durch eine Unter- und
// Obergrenze, die das jeweilige Spiel vorgibt.
//
// Reine Logik-Klasse, bewusst ohne Persistenz: der Zustand lebt nur im
// Arbeitsspeicher und geht beim Neustart der App verloren. Die Anbindung
// an echte Persistenz (SwiftData, pro Spiel-ID gespeichert) folgt erst in
// Block B4.

import Foundation

/// Feinstufen-Tracker fuer genau ein Spiel. Jedes Spiel haelt seine
/// eigene Instanz (Schluessel: `GameDefinition.id`).
public final class FineLevelTracker {
    public let lowerBound: Int
    public let upperBound: Int
    public private(set) var fineLevel: Int

    private var consecutiveSuccesses = 0
    private var consecutiveFailures = 0

    /// - Parameters:
    ///   - lowerBound: niedrigste erlaubte Feinstufe. Standard 1.
    ///   - upperBound: hoechste erlaubte Feinstufe, vom Spiel vorgegeben.
    ///   - startLevel: Startwert; wird auf `[lowerBound, upperBound]`
    ///     begrenzt. Standard `lowerBound`.
    public init(lowerBound: Int = 1, upperBound: Int, startLevel: Int? = nil) {
        precondition(lowerBound <= upperBound, "lowerBound darf nicht größer als upperBound sein")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.fineLevel = min(max(startLevel ?? lowerBound, lowerBound), upperBound)
    }

    /// Erfolg vermerken. Nach dem dritten Erfolg in Folge steigt die
    /// Feinstufe um 1 (begrenzt durch `upperBound`), danach beginnt die
    /// Zaehlung neu.
    public func recordSuccess() {
        consecutiveFailures = 0
        consecutiveSuccesses += 1
        guard consecutiveSuccesses >= 3 else { return }
        consecutiveSuccesses = 0
        fineLevel = min(fineLevel + 1, upperBound)
    }

    /// Fehlversuch vermerken. Nach dem zweiten Fehlversuch in Folge
    /// sinkt die Feinstufe um 1 (begrenzt durch `lowerBound`), danach
    /// beginnt die Zaehlung neu.
    public func recordFailure() {
        consecutiveSuccesses = 0
        consecutiveFailures += 1
        guard consecutiveFailures >= 2 else { return }
        consecutiveFailures = 0
        fineLevel = max(fineLevel - 1, lowerBound)
    }
}
