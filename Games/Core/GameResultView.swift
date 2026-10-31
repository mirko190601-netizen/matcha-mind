// GameResultView.swift
// Komponente "Ergebnis-Screen" (MASTER-PROMPT.md, Block B3 Aufgabe 1):
// zeigt Treffer, Genauigkeit in % und die Tautropfen ("+12 Tau")
// nach jeder Spielrunde. Nutzt ausschliesslich den Ton
// `feedback-good` - kein Rot, kein Countdown irgendwo im Baukasten.

import SwiftUI

/// Ergebnis-Screen nach einer beendeten Spielrunde.
public struct GameResultView: View {
    private let result: GameResult
    private let dewReward: Int
    private let onContinue: () -> Void

    /// - Parameters:
    ///   - result: Ergebnis der beendeten Runde (`GameSession.finish`).
    ///   - dewReward: Anzahl gewonnener Tautropfen (aus den Spiel-Views: `PlayerStore.dewPerGame`, derselbe Wert, den
    ///     `recordGameResult` gutschreibt).
    ///   - onContinue: Aufruf bei "Weiter".
    public init(result: GameResult, dewReward: Int, onContinue: @escaping () -> Void) {
        self.result = result
        self.dewReward = dewReward
        self.onContinue = onContinue
    }

    private var accuracyPercent: Int {
        Int((result.accuracy * 100).rounded())
    }

    private var dewText: String {
        let format = String(localized: "game.result.dew", defaultValue: "+%lld Tau")
        return String(format: format, dewReward)
    }

    public var body: some View {
        VStack(spacing: Space.space6) {
            Text(String(localized: "game.result.title", defaultValue: "Runde geschafft"))
                .font(.mmTitle)
                .foregroundStyle(Color("ink"))

            GlassCard {
                VStack(spacing: Space.space3) {
                    HStack {
                        Text(String(localized: "game.result.hitsLabel", defaultValue: "Treffer"))
                            .font(.mmBody)
                            .foregroundStyle(Color("text"))
                        Spacer()
                        Text("\(result.hits)")
                            .font(.mmCallout)
                            .foregroundStyle(Color("ink"))
                    }
                    HStack {
                        Text(String(localized: "game.result.accuracyLabel", defaultValue: "Genauigkeit"))
                            .font(.mmBody)
                            .foregroundStyle(Color("text"))
                        Spacer()
                        Text("\(accuracyPercent) %")
                            .font(.mmCallout)
                            .foregroundStyle(Color("ink"))
                    }
                }
            }

            Text(dewText)
                .font(.mmHeadline)
                .foregroundStyle(Color("feedback-good"))

            PrimaryButton(String(localized: "game.result.continue", defaultValue: "Weiter"), action: onContinue)
        }
        .padding(Space.space6)
        .background(Color("bg-tea"))
    }
}

#Preview("Hell") {
    GameResultView(
        result: GameResult(hits: 9, misses: 1, duration: 72),
        dewReward: 12,
        onContinue: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GameResultView(
        result: GameResult(hits: 9, misses: 1, duration: 72),
        dewReward: 12,
        onContinue: {}
    )
    .preferredColorScheme(.dark)
}
