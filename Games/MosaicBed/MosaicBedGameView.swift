// MosaicBedGameView.swift
// Spiel-View "Das Mosaik-Beet" (MASTER-PROMPT.md, Block B3 Aufgabe 2).
// Baut auf `Games/Core/` auf: `GameSession`, `GameInstructionSheet`,
// `GameRuleSheet`, `GameResultView`, `HelpButton` wie bei den vorherigen
// Spielen.
//
// Rundenablauf: `MosaicBedGenerator.generateUniquePuzzle` liefert ein
// Rätsel mit genau 1 Lösung (Gate-Anforderung). Der Spieler tippt ein
// leeres Feld an, um eine Pflanzenart zu setzen bzw. zu wechseln (zyklisch
// durch alle Arten, danach wieder leer). Sobald alle Felder der aktuellen
// Lösung entsprechen, ist das Rätsel gelöst; reicht die Zeit noch für ein
// weiteres Rätsel innerhalb der Rundendauer, startet direkt das nächste.

import SwiftUI

public struct MosaicBedGameView: View {
    private let level: TeaLevel
    private let game = MosaicBedGame()
    private let onResult: (GameResult) -> Void
    private let onFinished: () -> Void

    /// Zielspieldauer einer Runde (Abschnitt 6: "Runde 60-90 s"); bei
    /// einem Logikrätsel wie diesem eher eine Richtgröße dafür, wie viele
    /// Rätsel hintereinander folgen, als eine harte Grenze.
    private var roundDuration: TimeInterval { GameRound.duration }

    @State private var session = GameSession()

    @State private var showInstructions: Bool
    @State private var showRules = false

    @State private var puzzle: MosaicBedPuzzle?
    @State private var playerGrid: [[MosaicPlantType?]] = []
    @State private var flashCell: (row: Int, col: Int)?
    @State private var flashIsGood = true

    @State private var hits = 0
    @State private var misses = 0

