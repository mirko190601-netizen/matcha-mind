// DayKey.swift
// Spielerdaten (MASTER-PROMPT.md, Block B4 Aufgabe 1): Tagesschlüssel
// `yyyy-MM-dd` in lokaler Zeit. Reine Foundation-Logik, kein SwiftData.
//
// Der Schlüssel wird bewusst aus `DateComponents` zusammengesetzt statt über
// einen `DateFormatter`: so spielen Gerätesprache, Region und
// Kalendereinstellungen (z. B. buddhistischer Kalender) keine Rolle für das
// Format. Als String ist der Schlüssel lexikographisch vergleichbar
// (`"2026-01-09" < "2026-01-10"`), das ersetzt eine Datumsrechnung beim
// Zählen aktiver Tage.

import Foundation

enum DayKey {
    /// Tagesschlüssel `yyyy-MM-dd` für `date` im übergebenen Kalender (Standard:
    /// aktueller Kalender samt lokaler Zeitzone).
    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(padded(year, to: 4))-\(padded(month, to: 2))-\(padded(day, to: 2))"
    }

    private static func padded(_ value: Int, to width: Int) -> String {
        let digits = String(value)
        guard digits.count < width else { return digits }
        return String(repeating: "0", count: width - digits.count) + digits
    }
}
