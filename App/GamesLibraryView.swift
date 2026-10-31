// GamesLibraryView.swift
// Spiele-Tab (MASTER-PROMPT.md, Block B3 Aufgabe 4): ersetzt
// `GamesPlaceholderView`. Zeigt alle 14 Spiele aus `Games/Core/GameCatalog.swift`,
// nach Stufe gruppiert (Sencha/Oolong/Matcha-Abschnitte). Gesperrte Spiele
// (noch nicht gebaut oder erst ab einer höheren Spielerstufe, siehe
// `GameCatalog.isUnlocked(_:playerLevel:)`) zeigen einen Glas-Schloss-Chip
// analog zu `Illustration/GardenScene.swift`.
//
// Tippen auf ein freigeschaltetes Spiel öffnet dessen Spiel-View
// (Vollbild-Sheet); langes Drücken zeigt dessen Anleitung
// (`GameInstructionSheet`). Beides ist für gesperrte Spiele ohne Wirkung -
// deren Spiel-Views und Anleitungen entstehen erst in B5/B6.
//
// Tee-Stufe fuer die geoeffnete Spiel-View: die Spielerstufe aus dem
// `PlayerStore` (Block B4). Ausnahme nur im DEBUG-Build (Block B3 Aufgabe 5
// P5b): `-uitest-game-level` hat Vorrang und erlaubt UI-Tests, denselben
// Durchlauf auch für Oolong/Matcha zu prüfen. Der Release-Build hat diese
// Verzweigung nie, da `LaunchConfiguration` komplett unter `#if DEBUG` liegt.
//
// Freies Spielen zählt NICHT als Teepause: Ergebnisse werden gespeichert
// (`recordGameResult`), aber `completeTeaBreak()` wird hier nie aufgerufen.

import SwiftUI

struct GamesLibraryView: View {
    @Environment(PlayerStore.self) private var playerStore
    @State private var selectedGame: GameCatalogEntry?
    @State private var instructionEntry: GameCatalogEntry?

    /// Spaltenbreite auf dem iPad: adaptiv, begrenzt durch `Size.readingMax`
    /// als Richtwert fuer die maximale Spaltenbreite (Auftrag, Aufgabe 2).
    private let columns = [GridItem(.adaptive(minimum: 160, maximum: Size.readingMax), spacing: Space.space4)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.space8) {
                section(for: .sencha)
                section(for: .oolong)
                section(for: .matcha)
            }
            .padding(Space.space6)
        }
        .background(Color("bg-garden"))
        .fullScreenCover(item: $selectedGame) { entry in
            GameViewFactory.view(
                for: entry.id,
                level: resolvedGameLevel,
                onResult: { playerStore.recordGameResult(gameID: entry.id, result: $0) },
                onFinished: { selectedGame = nil }
            )
        }
        .sheet(item: $instructionEntry) { entry in
            GameInstructionSheet(
                pages: entry.instructionPages,
                hasTrialRound: entry.hasTrialRound,
                onSkip: { instructionEntry = nil },
                onFinish: { instructionEntry = nil }
            )
        }
    }

    private func section(for level: TeaLevel) -> some View {
        let games = GameCatalog.games(for: level)
        return VStack(alignment: .leading, spacing: Space.space4) {
            Text(sectionTitle(for: level))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))

            LazyVGrid(columns: columns, spacing: Space.space4) {
                ForEach(games) { entry in
                    gameTile(entry)
                }
            }
        }
    }

    private func sectionTitle(for level: TeaLevel) -> String {
        switch level {
        case .sencha:
            String(localized: "games.section.sencha", defaultValue: "Sencha")
        case .oolong:
            String(localized: "games.section.oolong", defaultValue: "Oolong")
        case .matcha:
            String(localized: "games.section.matcha", defaultValue: "Matcha")
        }
    }

    private func gameTile(_ entry: GameCatalogEntry) -> some View {
        Button {
            guard isUnlocked(entry) else { return }
            selectedGame = entry
        } label: {
            tileContent(entry)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked(entry))
        .onLongPressGesture(minimumDuration: 0.5) {
            guard isUnlocked(entry) else { return }
            instructionEntry = entry
        }
        .accessibilityLabel(Text(LocalizedStringKey(entry.nameKey)))
        .accessibilityHint(
            isUnlocked(entry)
                ? ""
                : String(localized: "games.locked.hint", defaultValue: "Noch gesperrt")
        )
    }

    private func tileContent(_ entry: GameCatalogEntry) -> some View {
        GlassCard(radius: Radius.radiusLg) {
            VStack(spacing: Space.space2) {
                Image(systemName: entry.area.symbolName)
                    .font(.system(size: Size.iconHeader, weight: .medium))
                    .foregroundStyle(Color("ink"))
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(entry.nameKey))
                    .font(.mmCallout)
                    .foregroundStyle(Color("ink"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(isUnlocked(entry) ? 1 : 0.45)
        .overlay {
            if !isUnlocked(entry) {
                lockChip(lockText(for: entry))
            }
        }
    }

    private func lockChip(_ text: String) -> some View {
        GlassCard(radius: Radius.radiusLg, padding: Space.space2) {
            HStack(spacing: Space.space1) {
                Image(systemName: "lock.fill")
                    .font(.system(size: Size.iconHelp, weight: .medium))
                    .foregroundStyle(Color("text"))
                    .accessibilityHidden(true)
                Text(text)
                    .font(.mmLabel)
                    .foregroundStyle(Color("text"))
            }
        }
    }

    private func isUnlocked(_ entry: GameCatalogEntry) -> Bool {
        GameCatalog.isUnlocked(entry, playerLevel: playerStore.level)
    }

    /// Text des Schloss-Chips: "ab Oolong/Matcha", solange die Spielerstufe
    /// noch darunter liegt; ist die Stufe erreicht, das Spiel aber noch nicht
    /// gebaut, "Kommt bald".
    private func lockText(for entry: GameCatalogEntry) -> String {
        if entry.minLevel > playerStore.level, let label = entry.lockLabel {
            return label.text
        }
        return String(localized: "game.locked.soon", defaultValue: "Kommt bald")
    }

    /// Siehe Datei-Kommentar oben: die Spielerstufe, außer ein UI-Test
    /// überschreibt sie im DEBUG-Build explizit über `-uitest-game-level`.
    private var resolvedGameLevel: TeaLevel {
        #if DEBUG
        LaunchConfiguration.fromProcessArguments().gameLevel ?? playerStore.level
        #else
        playerStore.level
        #endif
    }
}

#Preview("Hell") {
    GamesLibraryView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GamesLibraryView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
