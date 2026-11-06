// TeaLeafSortGameView.swift
// Spiel-View "Teeblätter sortieren" (MASTER-PROMPT.md, Block B3 Aufgabe 3).
// Baut auf `Games/Core/` auf: `GameSession`, `GameInstructionSheet`,
// `GameRuleSheet`, `GameResultView`, `HelpButton` wie bei den vorherigen
// Spielen.
//
// Rundenablauf: eine Karte erscheint, der Spieler tippt eine von 3
// Ablagen an. Richtig ist immer genau eine Ablage (siehe
// `TeaLeafSortGenerator.generateCard`) - welche Eigenschaft (Farbe, Form,
// Anzahl) bzw. welche zwei Eigenschaften (Matcha) das entscheiden, ist
// "die Regel" und wechselt nach `switchAfterCorrectCount` richtigen
// Zuordnungen in Folge. Bei Sencha wird der Wechsel vorher angekündigt
// (`showRuleChangeAnnouncement`), bei Oolong/Matcha geschieht er ohne
// Rückmeldung - der Spieler merkt es nur daran, dass seine bisherige
// Ablage plötzlich falsch ist.
//
// Vereinfachung (ähnlich FireflyPond-Illustration-Kommentar): die Karte
// zeigt Farbe/Form/Anzahl rein visuell; eine vollständige VoiceOver-
// Beschreibung aller drei Eigenschaften folgt bei Bedarf später, aktuell
// liest VoiceOver Ablage-Nummer und Kartenanzahl vor.

import SwiftUI

public struct TeaLeafSortGameView: View {
    private let level: TeaLevel
    private let game = TeaLeafSortGame()
    private let onResult: (GameResult) -> Void
    private let onFinished: () -> Void

    /// Zielspieldauer einer Runde (Abschnitt 6: "Runde 60-90 s").
    private var roundDuration: TimeInterval { GameRound.duration }

    /// Farbtoken je Ablagen-/Wert-Index (Rolle "Spielwelt",
    /// `design/designsystem-tokens.json`), Form (SF-Symbol) ist zusätzlich
    /// pro Index fest - erfüllt "Farben immer zusätzlich durch Form
    /// unterscheidbar".
    private static let colorTokens = ["matcha-300", "blossom-300", "gold-300"]
    private static let shapeSymbols = ["leaf.fill", "drop.fill", "star.fill"]

    /// Die 3 festen Ablagen: Ablage `i` ist durch die Karte mit allen drei
    /// Werten gleich `i` definiert (siehe `TeaLeafSortGenerator.generateCard`-
    /// Dokumentation: die aktive(n) Eigenschaft(en) einer Karte sind immer
    /// gleich `targetPileIndex`, daher passt Ablage `targetPileIndex`).
    private static let referenceCards: [TeaLeafCard] = (0..<3).map {
        TeaLeafCard(colorIndex: $0, shapeIndex: $0, countIndex: $0)
    }

    @State private var session = GameSession()

    @State private var showInstructions: Bool
    @State private var showRules = false
    @State private var showRuleChangeAnnouncement = false

    @State private var activeDimensions: Set<TeaLeafDimension> = [.color]
    @State private var currentCard: TeaLeafCard?
    @State private var currentTargetPileIndex = 0
    @State private var consecutiveCorrect = 0

    @State private var flashPileIndex: Int?
    @State private var flashIsGood = true

    @State private var hits = 0
    @State private var misses = 0

