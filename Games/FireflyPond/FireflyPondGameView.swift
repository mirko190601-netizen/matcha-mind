// FireflyPondGameView.swift
// Spiel-View "Glühwürmchen am Teich" (MASTER-PROMPT.md, Block B3
// Aufgabe 2). Baut auf `Games/Core/` auf: `GameSession` fuer den
// Rundenzustand, `GameInstructionSheet`/`GameRuleSheet`/`GameResultView`
// als fertige Baukasten-Komponenten.
//
// Rundenablauf: Objekte (Glühwürmchen oder Falter) erscheinen einzeln
// nacheinander, je `displayDuration` lang. Der Spieler tippt NUR auf ein
// Glühwürmchen in der Zielfarbe (Go); auf Ablenkung (Falter oder andere
// Glühwürmchen-Farbe) wird nicht getippt (No-Go). Wertung laut Auftrag:
// "Treffer = richtiges Tippen auf Ziel, Fehler = Tippen auf Ablenkung ODER
// Ziel verpasst" - ein korrekt ignoriertes Ablenkungs-Objekt ist also
// weder Treffer noch Fehler und wird nicht gezählt.
//
// Bekannte Vereinfachung: pausiert der Spieler während ein Objekt sichtbar
// ist, läuft dessen Anzeigezeit im Hintergrund weiter (der ?-Knopf wird in
// der Praxis zwischen zwei Objekten gedrückt). Eine lückenlose Pause mitten
// in der Anzeige folgt bei Bedarf später.

import SwiftUI

public struct FireflyPondGameView: View {
    private let level: TeaLevel
    private let game = FireflyPondGame()
    private let onResult: (GameResult) -> Void
    private let onFinished: () -> Void

    /// Anzahl Objekte pro Runde; ergibt mit `displayDuration` +
    /// `gapDuration` eine Rundendauer innerhalb der katalogweiten Vorgabe
    /// "Runde 60-90 s" (Abschnitt 6).
    private static let totalSpawnCount = 40
    private let displayDuration: TimeInterval = 1.1
    private let gapDuration: TimeInterval = 0.5

    @State private var session = GameSession()

    @State private var showInstructions: Bool
    @State private var showRules = false

    @State private var currentTargetColor: FireflyColor = .gold
    @State private var spawnQueue: [FireflyPondObjectKind] = []
    @State private var currentSpawnIndex = 0
    @State private var hasSwitchedTarget = false

    @State private var currentObject: FireflyPondObjectKind?
    @State private var wasTapped = false
    @State private var flashIsGood: Bool?

    @State private var hits = 0
    @State private var misses = 0

