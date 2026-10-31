import SwiftUI

/// Haupt-Navigation der App: vier Bereiche in einer `TabView`.
/// `.sidebarAdaptable` zeigt auf dem iPhone eine Tab-Leiste, auf dem iPad eine
/// Seitenleiste (design/designsystem-README.md, Abschnitt "iPad").
/// Jeder Tab zeigt vorerst nur einen Platzhalter-Screen; die echten Inhalte
/// folgen in späteren Blöcken.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab(String(localized: "tab.garden.title", defaultValue: "Garten"), systemImage: "leaf.fill") {
                GardenHomeView()
            }
            .accessibilityIdentifier("tab.garden")
            Tab(String(localized: "tab.games.title", defaultValue: "Spiele"), systemImage: "gamecontroller.fill") {
                GamesLibraryView()
            }
            .accessibilityIdentifier("tab.games")
            Tab(String(localized: "tab.history.title", defaultValue: "Verlauf"), systemImage: "clock.arrow.circlepath") {
                HistoryPlaceholderView()
            }
            .accessibilityIdentifier("tab.history")
            Tab(String(localized: "tab.profile.title", defaultValue: "Profil"), systemImage: "person.crop.circle.fill") {
                ProfilePlaceholderView()
            }
            .accessibilityIdentifier("tab.profile")
        }
        .tabViewStyle(.sidebarAdaptable)
        // designsystem-README.md ("Farben"): "Primär: matcha-600 ... Auch
        // für ... aktiven Tab." Ohne dieses `.tint` faerbt SwiftUI den
        // aktiven Tab mit dem System-Blau statt der Markenfarbe (gefunden
        // bei der Screenshot-Pruefung aus dem B1-Gate).
        .tint(Color("matcha-600"))
    }
}

#Preview {
    ContentView()
}
