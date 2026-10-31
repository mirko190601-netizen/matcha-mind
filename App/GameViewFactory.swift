// GameViewFactory.swift
// Baut die Spiel-View zu einer Spiel-Kennung (Block B4). Wird von der
// Spiele-Bibliothek (freies Spielen) und der Teepause gemeinsam genutzt,
// damit die Zuordnung Kennung -> View nur an einer Stelle steht.

import SwiftUI

// `@MainActor`: die Spiel-Views sind main-actor-isoliert; ohne diese
// Isolation wuerden die nicht-`Sendable`-Closures ueber die Actor-Grenze
// gereicht (Swift-6-Fehler "sending ... risks causing data races").
@MainActor
enum GameViewFactory {
    /// - Parameters:
    ///   - gameID: Kennung aus `GameCatalog` (z. B. "teapot-row").
    ///   - level: Tee-Stufe, mit der das Spiel gespielt wird.
    ///   - onResult: Aufruf genau einmal, sobald das Ergebnis feststeht.
    ///   - onFinished: Aufruf, sobald der Ergebnis-Screen bestaetigt wird.
    @ViewBuilder
    static func view(
        for gameID: String,
        level: TeaLevel,
        onResult: @escaping (GameResult) -> Void,
        onFinished: @escaping () -> Void
    ) -> some View {
        switch gameID {
        case TeapotRowGame().id:
            TeapotRowGameView(level: level, onResult: onResult, onFinished: onFinished)
        case FireflyPondGame().id:
            FireflyPondGameView(level: level, onResult: onResult, onFinished: onFinished)
        case MosaicBedGame().id:
            MosaicBedGameView(level: level, onResult: onResult, onFinished: onFinished)
        case TeaLeafSortGame().id:
            TeaLeafSortGameView(level: level, onResult: onResult, onFinished: onFinished)
        case BambooMathGame().id:
            BambooMathGameView(level: level, onResult: onResult, onFinished: onFinished)
        default:
            // Platzhalter-Spiele (noch nicht gebaut) sind nie spielbar und
            // oeffnen daher nie eine Spiel-View - dieser Zweig dient nur der
            // Vollstaendigkeit des Switches.
            EmptyView()
        }
    }
}
