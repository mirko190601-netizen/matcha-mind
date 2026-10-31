// LevelSettingsView.swift
// Stufen-Screen (MASTER-PROMPT.md, Block B4 Aufgabe 2): die drei Tee-Stufen
// zum Waehlen, dazu der Schalter fuer den automatischen Aufstieg. Eine
// manuelle Wahl gilt sofort fuer neue Runden (`PlayerStore.setLevel`).

import SwiftUI

struct LevelSettingsView: View {
    @Environment(PlayerStore.self) private var playerStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.space6) {
                Text(String(localized: "level.hint", defaultValue: "Du kannst die Stufe jederzeit selbst wählen."))
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))

                VStack(spacing: Space.space3) {
                    ForEach(TeaLevel.allCases, id: \.self) { level in
                        levelCard(level)
                    }
                }

                GlassCard(radius: Radius.radiusLg) {
                    VStack(alignment: .leading, spacing: Space.space2) {
                        Toggle(isOn: autoAdvanceBinding) {
                            Text(String(localized: "level.auto.toggle", defaultValue: "Automatisch aufsteigen"))
                                .font(.mmCallout)
                                .foregroundStyle(Color("ink"))
                        }
                        .tint(Color("matcha-600"))
                        .accessibilityIdentifier("level.auto")
                        Text(autoAdvanceHint)
                            .font(.mmCaption)
                            .foregroundStyle(Color("text-muted"))
                    }
                }
            }
            .frame(maxWidth: Size.readingMax, alignment: .leading)
            .padding(Space.space6)
            .frame(maxWidth: .infinity)
        }
        .background(Color("bg-tea"))
        .navigationTitle(String(localized: "level.title", defaultValue: "Stufe"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var autoAdvanceBinding: Binding<Bool> {
        Binding(
            get: { playerStore.autoAdvance },
            set: { playerStore.setAutoAdvance($0) }
        )
    }

    private var autoAdvanceHint: String {
        String(localized: "level.auto.hint", defaultValue: "Wenn du dich eingespielt hast, schlagen wir dir die nächste Stufe vor. Du entscheidest, ob du wechselst.")
    }

    private func levelCard(_ level: TeaLevel) -> some View {
        let isCurrent = playerStore.level == level
        return Button {
            playerStore.setLevel(level)
        } label: {
            GlassCard(radius: Radius.radiusLg) {
                HStack(spacing: Space.space3) {
                    VStack(alignment: .leading, spacing: Space.space1) {
                        Text(name(of: level))
                            .font(.mmCallout)
                            .foregroundStyle(Color("ink"))
                        Text(detail(of: level))
                            .font(.mmCaption)
                            .foregroundStyle(Color("text-muted"))
                    }
                    Spacer()
                    // Auswahl nicht nur per Farbe: gefuelltes Haekchen-Symbol.
                    Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: Size.iconHeader, weight: .medium))
                        .foregroundStyle(Color(isCurrent ? "matcha-600" : "text-muted"))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("level.option.\(level.rawValue)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func name(of level: TeaLevel) -> String {
        switch level {
        case .sencha:
            String(localized: "games.section.sencha", defaultValue: "Sencha")
        case .oolong:
            String(localized: "games.section.oolong", defaultValue: "Oolong")
        case .matcha:
            String(localized: "games.section.matcha", defaultValue: "Matcha")
        }
    }

    private func detail(of level: TeaLevel) -> String {
        switch level {
        case .sencha:
            String(localized: "level.sencha.detail", defaultValue: "Ein sanfter Einstieg")
        case .oolong:
            String(localized: "level.oolong.detail", defaultValue: "Etwas mehr Abwechslung")
        case .matcha:
            String(localized: "level.matcha.detail", defaultValue: "Für alle, die es gern tiefer mögen")
        }
    }
}

#Preview("Hell") {
    NavigationStack {
        LevelSettingsView()
    }
    .environment(PlayerStore.preview())
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    NavigationStack {
        LevelSettingsView()
    }
    .environment(PlayerStore.preview())
    .preferredColorScheme(.dark)
}
