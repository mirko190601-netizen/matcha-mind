// ReduceMotion.swift
// Hilfsmittel fuer "Bewegung reduzieren" (design/designsystem-README.md,
// Abschnitt "Illustration v2" -> "Bewegung der Illustrationen": "Bei
// 'Bewegung reduzieren': Standbild."). Wird von allen dezenten
// Dauer-Animationen der Illustrationen genutzt (MASTER-PROMPT.md B2 P7).
//
// Kein eigenes Hilfsmittel dafuer war vorher in `DesignSystem/` vorhanden
// (geprueft: Font+MatchaMind.swift, GlassButton.swift, GlassCard.swift,
// HeaderIconButton.swift, HelpButton.swift, PrimaryButton.swift,
// Tokens.swift - keine Reduce-Motion-Bezuege).

import SwiftUI

/// Reine, ohne UI-Rendering testbare Funktion: liefert die Dauer eines
/// Animations-Zyklus, oder `nil` wenn Bewegung reduziert werden soll
/// (Standbild). Von `onAppearStartGentleLoop(...)` genutzt, aber bewusst
/// als freie Funktion ausgelagert, damit sie in Unit-Tests ohne
/// View-Rendering gegen `accessibilityReduceMotion == true` geprueft werden
/// kann.
public func illustrationAnimationDuration(reduceMotion: Bool, baseDuration: Double) -> Double? {
    reduceMotion ? nil : baseDuration
}

public extension View {
    /// Startet (sofern `reduceMotion` nicht aktiv ist) beim Erscheinen der
    /// View eine dauerhaft wiederholende, sanfte Animation, die `isActive`
    /// von ihrem Startwert auf `true` schaltet. Fuer `autoreverses: true`
    /// ergibt das ein Hin-und-Her (z. B. Atmen, Glimmen, Wiegen); fuer
    /// `autoreverses: false` einen Zyklus, der nach jedem Durchlauf sofort
    /// von vorn beginnt (z. B. ein sich ausbreitender, verblassender
    /// Wasserring).
    ///
    /// Ist `reduceMotion == true` (Systemeinstellung "Bewegung reduzieren"),
    /// passiert nichts: `isActive` bleibt auf seinem Startwert stehen, die
    /// View zeigt ein Standbild - siehe
    /// `illustrationAnimationDuration(reduceMotion:baseDuration:)`.
    func onAppearStartGentleLoop(
        reduceMotion: Bool,
        baseDuration: Double,
        delay: Double = 0,
        autoreverses: Bool = true,
        isActive: Binding<Bool>
    ) -> some View {
        onAppear {
            guard let duration = illustrationAnimationDuration(
                reduceMotion: reduceMotion,
                baseDuration: baseDuration
            ) else { return }

            withAnimation(
                .easeInOut(duration: duration)
                    .repeatForever(autoreverses: autoreverses)
                    .delay(delay)
            ) {
                isActive.wrappedValue = true
            }
        }
    }
}