    /// - Parameters:
    ///   - level: aktuelle Tee-Stufe, bestimmt Farben, Ablenkungsanteil und
    ///     ob die Zielfarbe mitten in der Runde wechselt (`FireflyPondParameters`).
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
        _showInstructions = State(
            initialValue: !GameInstructionsSeenStore.hasSeenInstructions(gameID: FireflyPondGame().id)
        )
    }

    private var parameters: FireflyPondParameters {
        game.parameters[level] ?? FireflyPondParameters(
            availableColors: [.gold],
            distractionRatio: 0.3,
            targetSwitchesMidRound: false
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
                    pond
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
                titleKey: "game.fireflyPond.instruction.page1.title",
                bodyKey: "game.fireflyPond.instruction.page1.body"
            ),
            GameInstructionPage(
                id: 1,
                titleKey: "game.fireflyPond.instruction.page2.title",
                bodyKey: "game.fireflyPond.instruction.page2.body"
            ),
            GameInstructionPage(
                id: 2,
                titleKey: "game.fireflyPond.instruction.page3.title",
                bodyKey: "game.fireflyPond.instruction.page3.body"
            ),
        ]
    }

    private var pond: some View {
        Button {
            handleTapOnCurrentObject()
        } label: {
            Group {
                if let currentObject {
                    creatureView(for: currentObject)
                } else {
                    Color.clear
                }
            }
            .frame(width: Size.touchMin, height: Size.touchMin)
        }
        .buttonStyle(.plain)
        .disabled(currentObject == nil || session.state != .running)
    }

    @ViewBuilder
    private func creatureView(for kind: FireflyPondObjectKind) -> some View {
        switch kind {
        case .firefly(let color):
            // Die Illustration bringt nur eine feste Farbgebung mit (siehe
            // `FireflyColor`-Dokumentation) - ein Farbton-Token einfärbt sie
            // je Zielfarbe; nach einem Tipp überlagert kurz das Feedback.
            SmallCreatureIllustration(kind: .firefly)
                .colorMultiply(flashTint ?? Color(color.colorToken))
        case .moth:
            if let flashTint {
                // Nur nach einem Tipp eingefärbt; ohne Tipp bleibt der
                // Falter in seiner Originalfarbe aus der Illustration.
                SmallCreatureIllustration(kind: .moth)
                    .colorMultiply(flashTint)
            } else {
                SmallCreatureIllustration(kind: .moth)
            }
        }
    }

    /// Kurzes Feedback nach einem Tipp (`feedback-good`/`feedback-gentle`,
    /// siehe Auftrag: "Feedback nur feedback-good/feedback-gentle").
    private var flashTint: Color? {
        guard let flashIsGood else { return nil }
        return flashIsGood ? Color("feedback-good") : Color("feedback-gentle")
    }

    private func beginGame() {
        session.start()
        startRound()
    }

    private func startRound() {
        hits = 0
        misses = 0
        hasSwitchedTarget = false
        currentSpawnIndex = 0
        currentTargetColor = parameters.availableColors.randomElement() ?? .gold

        let firstSegmentCount = parameters.targetSwitchesMidRound
            ? Self.totalSpawnCount / 2
            : Self.totalSpawnCount
        spawnQueue = FireflyPondSpawnGenerator.generate(
            count: firstSegmentCount,
            parameters: parameters,
            targetColor: currentTargetColor
        )

        runRound()
    }

    private func runRound() {
        Task {
            while session.state == .running || session.state == .paused {
                while session.state == .paused {
                    try? await Task.sleep(nanoseconds: 150_000_000)
                }
                guard session.state == .running else { return }

                if currentSpawnIndex >= spawnQueue.count {
                    if parameters.targetSwitchesMidRound, !hasSwitchedTarget {
                        switchTargetMidRound()
                    } else {
                        break
                    }
                }

                await showNextSpawn()
            }

            guard session.state == .running || session.state == .paused else { return }
            session.finish(hits: hits, misses: misses, duration: session.elapsedPlayTime())
        }
    }

    /// Matcha: wechselt die Zielfarbe einmal in der Mitte der Runde und
    /// erzeugt die zweite Rundenhälfte mit der neuen Zielfarbe.
    private func switchTargetMidRound() {
        hasSwitchedTarget = true
        let remainingCount = Self.totalSpawnCount - spawnQueue.count
        guard remainingCount > 0 else { return }

        let newTarget = parameters.availableColors.filter { $0 != currentTargetColor }.randomElement()
            ?? currentTargetColor
        currentTargetColor = newTarget
        spawnQueue += FireflyPondSpawnGenerator.generate(
            count: remainingCount,
            parameters: parameters,
            targetColor: newTarget
        )
    }

    private func showNextSpawn() async {
        let kind = spawnQueue[currentSpawnIndex]
        currentObject = kind
        wasTapped = false
        flashIsGood = nil

        try? await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))

        if !wasTapped {
            evaluateMissedWithoutTap(kind: kind)
        }
        currentObject = nil
        currentSpawnIndex += 1

        try? await Task.sleep(nanoseconds: UInt64(gapDuration * 1_000_000_000))
    }

    private func handleTapOnCurrentObject() {
        guard let currentObject, !wasTapped, session.state == .running else { return }
        wasTapped = true

        if case .firefly(let color) = currentObject, color == currentTargetColor {
            hits += 1
            GameHaptics.hit()
            flashIsGood = true
        } else {
            misses += 1
            flashIsGood = false
        }
    }

    /// Objekt wurde nicht angetippt: ein verpasstes Zielfarbe-Glühwürmchen
    /// ist ein Fehler, eine korrekt ignorierte Ablenkung zählt laut
    /// Auftrag weder als Treffer noch als Fehler.
    private func evaluateMissedWithoutTap(kind: FireflyPondObjectKind) {
        if case .firefly(let color) = kind, color == currentTargetColor {
            misses += 1
        }
    }
}

#Preview("Hell") {
    FireflyPondGameView(level: .sencha)
        .preferredColorScheme(.light)
}
