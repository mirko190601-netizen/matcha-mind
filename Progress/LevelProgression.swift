// LevelProgression.swift
// Globale Stufe (MASTER-PROMPT.md, Block B4 Aufgabe 2): reine Aufstiegs-Logik.
// Bewusst nur Foundation, ohne SwiftUI/SwiftData - spaeter in ein eigenes
// Paket (`MatchaCore`) auslagerbar.
//
// Regel: Sencha -> Oolong nach mindestens 14 aktiven Tagen seit Stufenbeginn,
// Oolong -> Matcha nach mindestens 21 weiteren, jeweils nur wenn die
// Genauigkeit der letzten 7 aktiven Tage mindestens 75 % betraegt und der
// Auto-Aufstieg eingeschaltet ist. Ein "aktiver Tag" ist ein Tag mit
// erledigter Teepause.

import Foundation

/// Treffer und Fehler aller Spiele eines aktiven Tages.
struct ActiveDaySummary: Equatable, Sendable {
    let dayKey: String
    let hits: Int
    let misses: Int
}

enum LevelProgression {
    /// Aktive Tage seit Stufenbeginn bis zum Angebot Sencha -> Oolong.
    static let senchaToOolongActiveDays = 14
    /// Aktive Tage seit Stufenbeginn bis zum Angebot Oolong -> Matcha.
    static let oolongToMatchaActiveDays = 21
    /// Aktive Tage auf einer manuell gesenkten Stufe bis zum naechsten Angebot.
    static let reentryActiveDays = 14
    /// Mindest-Genauigkeit in Prozent.
    static let requiredAccuracyPercent = 75
    /// Anzahl der aktiven Tage, ueber die die Genauigkeit gemittelt wird.
    static let accuracyWindowDays = 7

    /// Ob die Genauigkeit der letzten `accuracyWindowDays` aktiven Tage die
    /// Schwelle erreicht. Ganzzahl-Vergleich `100 * T >= 75 * (T + F)`
    /// (kein Gleitkomma). Ohne Versuche: `false`.
    static func accuracyMeetsThreshold(lastActiveDays: [ActiveDaySummary]) -> Bool {
        let window = lastActiveDays
            .sorted { $0.dayKey < $1.dayKey }
            .suffix(accuracyWindowDays)
        let hits = window.reduce(0) { $0 + $1.hits }
        let misses = window.reduce(0) { $0 + $1.misses }
        guard hits + misses > 0 else { return false }
        return 100 * hits >= requiredAccuracyPercent * (hits + misses)
    }

    /// Stufe, auf die aktuell aufgestiegen werden kann, sonst `nil`.
    /// - Parameters:
    ///   - activeDaysAtCurrentLevel: aktive Tage seit Beginn der aktuellen Stufe.
    ///   - lastSevenActiveDays: Treffer/Fehler der letzten aktiven Tage.
    ///   - deferredUntilActiveDays: gesetzt, wenn der Spieler "Lieber noch
    ///     bleiben" gewaehlt hat; bis diese Zahl aktiver Tage erreicht ist,
    ///     gibt es kein neues Angebot.
    ///   - loweredManually: aktuelle Stufe wurde manuell gesenkt; dann gilt
    ///     `reentryActiveDays` statt der regulaeren Tageszahl.
    static func promotionTarget(
        currentLevel: TeaLevel,
        autoAdvance: Bool,
        activeDaysAtCurrentLevel: Int,
        lastSevenActiveDays: [ActiveDaySummary],
        deferredUntilActiveDays: Int?,
        loweredManually: Bool = false
    ) -> TeaLevel? {
        guard autoAdvance else { return nil }
        if let deferredUntilActiveDays, activeDaysAtCurrentLevel < deferredUntilActiveDays {
            return nil
        }

        let requiredDays: Int
        let target: TeaLevel
        switch currentLevel {
        case .sencha:
            requiredDays = senchaToOolongActiveDays
            target = .oolong
        case .oolong:
            requiredDays = oolongToMatchaActiveDays
            target = .matcha
        case .matcha:
            return nil
        }

        let days = loweredManually ? reentryActiveDays : requiredDays
        guard activeDaysAtCurrentLevel >= days else { return nil }
        guard accuracyMeetsThreshold(lastActiveDays: lastSevenActiveDays) else { return nil }
        return target
    }
}
