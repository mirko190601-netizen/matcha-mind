// GardenGrowth.swift
// Garten-Wachstum (MASTER-PROMPT.md, Block B4 Aufgabe 4.6): die Stufe 0-4
// richtet sich nach dem insgesamt verdienten Tau und sinkt nie.

import Foundation

enum GardenGrowth {
    /// Mindest-Tau (insgesamt verdient) je Stufe 0...4.
    static let thresholds = [0, 36, 120, 300, 600]
    static let maxStage = 4

    static func stage(dewEarnedTotal: Int) -> Int {
        thresholds.lastIndex { dewEarnedTotal >= $0 } ?? 0
    }

    /// Wie viele der festen Pflanzenplaetze in der Szene bewachsen sind.
    static func visiblePlantCount(stage: Int) -> Int {
        max(0, min(stage, maxStage)) * 2
    }
}
