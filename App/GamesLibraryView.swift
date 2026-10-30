// GamesLibraryView.swift
// Spiele-Tab (MASTER-PROMPT.md, Block B3 Aufgabe 4): ersetzt
// `GamesPlaceholderView`. Zeigt alle 14 Spiele aus `Games/Core/GameCatalog.swift`,
// nach Stufe gruppiert (Sencha/Oolong/Matcha-Abschnitte). Gesperrte Spiele
// (alles außer den 5 Sencha-Spielen, siehe `GameCatalogEntry.isUnlocked`)
// zeigen einen Glas-Schloss-Chip analog zu `Illustration/GardenScene.swift`.
//
// Tippen auf ein freigeschaltetes Spiel öffnet dessen Spiel-View
// (Vollbild-Sheet); langes Drücken zeigt dessen Anleitung
// (`GameInstructionSheet`). Beides ist für gesperrte Spiele ohne Wirkung -
// deren Spiel-Views und Anleitungen entstehen erst in B5/B6.
//
// Aktuelle Tee-Stufe fuer die geoeffnete Spiel-View: in diesem Block (B3)
// gibt es noch keine echte Spielerstufe (kommt erst in B4), daher wird fest
// `.sencha` übergeben - das einzige, was ohnehin spielbar ist. Ausnahme nur
// im DEBUG-Build (Block B3 Aufgabe 5 P5b): `-uitest-game-level` erlaubt UI-
// Tests, denselben Durchlauf auch für Oolong/Matcha zu prüfen. Der
// Release-Build hat diese Verzweigung nie, da `LaunchConfiguration`
// komplett unter `#if DEBUG` liegt - deshalb braucht `resolvedGameLevel`
// selbst eine `#if DEBUG`/`#else`-Verzweigung.

import SwiftUI

struct GamesLibraryView: View {
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
            gameView(for: entry)
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
            guard entry.isUnlocked else { return }
            selectedGame = entry
        } label: {
            tileContent(entry)
        }
        .buttonStyle(.plain)
        .disabled(!entry.isUnlocked)
        .onLongPressGesture(minimumDuration: 0.5) {
            guard entry.isUnlocked else { return }
            instructionEntry = entry
        }
        .accessibilityLabel(Text(LocalizedStringKey(entry.nameKey)))
        .accessibilityHint(
            entry.isUnlocked
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
        .opacity(entry.isUnlocked ? 1 : 0.45)
        .overlay {
            if !entry.isUnlocked, let lockLabel = entry.lockLabel {
                lockChip(lockLabel)
            }
        }
    }

    private func lockChip(_ label: GameLockLabel) -> some View {
        GlassCard(radius: Radius.radiusLg, padding: Space.space2) {
            HStack(spacing: Space.space1) {
                Image(systemName: "lock.fill")
                    .font(.system(size: Size.iconHelp, weight: .medium))
                    .foregroundStyle(Color("text"))
                    .accessibilityHidden(true)
                Text(label.text)
                    .font(.mmLabel)
                    .foregroundStyle(Color("text"))
            }
        }
    }

    @ViewBuilder
    private func gameView(for entry: GameCatalogEntry) -> some View {
        switch entry.id {
        case TeapotRowGame().id:
            TeapotRowGameView(level: resolvedGameLevel, onFinished: { selectedGame = nil })
        case FireflyPondGame().id:
            FireflyPondGameView(level: resolvedGameLevel, onFinished: { selectedGame = nil })
        case MosaicBedGame().id:
            MosaicBedGameView(level: resolvedGameLevel, onFinished: { selectedGame = nil })
        case TeaLeafSortGame().id:
            TeaLeafSortGameView(level: resolvedGameLevel, onFinished: { selectedGame = nil })
        case BambooMathGame().id:
            BambooMathGameView(level: resolvedGameLevel, onFinished: { selectedGame = nil })
        default:
            // Platzhalter-Spiele sind gesperrt (siehe `isUnlocked`) und
            // oeffnen daher nie eine Spiel-View - dieser Zweig ist nur zur
            // Erschoepfung des Switches vorhanden.
            EmptyView()
        }
    }

    /// Siehe Datei-Kommentar oben: `.sencha`, außer ein UI-Test überschreibt
    /// das im DEBUG-Build explizit über `-uitest-game-level`.
    private var resolvedGameLevel: TeaLevel {
        #if DEBUG
        LaunchConfiguration.fromProcessArguments().gameLevel ?? .sencha
        #else
        .sencha
        #endif
    }
}

#Preview("Hell") {
    GamesLibraryView()
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GamesLibraryView()
        .preferredColorScheme(.dark)
}
