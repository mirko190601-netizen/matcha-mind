// HistoryView.swift
// Verlauf (MASTER-PROMPT.md, Block B4 Aufgabe 8): die letzten sechs Wochen
// als Blaetter (gefuellt = aktiver Tag, Umriss = ruhiger Tag; die Form, nicht
// nur die Farbe, unterscheidet) und die Treffer je Bereich der letzten vier
// Wochen. Kein Rang, kein Streak, kein Rot. Gerechnet wird im `PlayerStore`.

import SwiftUI

struct HistoryView: View {
    @Environment(PlayerStore.self) private var playerStore

    var body: some View {
        let weeks = playerStore.historyWeeks
        let accuracy = playerStore.areaAccuracy
        return ScrollView {
            VStack(alignment: .leading, spacing: Space.space6) {
                Text(String(localized: "tab.history.title", defaultValue: "Verlauf"))
                    .font(.mmTitle)
                    .foregroundStyle(Color("ink"))
                    .accessibilityAddTraits(.isHeader)

                weeksSection(weeks)
                accuracySection(accuracy)
            }
            .frame(maxWidth: Size.readingMax, alignment: .leading)
            .padding(Space.space6)
            .frame(maxWidth: .infinity)
        }
        .background(Color("bg-tea"))
    }

    // MARK: - Wochen

    private func weeksSection(_ weeks: [HistoryWeek]) -> some View {
        VStack(alignment: .leading, spacing: Space.space3) {
            Text(String(localized: "history.weeks.title", defaultValue: "Deine letzten Wochen"))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                weekCard(week, index: index)
            }
        }
    }

    private func weekCard(_ week: HistoryWeek, index: Int) -> some View {
        let label = Self.weekStartText(week)
        let sentence = Self.accessibilitySentence(weekStart: label, activeCount: week.activeCount)
        return GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            VStack(alignment: .leading, spacing: Space.space2) {
                Text(label)
                    .font(.mmCaption)
                    .foregroundStyle(Color("text-muted"))
                HStack(spacing: Space.space3) {
                    ForEach(Array(week.activeStates.enumerated()), id: \.offset) { _, active in
                        Image(systemName: active ? "leaf.fill" : "leaf")
                            .font(.system(size: Size.iconHeader, weight: .medium))
                            .foregroundStyle(Color(active ? "matcha-600" : "text-muted"))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence)
        .accessibilityIdentifier("history.week.\(index)")
    }

    // MARK: - Bereiche

    private func accuracySection(_ accuracy: [AreaAccuracy]) -> some View {
        VStack(alignment: .leading, spacing: Space.space3) {
            Text(String(localized: "history.accuracy.title", defaultValue: "Treffer nach Bereich"))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))
            if accuracy.isEmpty {
                Text(String(localized: "history.empty.body", defaultValue: "Hier wächst dein Verlauf, sobald du gespielt hast."))
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))
                    .accessibilityIdentifier("history.empty")
            } else {
                Text(String(localized: "history.accuracy.caption", defaultValue: "Die letzten 4 Wochen"))
                    .font(.mmCaption)
                    .foregroundStyle(Color("text-muted"))
                ForEach(accuracy, id: \.area) { item in
                    accuracyRow(item)
                }
            }
        }
    }

    private func accuracyRow(_ item: AreaAccuracy) -> some View {
        let name = item.area.displayName
        return GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            VStack(alignment: .leading, spacing: Space.space2) {
                HStack(spacing: Space.space3) {
                    Image(systemName: item.area.symbolName)
                        .font(.system(size: Size.iconHeader, weight: .medium))
                        .foregroundStyle(Color("matcha-600"))
                        .accessibilityHidden(true)
                    Text(name)
                        .font(.mmCallout)
                        .foregroundStyle(Color("ink"))
                    Spacer()
                    Text(Self.percentText(item.percent))
                        .font(.mmCallout)
                        .foregroundStyle(Color("text"))
                }
                ProgressView(value: Double(item.percent), total: 100)
                    .tint(Color("matcha-600"))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.percentSentence(name: name, percent: item.percent))
        .accessibilityIdentifier("history.accuracy.\(item.area.rawValue)")
    }

    // MARK: - Texte

    /// "Woche ab 3. Nov." (lokalisiertes Datum des Montags).
    static func weekStartText(_ week: HistoryWeek, calendar: Calendar = .autoupdatingCurrent) -> String {
        guard let first = week.dayKeys.first, let date = DayKey.date(from: first, calendar: calendar) else {
            return week.weekKey
        }
        let dateText = date.formatted(.dateTime.day().month(.abbreviated))
        return String(
            format: String(localized: "history.week.label", defaultValue: "Woche ab %@"),
            dateText
        )
    }

    /// Ein Satz je Woche fuer VoiceOver, ohne Zaehler-Druck.
    static func accessibilitySentence(weekStart: String, activeCount: Int) -> String {
        if activeCount == 0 {
            return String(
                format: String(localized: "history.week.a11y.quiet", defaultValue: "%@: eine ruhige Woche"),
                weekStart
            )
        }
        return String(
            format: String(localized: "history.week.a11y.active", defaultValue: "%@: Tage mit Teepause: %lld"),
            weekStart,
            activeCount
        )
    }

    static func percentText(_ percent: Int) -> String {
        String(format: String(localized: "history.percent", defaultValue: "%lld %%"), percent)
    }

    static func percentSentence(name: String, percent: Int) -> String {
        String(
            format: String(localized: "history.accuracy.a11y", defaultValue: "%@: %lld Prozent Treffer"),
            name,
            percent
        )
    }
}

extension GameArea {
    /// Anzeigename des Bereichs.
    var displayName: String {
        switch self {
        case .spatialMemory: String(localized: "area.spatialMemory", defaultValue: "Räumliches Gedächtnis")
        case .focus: String(localized: "area.focus", defaultValue: "Aufmerksamkeit")
        case .logic: String(localized: "area.logic", defaultValue: "Logik")
        case .flexibility: String(localized: "area.flexibility", defaultValue: "Flexibilität")
        case .mentalMath: String(localized: "area.mentalMath", defaultValue: "Kopfrechnen")
        case .workingMemory: String(localized: "area.workingMemory", defaultValue: "Arbeitsgedächtnis")
        case .impulseControl: String(localized: "area.impulseControl", defaultValue: "Impulskontrolle")
        case .spatialReasoning: String(localized: "area.spatialReasoning", defaultValue: "Räumliches Denken")
        case .planning: String(localized: "area.planning", defaultValue: "Planen")
        case .language: String(localized: "area.language", defaultValue: "Sprache")
        case .dualWorkingMemory: String(localized: "area.dualWorkingMemory", defaultValue: "Doppeltes Merken")
        case .reasoning: String(localized: "area.reasoning", defaultValue: "Schlussfolgern")
        case .dividedAttention: String(localized: "area.dividedAttention", defaultValue: "Geteilte Aufmerksamkeit")
        case .patternRecognition: String(localized: "area.patternRecognition", defaultValue: "Muster erkennen")
        }
    }
}

#Preview("Hell") {
    HistoryView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    HistoryView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
