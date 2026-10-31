import SwiftData
import SwiftUI

@main
struct MatchaMindApp: App {
    private let appEnvironment: AppEnvironment
    private let playerStore: PlayerStore

    init() {
        // Testzugänge (UI-Test-Personas, simuliertes Datum) nur in DEBUG -
        // siehe MASTER-PROMPT.md Abschnitt 7.5. Im Release-Build existiert
        // `fromLaunchArguments()` gar nicht erst.
        #if DEBUG
        appEnvironment = .fromLaunchArguments()
        #else
        appEnvironment = AppEnvironment()
        #endif

        // Spielerdaten (Block B4): in UI-Tests nur im Arbeitsspeicher, sonst
        // in der Standard-Datei. Schlägt das Öffnen der Datei fehl, läuft die
        // App mit einem flüchtigen Speicher weiter, statt abzustürzen.
        let container: ModelContainer
        do {
            container = try PlayerStore.makeContainer(inMemory: appEnvironment.isUITesting)
        } catch {
            guard let fallback = try? PlayerStore.makeContainer(inMemory: true) else {
                fatalError("Spielerdaten-Container konnte nicht angelegt werden: \(error)")
            }
            container = fallback
        }
        let store = PlayerStore(container: container, clock: appEnvironment.clock)
        playerStore = store
        GameInstructionsSeenStore.backing = store
        FineLevelStore.backing = store
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appEnvironment, appEnvironment)
                .environment(playerStore)
                // `colorScheme` ist nur in UI-Tests mit `-uitest-appearance`
                // gesetzt (siehe `LaunchConfiguration`/`AppEnvironment`).
                // `nil` lässt `.preferredColorScheme` unverändert das
                // Systemverhalten greifen - kein Unterschied zum
                // Release-Build.
                .preferredColorScheme(appEnvironment.colorScheme)
        }
    }
}
