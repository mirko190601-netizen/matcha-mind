// WeeklyGoal.swift
// Wochenziel (MASTER-PROMPT.md, Block B4 Aufgabe 4.6): ISO-Woche
// (Montag bis Sonntag). Der uebergebene Kalender liefert nur die Zeitzone;
// die Wochenregeln sind immer ISO 8601.

import Foundation

enum WeeklyGoal {
    private static func isoCalendar(like calendar: Calendar) -> Calendar {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        return iso
    }

    /// Wochenschluessel wie `2026-W44` (ISO-Wochenjahr, zweistellige Woche).
    static func weekKey(for date: Date, calendar: Calendar) -> String {
        let components = isoCalendar(like: calendar).dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        return "\(year)-W\(week < 10 ? "0" : "")\(week)"
    }

    /// Die sieben Tagesschluessel (Montag bis Sonntag) der Woche, die `date` enthaelt.
    static func dayKeys(ofWeekContaining date: Date, calendar: Calendar) -> [String] {
        let iso = isoCalendar(like: calendar)
        guard let start = iso.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { offset in
            iso.date(byAdding: .day, value: offset, to: start).map { DayKey.string(for: $0, calendar: iso) }
        }
    }

    static func isReached(activeDays: Int, goal: Int) -> Bool {
        activeDays >= goal
    }
}
