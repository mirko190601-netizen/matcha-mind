// PlayerData.swift
// Spielerdaten (MASTER-PROMPT.md, Block B4 Aufgabe 1): SwiftData-Modelle.
// Geschrieben wird ausschliesslich ueber `PlayerStore`.
//
// Stufen werden als `Int` (`TeaLevel.rawValue`) gespeichert, nicht als
// Enum, damit das Schema unabhaengig von spaeteren Enum-Erweiterungen
// bleibt.

import Foundation
import SwiftData

/// Genau ein Eintrag pro Installation: Stufe, Einstellungen, Tautropfen.
@Model
final class PlayerProfile {
    var levelRaw: Int
    var autoAdvance: Bool = true
    /// Tagesschluessel, an dem die aktuelle Stufe begann.
    var levelSinceDayKey: String
    /// Hoechste je erreichte Stufe (bestimmt die geoeffneten Gartenbereiche).
    var highestLevelRaw: Int
    /// Nach "Lieber noch bleiben": kein neues Angebot, bis so viele aktive
    /// Tage seit Stufenbeginn erreicht sind.
    var promotionDeferredUntilActiveDays: Int?
    /// Aktuelle Stufe wurde manuell gesenkt: naechstes Angebot nach
    /// `LevelProgression.reentryActiveDays`, unabhaengig von der Stufe.
    var levelLoweredManually: Bool = false
    var dewDrops: Int = 0
    /// Insgesamt verdiente Tautropfen, sinkt nie (steuert das Garten-Wachstum).
    var dewEarnedTotal: Int = 0
    var decorationIDs: [String] = []
    var weeklyGoalDays: Int = 4
    /// ISO-Wochenschluessel (z. B. `2026-W44`), fuer die eine Bonus-Bluete
    /// vergeben wurde (hoechstens einmal je Woche).
    var bonusBlossomWeeks: [String] = []
    var reminderHour: Int?
    var reminderMinute: Int?
    /// Erststart (Begruessung und Uhrzeit) abgeschlossen. Neue Felder haben
    /// Standardwerte, damit die Migration leicht bleibt.
    var onboardingCompleted: Bool = false
    /// Erinnerung im Profil ausgeschaltet: es wird nichts mehr geplant.
    var reminderOff: Bool = false
    /// Termin der einmaligen 17-Uhr-Einladung (ohne gewaehlte Uhrzeit), damit
    /// nie eine zweite folgt.
    var invitationDate: Date?
    /// Ton und Haptik (Profil). Klaenge gibt es noch nicht; der Schalter
    /// wird nur gespeichert. Haptik wirkt ueber `GameHaptics`.
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var adFreePurchasedCache: Bool = false
    var installDate: Date

    init(level: TeaLevel, levelSinceDayKey: String, installDate: Date) {
        self.levelRaw = level.rawValue
        self.levelSinceDayKey = levelSinceDayKey
        self.highestLevelRaw = level.rawValue
        self.installDate = installDate
    }

    var level: TeaLevel {
        get { TeaLevel(rawValue: levelRaw) ?? .sencha }
        set { levelRaw = newValue.rawValue }
    }

    var highestLevel: TeaLevel {
        get { TeaLevel(rawValue: highestLevelRaw) ?? .sencha }
        set { highestLevelRaw = newValue.rawValue }
    }
}

/// Ein Eintrag je Kalendertag mit Spielaktivitaet.
@Model
final class DayRecord {
    /// Tagesschluessel `yyyy-MM-dd` (siehe `DayKey`).
    @Attribute(.unique) var dayKey: String
    var levelRaw: Int
    var hits: Int = 0
    var misses: Int = 0
    /// Ob an diesem Tag die Teepause erledigt wurde (= aktiver Tag).
    var teaBreakCompleted: Bool = false

    init(dayKey: String, level: TeaLevel) {
        self.dayKey = dayKey
        self.levelRaw = level.rawValue
    }

    var level: TeaLevel {
        get { TeaLevel(rawValue: levelRaw) ?? .sencha }
        set { levelRaw = newValue.rawValue }
    }
}

/// Ein Eintrag je Spiel (`GameDefinition.id`).
@Model
final class GameRecord {
    @Attribute(.unique) var gameID: String
    var lastPlayed: Date?
    var fineLevel: Int?
    var instructionsSeen: Bool = false

    init(gameID: String) {
        self.gameID = gameID
    }
}

/// Ein Eintrag je beendeter Spielrunde (Grundlage des Verlaufs). Der Bereich
/// wird als Text (`GameArea.rawValue`) gespeichert, damit das Schema
/// unabhaengig von spaeteren Enum-Erweiterungen bleibt.
@Model
final class ResultRecord {
    /// Tagesschluessel `yyyy-MM-dd` (siehe `DayKey`).
    var dayKey: String
    var gameID: String
    var areaRaw: String
    var hits: Int
    var misses: Int

    init(dayKey: String, gameID: String, area: GameArea, hits: Int, misses: Int) {
        self.dayKey = dayKey
        self.gameID = gameID
        self.areaRaw = area.rawValue
        self.hits = hits
        self.misses = misses
    }
}
