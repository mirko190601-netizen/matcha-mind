// TeapotRowGameView.swift
// Spiel-View "Teekannen-Reihe" (MASTER-PROMPT.md, Block B3 Aufgabe 2).
// Baut auf `Games/Core/` auf: `GameSession` fuer den Rundenzustand,
// `GameInstructionSheet`/`GameRuleSheet`/`GameResultView` als fertige
// Baukasten-Komponenten, `FineLevelTracker` fuer die Feinstufe innerhalb
// der aktuellen Tee-Stufe.
//
// Rundenablauf: mehrere Merk-Durchgaenge ("Trials") hintereinander, bis
// die Zielspieldauer erreicht ist (`roundDuration`, innerhalb der
// katalogweiten Vorgabe "Runde 60-90 s", Abschnitt 6). Jeder Tipp waehrend
// der Eingabe wird sofort gewertet - "Treffer = richtige Position zur
// richtigen Zeit in der Sequenz, Fehler = falsche Position" (Auftrag) - ob
// die Feinstufe nach einem Trial steigt oder faellt, haengt davon ab, ob
// der gesamte Trial fehlerfrei war (`FineLevelTracker.recordSuccess()`/
// `recordFailure()`).

import SwiftUI

public struct TeapotRowGameView: View {
    private let level: TeaLevel
    private let game = TeapotRowGame()
    private let onResult: (GameResult) -> Void
    private let onFinished: () -> Void

    /// Zielspieldauer einer Runde (Abschnitt 6: "Runde 60-90 s").
    private let roundDuration: TimeInterval = 75

    @State private var session = GameSession()
    @State private var fineLevelTracker: FineLevelTracker

    @State private var showInstructions: Bool
    @State private var showRules = false

    @State private var sequence: [Int] = []
    @State private var expectedTaps: [Int] = []
    @State private var tappedCount = 0
    @State private var isPlayingBack = false
    @State private var roundHadMistake = false

    @State private var highlightedPosition: Int?
    @State private var flashPosition: Int?
    @State private var flashIsGood = true

    @State private var hits = 0
    @State private var misses = 0

    /// - Parameters:
    ///   - level: aktuelle Tee-Stufe, bestimmt Sequenzlaenge und Richtung
    ///     (`TeapotRowParameters`).
    ///   - onResult: Aufruf genau einmal, sobald das Ergebnis der Runde feststeht
    ///     (Fortschritt speichern).
    ///   - onFinished: Aufruf, sobald der Ergebnis-Screen bestaetigt wird
    ///     (Rueckkehr zu Teepause/Bibliothek - Anbindung folgt in Block
    ///     B3 Aufgabe 4 / B4).
    public init(
        level: TeaLevel,
        onResult: @escaping (GameResult) -> Void = { _ in },
        onFinished: @escaping () -> Void = {}
    ) {
        self.level = level
        self.onResult = onResult
        self.onFinished = onFinished
        let range = TeapotRowGame().parameters[level]?.sequenceLengthRange ?? 3...5
        _fineLevelTracker = State(
            initialValue: FineLevelTracker(
                lowerBound: range.lowerBound,
                upperBound: range.upperBound,
                startLevel: FineLevelStore.startLevel(gameID: TeapotRowGame().id)
            )
        )
        _showInstructions = State(
            initialValue: !GameInstructionsSeenStore.hasSeenInstructions(gameID: TeapotRowGame().id)
        )
    }

    private var direction: TeapotRowDirection {
        game.parameters[level]?.direction ?? .forward
    }

    public var body: some View {
        ZStack {
            Color("bg-garden").ignoresSafeArea()

            VStack(spacing: Space.space6) {
                HStack {
                    Spacer()
                    HelpButton {
                        session.pause()
                        showRules = true
                    }
                }

                Spacer()

                if case .finished(let result) = session.state {
                    GameResultView(result: result, dewReward: PlayerStore.dewPerGame, onContinue: onFinished)
                } else {
                    teapotGrid
                    Spacer()
                }
            }
            .padding(Space.space6)
        }
        // Genau einmal, sobald das Ergebnis feststeht (Uebergang nach `.finished`).
        .onChange(of: session.state) { _, newState in
            if case .finished(let result) = newState {
                onResult(result)
            }
        }
        .sheet(isPresented: $showInstructions) {
            GameInstructionSheet(
                pages: instructionPages,
                hasTrialRound: game.hasTrialRound,
                onSkip: { showInstructions = false; GameInstructionsSeenStore.markSeen(gameID: game.id); beginGame() },
                onFinish: { showInstructions = false; GameInstructionsSeenStore.markSeen(gameID: game.id); beginGame() }
            )
        }
        .sheet(isPresented: $showRules) {
            GameRuleSheet(
                shortRuleKeys: game.shortRuleKeys,
                onShowInstructions: { showRules = false; showInstructions = true },
                onContinue: { showRules = false; session.resume() }
            )
        }
    }

