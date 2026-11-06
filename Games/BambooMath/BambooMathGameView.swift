// BambooMathGameView.swift
// Spiel-View "Bambus-Rechnen" (MASTER-PROMPT.md, Block B3 Aufgabe 2).
// Baut auf `Games/Core/` auf: `GameSession`, `GameInstructionSheet`,
// `GameRuleSheet`, `GameResultView`, `HelpButton` wie bei den anderen
// Sencha-Spielen.
//
// Interaktion (siehe Auftrag: "wähle eine klare, einfache Interaktion und
// dokumentiere sie"): die komplette Rechenkette wird auf einmal angezeigt
// ("12 + 5 − 3 = ?"), der Spieler tippt das Endergebnis über ein eigenes
// Zahlenpad ein (kein System-Tastatur-Textfeld, damit das Spiel durchgehend
// im Glas-Look des Designsystems bleibt) und bestätigt mit "Prüfen". Nach
// der Bestätigung zeigt ein kurzer Rahmen-Flash (`feedback-good`/
// `feedback-gentle`) das Ergebnis, danach erscheint automatisch die
// nächste Kette - es gibt keinen zweiten Versuch pro Kette, das hält den
// Rhythmus ruhig und countdown-frei.
//
// Bekannte Vereinfachung (wie bei `FireflyPondGameView` dokumentiert):
// pausiert der Spieler während des kurzen Flashs nach einer Antwort, läuft
// die 700ms-Wartezeit im Hintergrund weiter.

import SwiftUI

public struct BambooMathGameView: View {
    private let level: TeaLevel
    private let game = BambooMathGame()
    private let onResult: (GameResult) -> Void
    private let onFinished: () -> Void

    /// Zielspieldauer einer Runde (Abschnitt 6: "Runde 60-90 s").
    private var roundDuration: TimeInterval { GameRound.duration }
    /// Maximale Ziffern einer eingegebenen Antwort (Obergrenze Matcha: 100).
    private static let maxAnswerDigits = 3

    @State private var session = GameSession()

    @State private var showInstructions: Bool
    @State private var showRules = false

    @State private var currentChain: BambooMathChain?
    @State private var inputDigits = ""
    @State private var isInputLocked = false
    @State private var flashIsGood: Bool?

    @State private var hits = 0
    @State private var misses = 0

    /// - Parameters:
    ///   - level: aktuelle Tee-Stufe, bestimmt Schrittzahl, Obergrenze und
    ///     erlaubte Rechenzeichen (`BambooMathParameters`).
    ///   - onResult: Aufruf genau einmal, sobald das Ergebnis der Runde feststeht
    ///     (Fortschritt speichern).
    ///   - onFinished: Aufruf, sobald der Ergebnis-Screen bestätigt wird.
    public init(
        level: TeaLevel,
        onResult: @escaping (GameResult) -> Void = { _ in },
        onFinished: @escaping () -> Void = {}
    ) {
        self.level = level
        self.onResult = onResult
        self.onFinished = onFinished
        _showInstructions = State(
            initialValue: !GameInstructionsSeenStore.hasSeenInstructions(gameID: BambooMathGame().id)
        )
    }

    private var parameters: BambooMathParameters {
        game.parameters[level] ?? BambooMathParameters(
            stepCountRange: 3...3,
            numberUpperBound: 20,
            allowedOperators: [.add, .subtract]
        )
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
                    chainScreen
                }

                Spacer()
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
                pages: game.instructionPages,
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

    private var chainScreen: some View {
        VStack(spacing: Space.space8) {
            if let currentChain {
                expressionCard(currentChain)
            }

            NumberPad(
                enteredValue: inputDigits,
                isLocked: isInputLocked,
                onDigit: appendDigit,
                onDelete: deleteLastDigit,
                onSubmit: submitAnswer
            )
        }
        .frame(maxWidth: Size.readingMax)
    }

