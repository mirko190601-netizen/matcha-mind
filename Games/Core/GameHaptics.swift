// GameHaptics.swift
// Haptik (MASTER-PROMPT.md, Block B4 Aufgabe 8): die einzige Stelle, an der
// Spiele eine Rueckmeldung am Geraet ausloesen. Nur bei Treffern, nie bei
// Fehlern. Liest den Profil-Schalter ueber `backing`, das beim App-Start
// gesetzt wird (analog zu `FineLevelStore`). Ohne `backing` (Vorschauen,
// Unit-Tests) passiert nichts.

import UIKit

@MainActor
enum GameHaptics {
    static var backing: PlayerStore?

    /// Loest die eigentliche Rueckmeldung aus; Tests ersetzen die Aktion.
    static var trigger: @MainActor () -> Void = {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Ein Treffer: sanfter Impuls, wenn die Haptik im Profil eingeschaltet ist.
    static func hit() {
        guard let backing, backing.hapticsEnabled else { return }
        trigger()
    }
}