    /// - Parameters:
    ///   - level: aktuelle Tee-Stufe, bestimmt Regel-Anzahl und Ankündigung
    ///     (`TeaLeafSortParameters`).
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
            initialValue: !GameInstructionsSeenStore.hasSeenInstructions(gameID: TeaLeafSortGame().id)
        )
    }

    private var parameters: TeaLeafSortParameters {
        game.parameters[level] ?? TeaLeafSortParameters(activeDimensionCount: 1, announceRuleChange: true)
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
                } else if showRuleChangeAnnouncement {
                    ruleChangeAnnouncement
                } else {
                    sortingScreen
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
                titleKey: "game.teaLeafSort.instruction.page1.title",
                bodyKey: "game.teaLeafSort.instruction.page1.body"
            ),
            GameInstructionPage(
                id: 1,
                titleKey: "game.teaLeafSort.instruction.page2.title",
                bodyKey: "game.teaLeafSort.instruction.page2.body"
            ),
            GameInstructionPage(
                id: 2,
                titleKey: "game.teaLeafSort.instruction.page3.title",
                bodyKey: "game.teaLeafSort.instruction.page3.body"
            ),
        ]
    }

    private var sortingScreen: some View {
        VStack(spacing: Space.space8) {
            if let currentCard {
                cardView(currentCard)
                    .accessibilityLabel(cardAccessibilityLabel(currentCard))
            }

            HStack(spacing: Space.space4) {
                ForEach(Array(Self.referenceCards.enumerated()), id: \.offset) { index, reference in
                    pileButton(index: index, reference: reference)
                }
            }
        }
        .frame(maxWidth: Size.readingMax)
    }

    private func pileButton(index: Int, reference: TeaLeafCard) -> some View {
        let isFlashing = flashPileIndex == index
        return Button {
            handleTap(onPile: index)
        } label: {
            cardView(reference)
                .padding(Space.space3)
                .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Radius.radiusMd))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.radiusMd)
                        .strokeBorder(
                            isFlashing ? (flashIsGood ? Color("feedback-good") : Color("feedback-gentle")) : .clear,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(session.state != .running)
        .accessibilityLabel(
            String(format: String(localized: "game.teaLeafSort.pile", defaultValue: "Ablage %lld"), index + 1)
        )
    }

    private func cardView(_ card: TeaLeafCard) -> some View {
        HStack(spacing: Space.space1) {
            ForEach(0..<(card.countIndex + 1), id: \.self) { _ in
                Image(systemName: Self.shapeSymbols[card.shapeIndex])
                    .foregroundStyle(Color(Self.colorTokens[card.colorIndex]))
            }
        }
    }

    private func cardAccessibilityLabel(_ card: TeaLeafCard) -> String {
        String(
            format: String(localized: "game.teaLeafSort.card", defaultValue: "Teeblatt-Karte, %lld Stück"),
            card.countIndex + 1
        )
    }

    private var ruleChangeAnnouncement: some View {
        GlassCard(radius: Radius.radiusLg) {
            VStack(spacing: Space.space4) {
                Text(String(localized: "game.teaLeafSort.ruleChanging", defaultValue: "Die Regel ändert sich gleich!"))
                    .font(.mmHeadline)
                    .foregroundStyle(Color("ink"))
                    .multilineTextAlignment(.center)

                PrimaryButton(String(localized: "game.teaLeafSort.ruleChangeContinue", defaultValue: "Weiter")) {
                    applyPendingRuleChangeAndContinue()
                }
            }
        }
    }

    private func beginGame() {
        session.start()
        activeDimensions = TeaLeafSortGenerator.possibleActiveDimensionSets(count: parameters.activeDimensionCount)
            .randomElement() ?? [.color]
        consecutiveCorrect = 0
        hits = 0
        misses = 0
        drawNextCard()
    }

    private func drawNextCard() {
        currentTargetPileIndex = Int.random(in: 0..<TeaLeafSortGenerator.valueCount)
        currentCard = TeaLeafSortGenerator.generateCard(
            targetPileIndex: currentTargetPileIndex,
            activeDimensions: activeDimensions
        )
    }

    private func handleTap(onPile index: Int) {
        guard currentCard != nil, session.state == .running else { return }

        let isCorrect = index == currentTargetPileIndex
        if isCorrect {
            hits += 1
            GameHaptics.hit()
            consecutiveCorrect += 1
        } else {
            misses += 1
            consecutiveCorrect = 0
        }
        flashPileIndex = index
        flashIsGood = isCorrect

        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if flashPileIndex == index {
                flashPileIndex = nil
            }
        }

        if consecutiveCorrect >= TeaLeafSortGenerator.switchAfterCorrectCount {
            consecutiveCorrect = 0
            if parameters.announceRuleChange {
                showRuleChangeAnnouncement = true
                return
            }
            activeDimensions = TeaLeafSortGenerator.pickNewActiveDimensions(
                count: parameters.activeDimensionCount,
                excluding: activeDimensions
            )
        }

        advanceOrFinish()
    }

    private func applyPendingRuleChangeAndContinue() {
        showRuleChangeAnnouncement = false
        activeDimensions = TeaLeafSortGenerator.pickNewActiveDimensions(
            count: parameters.activeDimensionCount,
            excluding: activeDimensions
        )
        advanceOrFinish()
    }

    private func advanceOrFinish() {
        if session.elapsedPlayTime() >= roundDuration {
            session.finish(hits: hits, misses: misses, duration: session.elapsedPlayTime())
        } else {
            drawNextCard()
        }
    }
}

#Preview("Hell") {
    TeaLeafSortGameView(level: .sencha)
        .preferredColorScheme(.light)
}