    private var instructionPages: [GameInstructionPage] {
        [
            GameInstructionPage(
                id: 0,
                titleKey: "game.teapotRow.instruction.page1.title",
                bodyKey: "game.teapotRow.instruction.page1.body"
            ),
            GameInstructionPage(
                id: 1,
                titleKey: "game.teapotRow.instruction.page2.title",
                bodyKey: "game.teapotRow.instruction.page2.body"
            ),
            GameInstructionPage(
                id: 2,
                titleKey: "game.teapotRow.instruction.page3.title",
                bodyKey: "game.teapotRow.instruction.page3.body"
            ),
        ]
    }

    private var teapotGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: Space.space3), count: 3)
        return LazyVGrid(columns: columns, spacing: Space.space3) {
            ForEach(0..<TeapotRowGame.positionCount, id: \.self) { position in
                teapotButton(at: position)
            }
        }
        .frame(maxWidth: Size.readingMax)
    }

    private func teapotButton(at position: Int) -> some View {
        let isHighlighted = highlightedPosition == position
        let flashColor: Color? = flashPosition == position
            ? (flashIsGood ? Color("feedback-good") : Color("feedback-gentle"))
            : nil

        return Button {
            handleTap(on: position)
        } label: {
            // Platzhalter-Symbol (echte Illustration kommt spaeter, siehe
            // Auftrag). Groesse ueber vorhandenes Icon-Token, da es noch
            // kein eigenes Token fuer Spielfeld-Symbole gibt.
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: Size.iconHeader, weight: .medium))
                .foregroundStyle(flashColor ?? (isHighlighted ? Color("lavender-500") : Color("text-muted")))
                .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .disabled(isPlayingBack || session.state != .running || tappedCount >= expectedTaps.count)
        .accessibilityLabel(
            String(
                format: String(localized: "game.teapotRow.position", defaultValue: "Kanne %lld"),
                position + 1
            )
        )
    }

    private func beginGame() {
        session.start()
        startRound()
    }

    private func startRound() {
        roundHadMistake = false
        tappedCount = 0
        sequence = TeapotRowSequenceGenerator.generate(
            length: fineLevelTracker.fineLevel,
            positionCount: TeapotRowGame.positionCount
        )
        expectedTaps = direction == .forward ? sequence : sequence.reversed()
        playback()
    }

    private func playback() {
        isPlayingBack = true
        Task {
            for position in sequence {
                guard session.state == .running else { return }
                highlightedPosition = position
                try? await Task.sleep(nanoseconds: 600_000_000)
                highlightedPosition = nil
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            isPlayingBack = false
        }
    }

    private func handleTap(on position: Int) {
        guard !isPlayingBack, session.state == .running, tappedCount < expectedTaps.count else { return }

        let isCorrect = expectedTaps[tappedCount] == position
        if isCorrect {
            hits += 1
        } else {
            misses += 1
            roundHadMistake = true
        }
        flashPosition = position
        flashIsGood = isCorrect
        tappedCount += 1

        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if flashPosition == position {
                flashPosition = nil
            }
        }

        guard tappedCount == expectedTaps.count else { return }
        finishRound()
    }

    private func finishRound() {
        if roundHadMistake {
            fineLevelTracker.recordFailure()
        } else {
            fineLevelTracker.recordSuccess()
        }
        FineLevelStore.save(gameID: game.id, level: fineLevelTracker.fineLevel)

        if session.elapsedPlayTime() >= roundDuration {
            session.finish(hits: hits, misses: misses, duration: session.elapsedPlayTime())
        } else {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                startRound()
            }
        }
    }
}

#Preview("Hell") {
    TeapotRowGameView(level: .sencha)
        .preferredColorScheme(.light)
}
