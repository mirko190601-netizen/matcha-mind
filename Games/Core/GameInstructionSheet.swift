// GameInstructionSheet.swift
// Komponente "Spielanleitung" aus design/designsystem-README.md
// ("Komponenten"): Sheet `.large`, bis 3 Seiten, Seitenpunkte,
// "Ueberspringen", letzte Seite "Los geht's" bzw. "Proberunde starten"
// (je nach `GameDefinition.hasTrialRound`). Oeffnet automatisch beim
// ersten Start eines Spiels (Aufruf-Logik liegt beim jeweiligen Spiel,
// kommt in Block B3 Aufgabe 2).

import SwiftUI

/// Eine Seite der Spielanleitung. Titel und Text kommen als
/// String-Katalog-Schluessel, damit jedes Spiel seine eigenen Texte
/// liefert, ohne dass der Baukasten sie kennen muss.
public struct GameInstructionPage: Identifiable, Sendable {
    public let id: Int
    public let titleKey: String
    public let bodyKey: String

    public init(id: Int, titleKey: String, bodyKey: String) {
        self.id = id
        self.titleKey = titleKey
        self.bodyKey = bodyKey
    }
}

/// Spielanleitungs-Fenster: bis zu 3 Seiten mit Seitenpunkten, die man
/// wischen kann, ein "Ueberspringen"-Button und ein Haupt-Button, der auf
/// der letzten Seite je nach Proberunde "Los geht's" oder "Proberunde
/// starten" zeigt.
public struct GameInstructionSheet: View {
    private let pages: [GameInstructionPage]
    private let hasTrialRound: Bool
    private let onSkip: () -> Void
    private let onFinish: () -> Void

    @State private var currentPageIndex = 0

    /// - Parameters:
    ///   - pages: 1-3 Seiten (siehe `GameDefinition.instructionPageCount`).
    ///   - hasTrialRound: steuert den Text des letzten Haupt-Buttons.
    ///   - onSkip: Aufruf bei "Ueberspringen".
    ///   - onFinish: Aufruf, wenn die letzte Seite bestaetigt wird.
    public init(
        pages: [GameInstructionPage],
        hasTrialRound: Bool,
        onSkip: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.pages = pages
        self.hasTrialRound = hasTrialRound
        self.onSkip = onSkip
        self.onFinish = onFinish
    }

    private var isLastPage: Bool {
        currentPageIndex >= pages.count - 1
    }

    private var mainButtonTitle: String {
        guard isLastPage else {
            return String(localized: "game.instruction.next", defaultValue: "Weiter")
        }
        return hasTrialRound
            ? String(localized: "game.instruction.startTrial", defaultValue: "Proberunde starten")
            : String(localized: "game.instruction.start", defaultValue: "Los geht's")
    }

    public var body: some View {
        VStack(spacing: Space.space4) {
            HStack {
                Spacer()
                GlassButton(String(localized: "game.instruction.skip", defaultValue: "Überspringen"), action: onSkip)
            }

            TabView(selection: $currentPageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(alignment: .leading, spacing: Space.space3) {
                        Text(LocalizedStringKey(page.titleKey))
                            .font(.mmHeadline)
                            .foregroundStyle(Color("ink"))
                        Text(LocalizedStringKey(page.bodyKey))
                            .font(.mmBody)
                            .foregroundStyle(Color("text"))
                        Spacer()
                    }
                    .padding(.horizontal, Space.space6)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .always : .never))

            PrimaryButton(mainButtonTitle) {
                if isLastPage {
                    onFinish()
                } else {
                    currentPageIndex += 1
                }
            }
            .padding(.horizontal, Space.space6)
        }
        .padding(.vertical, Space.space4)
        .background(Color("bg-tea"))
        .presentationDetents([.large])
    }
}

#Preview("Hell") {
    GameInstructionSheet(
        pages: [
            GameInstructionPage(
                id: 0,
                titleKey: "preview.instruction.title",
                bodyKey: "preview.instruction.body"
            )
        ],
        hasTrialRound: true,
        onSkip: {},
        onFinish: {}
    )
    .preferredColorScheme(.light)
}