    private func expressionCard(_ chain: BambooMathChain) -> some View {
        GlassCard {
            Text("\(chain.displayExpression) = \(inputDigits.isEmpty ? "?" : inputDigits)")
                .font(.mmTitle)
                .foregroundStyle(Color("ink"))
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.radiusXl)
                .strokeBorder(flashBorderColor, lineWidth: 2)
        )
        .accessibilityLabel(chainAccessibilityLabel(chain))
    }

    private var flashBorderColor: Color {
        guard let flashIsGood else { return .clear }
        return flashIsGood ? Color("feedback-good") : Color("feedback-gentle")
    }

    private func chainAccessibilityLabel(_ chain: BambooMathChain) -> String {
        let answerPart = inputDigits.isEmpty
            ? String(localized: "game.bambooMath.answerPending", defaultValue: "noch keine Antwort")
            : inputDigits
        return "\(chain.accessibilityExpression) = \(answerPart)"
    }

    private func beginGame() {
        session.start()
        hits = 0
        misses = 0
        drawNextChain()
    }

    private func drawNextChain() {
        inputDigits = ""
        flashIsGood = nil
        let stepCount = Int.random(in: parameters.stepCountRange)
        currentChain = BambooMathChainGenerator.generate(stepCount: stepCount, parameters: parameters)
    }

    private func appendDigit(_ digit: Int) {
        guard inputDigits.count < Self.maxAnswerDigits else { return }
        inputDigits.append(String(digit))
    }

    private func deleteLastDigit() {
        guard !inputDigits.isEmpty else { return }
        inputDigits.removeLast()
    }

    private func submitAnswer() {
        guard let currentChain, let entered = Int(inputDigits), session.state == .running else { return }

        let isCorrect = entered == currentChain.finalResult
        if isCorrect {
            hits += 1
            GameHaptics.hit()
        } else {
            misses += 1
        }
        flashIsGood = isCorrect
        isInputLocked = true

        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard session.state == .running || session.state == .paused else { return }
            isInputLocked = false
            advanceOrFinish()
        }
    }

    private func advanceOrFinish() {
        if session.elapsedPlayTime() >= roundDuration {
            session.finish(hits: hits, misses: misses, duration: session.elapsedPlayTime())
        } else {
            drawNextChain()
        }
    }
}

/// Eigenes Zahlenpad (0-9, Löschen) plus "Prüfen"-Button, statt der
/// System-Tastatur - siehe Interaktions-Dokumentation oben.
private struct NumberPad: View {
    let enteredValue: String
    let isLocked: Bool
    let onDigit: (Int) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Space.space3), count: 3)

    var body: some View {
        VStack(spacing: Space.space4) {
            LazyVGrid(columns: columns, spacing: Space.space3) {
                ForEach(1...9, id: \.self) { digit in
                    digitButton(digit)
                }
                deleteButton
                digitButton(0)
                // Leere dritte Kachel: haelt das 3-spaltige Raster bei
                // "Löschen, 0, ⎵" gleichmäßig, ohne eine vierte Ziffernreihe
                // nur für ein einzelnes Feld zu brauchen.
                Color.clear.frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
            }

            PrimaryButton(String(localized: "game.bambooMath.submit", defaultValue: "Prüfen"), action: onSubmit)
                .disabled(enteredValue.isEmpty || isLocked)
        }
    }

    private func digitButton(_ digit: Int) -> some View {
        Button {
            onDigit(digit)
        } label: {
            Text("\(digit)")
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))
                .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Radius.radiusMd))
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.left.fill")
                .font(.system(size: Size.iconHeader, weight: .medium))
                .foregroundStyle(Color("text"))
                .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Radius.radiusMd))
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel(String(localized: "game.bambooMath.delete", defaultValue: "Löschen"))
    }
}

#Preview("Hell") {
    BambooMathGameView(level: .sencha)
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    BambooMathGameView(level: .matcha)
        .preferredColorScheme(.dark)
}
