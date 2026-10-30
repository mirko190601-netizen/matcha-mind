import SwiftUI

@main
struct MatchaMindApp: App {
    private let appEnvironment: AppEnvironment

    init() {
        // Testzugänge (UI-Test-Personas, simuliertes Datum) nur in DEBUG -
        // siehe MASTER-PROMPT.md Abschnitt 7.5. Im Release-Build existiert
        // `fromLaunchArguments()` gar nicht erst.
        #if DEBUG
        appEnvironment = .fromLaunchArguments()
        #else
        appEnvironment = AppEnvironment()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appEnvironment, appEnvironment)
                // `colorScheme` ist nur in UI-Tests mit `-uitest-appearance`
                // gesetzt (siehe `LaunchConfiguration`/`AppEnvironment`).
                // `nil` lässt `.preferredColorScheme` unverändert das
                // Systemverhalten greifen - kein Unterschied zum
                // Release-Build.
                .preferredColorScheme(appEnvironment.colorScheme)
        }
    }
}
