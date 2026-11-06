// HistoryCalculator.swift
// Verlauf (MASTER-PROMPT.md, Block B4 Aufgabe 8): reine Auswertung ohne
// SwiftData, damit sie sich testen laesst. Wochen sind ISO-Wochen wie in
// `WeeklyGoal`, Tage werden ueber `DayKey` verglichen (keine Sekundenrechnung).

import Foundation

/// Eine Kalenderwoche im Verlauf: sieben Tage, je aktiv (Teepause erledigt) oder nicht.
struct HistoryWeek: Equatable, Sendable {
    /// ISO-Wochenschluessel, z. B. `2026-W44`.
    let weekKey: String
    /// Montag bis Sonntag als Tagesschluessel.
    let dayKeys: [String]
    let activeStates: [Bool]

    var activeCount: Int { activeStates.filter { $0 }.count }
}

/// Genauigkeit eines Bereichs als Ganzzahl-Prozent (0 bis 100).
struct AreaAccuracy: Equatable, Sendable {
    let area: GameArea
    let percent: Int
}

/// Treffer und Fehler eines einzelnen Ergebnisses, losgeloest vom Modell.
struct ResultSummary: Equatable, Sendable {
    let dayKey: String
    let areaRaw: String
    let hits: Int
    let misses: Int
}

enum HistoryCalculator {
    /// Anzahl Wochen in der Wochen-Darstellung.
    static let weekCount = 6
    /// Fenster fuer die Genauigkeit: laufende Woche plus die drei davor.
    static let accuracyWeekCount = 4

    /// Die letzten `count` Wochen, die aktuelle zuerst.
    static func weeks(
        now: Date,
        completedDayKeys: Set<String>,
        count: Int = weekCount,
        calendar: Calendar
    ) -> [HistoryWeek] {
        var result: [HistoryWeek] = []
        for offset in 0..<max(count, 0) {
            guard let date = calendar.date(byAdding: .day, value: -7 * offset, to: now) else { continue }
            let keys = WeeklyGoal.dayKeys(ofWeekContaining: date, calendar: calendar)
            var states: [Bool] = []
            for key in keys {
                states.append(completedDayKeys.contains(key))
            }
            result.append(HistoryWeek(
                weekKey: WeeklyGoal.weekKey(for: date, calendar: calendar),
                dayKeys: keys,
                activeStates: states
            ))
        }
        return result
    }

    /// Erster Tagesschluessel (Montag) des Genauigkeits-Fensters.
    static func accuracyWindowStartKey(now: Date, calendar: Calendar) -> String? {
        let back = -7 * (accuracyWeekCount - 1)
        guard let date = calendar.date(byAdding: .day, value: back, to: now) else { return nil }
        return WeeklyGoal.dayKeys(ofWeekContaining: date, calendar: calendar).first
    }

    /// Genauigkeit je Bereich ueber die letzten vier Wochen, in der Reihenfolge
    /// von `GameArea.allCases`. Bereiche ohne Versuche fehlen.
    static func accuracy(
        results: [ResultSummary],
        now: Date,
        calendar: Calendar
    ) -> [AreaAccuracy] {
        guard let startKey = accuracyWindowStartKey(now: now, calendar: calendar) else { return [] }
        var hitsByArea: [String: Int] = [:]
        var attemptsByArea: [String: Int] = [:]
        for item in results where item.dayKey >= startKey {
            hitsByArea[item.areaRaw, default: 0] += item.hits
            attemptsByArea[item.areaRaw, default: 0] += item.hits + item.misses
        }
        var output: [AreaAccuracy] = []
        for area in GameArea.allCases {
            let attempts = attemptsByArea[area.rawValue] ?? 0
            guard attempts > 0 else { continue }
            let hits = hitsByArea[area.rawValue] ?? 0
            output.append(AreaAccuracy(area: area, percent: percent(hits: hits, attempts: attempts)))
        }
        return output
    }

    /// Gerundetes Ganzzahl-Prozent; ohne Versuche 0 (keine Division durch 0).
    static func percent(hits: Int, attempts: Int) -> Int {
        guard attempts > 0 else { return 0 }
        return (hits * 100 + attempts / 2) / attempts
    }
}
