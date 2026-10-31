// TeaBreakPlanner.swift
// Auswahl der Spiele fuer die Teepause (MASTER-PROMPT.md, Block B4 Aufgabe 3):
// drei Spiele aus verschiedenen Bereichen, bevorzugt solche, die noch nie
// oder am laengsten nicht gespielt wurden. Bewusst nur Foundation und ein
// uebergebener Zufallsgenerator, damit die Auswahl testbar bleibt.

import Foundation

/// Ein Spiel, das fuer die Teepause in Frage kommt.
struct TeaBreakCandidate: Equatable, Sendable {
    let gameID: String
    let area: GameArea
    /// Zeitpunkt des letzten Spiels, `nil` = noch nie gespielt.
    let lastPlayed: Date?
}

enum TeaBreakPlanner {
    /// Anzahl der Spiele in einer Teepause.
    static let defaultCount = 3

    /// Waehlt bis zu `count` Spielkennungen aus.
    /// Ablauf: Kandidaten mischen, dann stabil sortieren (nie gespielt zuerst,
    /// dann das aelteste `lastPlayed`; Gleichstand entscheidet die Position
    /// nach dem Mischen), anschliessend der Reihe nach nehmen, was einen noch
    /// nicht gewaehlten Bereich hat. Reichen die Bereiche nicht, wird mit den
    /// uebrigen in derselben Reihenfolge aufgefuellt. Gibt es weniger
    /// Kandidaten als `count`, kommen alle.
    static func plan<G: RandomNumberGenerator>(
        candidates: [TeaBreakCandidate],
        count: Int = defaultCount,
        using rng: inout G
    ) -> [String] {
        guard count > 0 else { return [] }

        let shuffled = candidates.shuffled(using: &rng)
        let sorted = shuffled.enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.lastPlayed, rhs.element.lastPlayed) {
                case (nil, nil):
                    return lhs.offset < rhs.offset
                case (nil, _):
                    return true
                case (_, nil):
                    return false
                case let (left?, right?):
                    if left != right { return left < right }
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)

        var chosen: [TeaBreakCandidate] = []
        var usedAreas: Set<GameArea> = []
        for candidate in sorted where chosen.count < count {
            if usedAreas.insert(candidate.area).inserted {
                chosen.append(candidate)
            }
        }
        for candidate in sorted where chosen.count < count {
            if !chosen.contains(where: { $0.gameID == candidate.gameID }) {
                chosen.append(candidate)
            }
        }
        return chosen.map(\.gameID)
    }
}
