// GameRuleSheet.swift
// Komponente "Regel-Fenster" aus design/designsystem-README.md
// ("Komponenten"): Sheet `.medium`, 3-4 Kurzregeln, "Ganze Anleitung
// ansehen" (oeffnet `GameInstructionSheet`), "Weiterspielen". Wird vom
// `HelpButton` (?) oben rechts in jedem Spiel geoeffnet und pausiert dabei
// die laufende Runde.

import SwiftUI

/// Regel-Fenster: zeigt die 3-4 Kurzregeln eines Spiels
/// (`GameDefinition.shortRuleKeys`) als Glas-Karte. Das Pausieren der
/// Spielrunde beim Oeffnen uebernimmt die aufrufende Stelle (z. B. durch
/// `session.pause()` im `onAppear`/beim Praesentieren des Sheets) - dieses
/// View ruft dafuer `onContinue` erst beim "Weiterspielen"-Tippen auf, das
/// die Call-Site mit `session.resume()` verbindet.
public struct GameRuleSheet: View {
    private let shortRuleKeys: [String]
    private let onShowInstructions: () -> Void
    private let onContinue: () -> Void

    /// - Parameters:
    ///   - shortRuleKeys: 3-4 String-Katalog-Schluessel der Kurzregeln.
    ///   - onShowInstructions: Aufruf bei "Ganze Anleitung ansehen".
    ///   - onContinue: Aufruf bei "Weiterspielen" (Runde fortsetzen).
    public init(
        shortRuleKeys: [String],
        onShowInstructions: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.shortRuleKeys = shortRuleKeys
        self.onShowInstructions = onShowInstructions
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: Space.space4) {
            Text(String(localized: "game.rules.title", defaultValue: "Kurz erklärt"))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))

            GlassCard(radius: Radius.radiusLg) {
                VStack(alignment: .leading, spacing: Space.space3) {
                    ForEach(Array(shortRuleKeys.enumerated()), id: \.offset) { _, key in
                        Text(LocalizedStringKey(key))
                            .font(.mmBody)
                            .foregroundStyle(Color("text"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassButton(
                String(localized: "game.rules.openInstructions", defaultValue: "Ganze Anleitung ansehen"),
                action: onShowInstructions
            )

            PrimaryButton(
                String(localized: "game.rules.continue", defaultValue: "Weiterspielen"),
                action: onContinue
            )
        }
        .padding(Space.space6)
        .background(Color("bg-tea"))
        .presentationDetents([.medium])
    }
}

#Preview("Hell") {
    GameRuleSheet(
        shortRuleKeys: ["preview.rule.one", "preview.rule.two", "preview.rule.three"],
        onShowInstructions: {},
        onContinue: {}
    )
    .preferredColorScheme(.light)
}
