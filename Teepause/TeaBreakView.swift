// TeaBreakView.swift
// Teepause (MASTER-PROMPT.md, Block B4 Aufgabe 3): Vollbild-Ablauf aus
// Uebersicht -> drei Spiele nacheinander -> Abschluss im Garten. Die drei
// Spiele waehlt `TeaBreakPlanner`; ihre Ergebnisse gehen an den
// `PlayerStore`. Beim Eintritt in den Abschluss wird die Teepause genau einmal
// als erledigt gezaehlt; liefert das ein Aufstiegsangebot, erscheint der
// Aufstiegs-Moment (`PromotionMomentView`).

import SwiftUI

struct TeaBreakView: View {
    @Environment(PlayerStore.self) private var playerStore

    /// Schliesst die Teepause (Rueckkehr in den Garten).
    let onClose: () -> Void

    private enum Phase: Equatable {
        case overview
        case playing(Int)
        case finished
    }

    @State private var phase: Phase = .overview
    @State private var plannedGameIDs: [String] = []
    @State private var didCompleteTeaBreak = false
    @State private var offeredPromotion: TeaLevel?
    @State private var showPromotion = false

    var body: some View {
        ZStack {
            Color("bg-tea").ignoresSafeArea()

            switch phase {
            case .overview:
                overview
            case .playing(let index):
                playing(at: index)
            case .finished:
                finished
            }
        }
        .onAppear {
            if plannedGameIDs.isEmpty {
                plannedGameIDs = makePlan()
            }
        }
        .sheet(isPresented: $showPromotion) {
            if let target = offeredPromotion {
                PromotionMomentView(target: target, onDone: { showPromotion = false })
            }
        }
    }

    // MARK: - Uebersicht

    private var overview: some View {
        VStack(spacing: Space.space6) {
            Spacer()
            VStack(spacing: Space.space2) {
                Text(String(localized: "teabreak.overview.title", defaultValue: "Deine Teepause"))
                    .font(.mmTitle)
                    .foregroundStyle(Color("ink"))
                Text(String(localized: "teabreak.overview.body", defaultValue: "Drei kurze Spiele, ganz in deinem Tempo."))
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Space.space3) {
                ForEach(plannedGameIDs, id: \.self) { gameID in
                    gameCard(for: gameID)
                }
            }

            Spacer()

            VStack(spacing: Space.space3) {
                PrimaryButton(String(localized: "teabreak.overview.start", defaultValue: "Los geht's")) {
                    guard !plannedGameIDs.isEmpty else { return }
                    phase = .playing(0)
                }
                .accessibilityIdentifier("teabreak.go")
                GlassButton(String(localized: "teabreak.overview.later", defaultValue: "Später")) {
                    onClose()
                }
                .accessibilityIdentifier("teabreak.later")
            }
        }
        .frame(maxWidth: Size.readingMax)
        .padding(Space.space6)
    }

    @ViewBuilder
    private func gameCard(for gameID: String) -> some View {
        if let entry = GameCatalog.allGames.first(where: { $0.id == gameID }) {
            GlassCard(radius: Radius.radiusLg) {
                HStack(spacing: Space.space3) {
                    Image(systemName: entry.area.symbolName)
                        .font(.system(size: Size.iconHeader, weight: .medium))
                        .foregroundStyle(Color("ink"))
                        .accessibilityHidden(true)
                    Text(LocalizedStringKey(entry.nameKey))
                        .font(.mmCallout)
                        .foregroundStyle(Color("ink"))
                    Spacer()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("teabreak.card")
        }
    }

    // MARK: - Spielen

    @ViewBuilder
    private func playing(at index: Int) -> some View {
        if plannedGameIDs.indices.contains(index) {
            let gameID = plannedGameIDs[index]
            GameViewFactory.view(
                for: gameID,
                level: playerStore.level,
                onResult: { playerStore.recordGameResult(gameID: gameID, result: $0) },
                onFinished: { advance(after: index) }
            )
            .id(gameID)
        }
    }

    private func advance(after index: Int) {
        let next = index + 1
        if plannedGameIDs.indices.contains(next) {
            phase = .playing(next)
        } else {
            enterFinished()
        }
    }

    // MARK: - Abschluss

    private var finished: some View {
        ScrollView {
            VStack(spacing: Space.space6) {
                GardenScene(
                    oolongUnlocked: playerStore.highestLevel >= .oolong,
                    matchaUnlocked: playerStore.highestLevel >= .matcha
                )
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: Radius.radiusXl))
                .accessibilityHidden(true)

                VStack(spacing: Space.space2) {
                    Text(String(localized: "teabreak.finished.title", defaultValue: "Teepause genossen"))
                        .font(.mmTitle)
                        .foregroundStyle(Color("ink"))
                    Text(String(localized: "teabreak.finished.body", defaultValue: "Dein Garten freut sich über deinen Besuch."))
                        .font(.mmBody)
                        .foregroundStyle(Color("text"))
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(String(localized: "teabreak.finished.back", defaultValue: "Zurück in den Garten")) {
                    onClose()
                }
                .accessibilityIdentifier("teabreak.back")
            }
            .frame(maxWidth: Size.readingMax)
            .padding(Space.space6)
            .frame(maxWidth: .infinity)
        }
    }

    /// Wechselt in den Abschluss und zaehlt die Teepause genau einmal.
    private func enterFinished() {
        phase = .finished
        guard !didCompleteTeaBreak else { return }
        didCompleteTeaBreak = true
        if let target = playerStore.completeTeaBreak() {
            offeredPromotion = target
            showPromotion = true
        }
    }

    // MARK: - Planung

    private func makePlan() -> [String] {
        let candidates = GameCatalog.playableGames(for: playerStore.level).map { entry in
            TeaBreakCandidate(
                gameID: entry.id,
                area: entry.area,
                lastPlayed: playerStore.lastPlayed(gameID: entry.id)
            )
        }
        var rng = SystemRandomNumberGenerator()
        return TeaBreakPlanner.plan(candidates: candidates, using: &rng)
    }
}

#Preview("Hell") {
    TeaBreakView(onClose: {})
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    TeaBreakView(onClose: {})
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