    /// - Parameters:
    ///   - level: aktuelle Tee-Stufe, bestimmt Rastergröße und Regeln
    ///     (`MosaicBedParameters`).
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
            initialValue: !GameInstructionsSeenStore.hasSeenInstructions(gameID: MosaicBedGame().id)
        )
    }

    private var parameters: MosaicBedParameters {
        game.parameters[level] ?? MosaicBedParameters(gridSize: 4, forbiddenAdjacentPairs: [], hintAvailable: true)
    }

    public var body: some View {
        ZStack {
            Color("bg-garden").ignoresSafeArea()

            VStack(spacing: Space.space6) {
                HStack {
                    if parameters.hintAvailable {
                        GlassButton(String(localized: "game.mosaicBed.hint", defaultValue: "Hinweis"), action: giveHint)
                    }
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
                    grid
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
                titleKey: "game.mosaicBed.instruction.page1.title",
                bodyKey: "game.mosaicBed.instruction.page1.body"
            ),
            GameInstructionPage(
                id: 1,
                titleKey: "game.mosaicBed.instruction.page2.title",
                bodyKey: "game.mosaicBed.instruction.page2.body"
            ),
            GameInstructionPage(
                id: 2,
                titleKey: "game.mosaicBed.instruction.page3.title",
                bodyKey: "game.mosaicBed.instruction.page3.body"
            ),
        ]
    }

    private var grid: some View {
        let size = parameters.gridSize
        let columns = Array(repeating: GridItem(.flexible(), spacing: Space.space2), count: size)
        // Ein einziges ForEach mit eindeutigen IDs (0..<size*size). Zwei
        // verschachtelte ForEach(0..<size) erzeugten im LazyVGrid doppelte IDs
        // (0...size-1 je Reihe) - SwiftUI hat dadurch ab Reihe 2 keine
        // eigenen Felder fuer VoiceOver/UI-Tests angelegt.
        return LazyVGrid(columns: columns, spacing: Space.space2) {
            ForEach(0..<(size * size), id: \.self) { index in
                cellButton(row: index / size, col: index % size)
            }
        }
        .frame(maxWidth: Size.readingMax)
    }

    private func cellButton(row: Int, col: Int) -> some View {
        let isGiven = puzzle?.givens[row][col] != nil
        let value = playerGrid.indices.contains(row) ? playerGrid[row][col] : nil
        let isFlashing = flashCell?.row == row && flashCell?.col == col

        return Button {
            handleTap(row: row, col: col)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.radiusSm)
                    .fill(isGiven ? Color("bg-band") : Color("bg-tea"))
                if let value {
                    Image(systemName: value.symbolName)
                        .font(.system(size: Size.iconHeader, weight: .medium))
                        .foregroundStyle(
                            isFlashing
                                ? (flashIsGood ? Color("feedback-good") : Color("feedback-gentle"))
                                : Color(value.colorToken)
                        )
                }
            }
            .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
        }
        .buttonStyle(.plain)
        .disabled(isGiven || session.state != .running)
        .accessibilityLabel(accessibilityLabel(row: row, col: col, value: value, isGiven: isGiven))
    }

    private func accessibilityLabel(row: Int, col: Int, value: MosaicPlantType?, isGiven: Bool) -> String {
        let position = String(
            format: String(localized: "game.mosaicBed.cellPosition", defaultValue: "Feld Reihe %lld, Spalte %lld"),
            row + 1,
            col + 1
        )
        guard let value else {
            return position
        }
        let plantName = plantAccessibilityName(value)
        return isGiven
            ? "\(position), \(plantName) vorgegeben"
            : "\(position), \(plantName)"
    }

    private func plantAccessibilityName(_ type: MosaicPlantType) -> String {
        switch type {
        case .leaf: String(localized: "game.mosaicBed.plant.leaf", defaultValue: "Blatt")
        case .drop: String(localized: "game.mosaicBed.plant.drop", defaultValue: "Tropfen")
        case .sun: String(localized: "game.mosaicBed.plant.sun", defaultValue: "Sonne")
        case .star: String(localized: "game.mosaicBed.plant.star", defaultValue: "Stern")
        case .moon: String(localized: "game.mosaicBed.plant.moon", defaultValue: "Mond")
        case .flame: String(localized: "game.mosaicBed.plant.flame", defaultValue: "Flamme")
        }
    }

    private func beginGame() {
        session.start()
        startPuzzle()
    }

    private func startPuzzle() {
        let newPuzzle = MosaicBedGenerator.generateUniquePuzzle(parameters: parameters)
        puzzle = newPuzzle
        playerGrid = newPuzzle?.givens ?? []
    }

    private func handleTap(row: Int, col: Int) {
        guard let puzzle, session.state == .running else { return }
        guard puzzle.givens[row][col] == nil else { return }

        let current = playerGrid[row][col]
        let next = nextPlantType(after: current, in: puzzle.plantTypes)
        playerGrid[row][col] = next

        if let next {
            let isCorrect = next == puzzle.solution[row][col]
            if isCorrect {
                hits += 1
                GameHaptics.hit()
            } else {
                misses += 1
            }
            flashCell = (row, col)
            flashIsGood = isCorrect
            Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                if flashCell?.row == row, flashCell?.col == col {
                    flashCell = nil
                }
            }
        }

        checkCompletion()
    }

    /// Zyklus: leer -> erste Art -> ... -> letzte Art -> wieder leer.
    private func nextPlantType(after current: MosaicPlantType?, in plantTypes: [MosaicPlantType]) -> MosaicPlantType? {
        guard let current, let index = plantTypes.firstIndex(of: current) else {
            return plantTypes.first
        }
        let nextIndex = index + 1
        return nextIndex < plantTypes.count ? plantTypes[nextIndex] : nil
    }

    /// Nur bei Sencha sichtbar (siehe `MosaicBedParameters.hintAvailable`):
    /// füllt ein zufälliges noch leeres Feld mit der richtigen Pflanzenart,
    /// ohne das als Treffer oder Fehler zu werten.
    private func giveHint() {
        guard let puzzle, session.state == .running else { return }
        let size = puzzle.gridSize
        var emptyCells: [(row: Int, col: Int)] = []
        for row in 0..<size {
            for col in 0..<size where puzzle.givens[row][col] == nil && playerGrid[row][col] == nil {
                emptyCells.append((row: row, col: col))
            }
        }
        guard let (row, col) = emptyCells.randomElement() else { return }
        playerGrid[row][col] = puzzle.solution[row][col]
        checkCompletion()
    }

    private func checkCompletion() {
        guard let puzzle else { return }
        let isComplete = playerGrid == puzzle.solution.map { row in row.map { Optional($0) } }
        guard isComplete else { return }

        if session.elapsedPlayTime() >= roundDuration {
            session.finish(hits: hits, misses: misses, duration: session.elapsedPlayTime())
        } else {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                startPuzzle()
            }
        }
    }
}

#Preview("Hell") {
    MosaicBedGameView(level: .sencha)
        .preferredColorScheme(.light)
}
