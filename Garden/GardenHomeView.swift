// GardenHomeView.swift
// Garten-Startseite (MASTER-PROMPT.md, Block B4 Aufgabe 4.6): ersetzt den
// frueheren Platzhalter. Szene mit Bereichen nach hoechster Stufe, Wachstum
// nach verdientem Tau, gekaufter Deko und Bonus-Blueten; dazu Tau-Anzeige,
// Wochenziel (ruhige Blaetter, ohne Zahlen-Druck), Teepause-Einstieg und
// Zugang zum Deko-Shop.

import SwiftUI

struct GardenHomeView: View {
    @Environment(PlayerStore.self) private var playerStore
    @State private var showTeaBreak = false
    @State private var showShop = false

    var body: some View {
        ScrollView {
            VStack(spacing: Space.space4) {
                HStack {
                    DewChip(amount: playerStore.dewDrops)
                    Spacer()
                    GlassButton(
                        String(localized: "garden.shop.open", defaultValue: "Deko-Shop"),
                        systemImage: "sparkles"
                    ) { showShop = true }
                        .accessibilityIdentifier("garden.shop.open")
                }

                teaBreakEntry

                GardenScene(
                    oolongUnlocked: playerStore.highestLevel >= .oolong,
                    matchaUnlocked: playerStore.highestLevel >= .matcha,
                    growthStage: GardenGrowth.stage(dewEarnedTotal: playerStore.dewEarnedTotal),
                    decorationIDs: playerStore.ownedDecorationIDs,
                    bonusBlossoms: playerStore.bonusBlossomCount
                )
                .aspectRatio(0.9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Radius.radiusXl))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("garden.scene")

                weeklyGoal
            }
            .padding(Space.space4)
            .frame(maxWidth: Size.readingMax * 1.5)
            .frame(maxWidth: .infinity)
        }
        .background(Color("bg-garden"))
        .fullScreenCover(isPresented: $showTeaBreak) {
            TeaBreakView(onClose: { showTeaBreak = false })
        }
        .sheet(isPresented: $showShop) {
            DecorationShopView(onClose: { showShop = false })
        }
    }

    // MARK: - Wochenziel

    private var weeklyGoal: some View {
        let states = playerStore.weekActiveDayStates
        let active = playerStore.activeDaysThisWeek
        let summary = String(
            format: String(localized: "garden.week.a11y", defaultValue: "%lld von %lld Teepausen diese Woche"),
            active, playerStore.weeklyGoalDays
        )
        return GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            VStack(spacing: Space.space2) {
                Text(String(localized: "garden.week.title", defaultValue: "Diese Woche"))
                    .font(.mmHeadline)
                    .foregroundStyle(Color("ink"))
                HStack(spacing: Space.space3) {
                    ForEach(Array(states.enumerated()), id: \.offset) { _, isActive in
                        Image(systemName: isActive ? "leaf.fill" : "leaf")
                            .font(.system(size: Size.iconHeader, weight: .medium))
                            .foregroundStyle(isActive ? Color("matcha-600") : Color("text-muted"))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(summary)
                .accessibilityIdentifier("garden.week")
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Teepause

    private var teaBreakDoneText: String {
        String(localized: "garden.teabreak.done", defaultValue: "Deine Teepause für heute ist getrunken. Im Spiele-Tab kannst du frei weiterspielen.")
    }

    @ViewBuilder
    private var teaBreakEntry: some View {
        if playerStore.isTeaBreakCompletedToday {
            Text(teaBreakDoneText)
                .font(.mmBody)
                .foregroundStyle(Color("text"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: Size.readingMax)
        } else {
            PrimaryButton(String(localized: "garden.teabreak.start", defaultValue: "Teepause starten")) {
                showTeaBreak = true
            }
            .accessibilityIdentifier("teabreak.start")
            .frame(maxWidth: Size.readingMax)
        }
    }
}

#Preview("Hell") {
    GardenHomeView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GardenHomeView()
        .environment(PlayerStore.preview(level: .matcha))
        .preferredColorScheme(.dark)
}
