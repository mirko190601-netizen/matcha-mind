import SwiftData
import SwiftUI

@main
struct MatchaMindApp: App {
    private let appEnvironment: AppEnvironment
    private let playerStore: PlayerStore
    private let reminderCoordinator: ReminderCoordinator

    @Environment(\.scenePhase) private var scenePhase

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
        GameHaptics.backing = store

        // Erinnerungen: ohne Erststart (UI-Tests) nichts beim System eintragen.
        let calendar = Calendar.autoupdatingCurrent
        let scheduler: any NotificationScheduling
        if appEnvironment.showsOnboarding {
            scheduler = SystemNotificationScheduler(calendar: calendar)
        } else {
            scheduler = NoopNotificationScheduler()
        }
        reminderCoordinator = ReminderCoordinator(
            store: store,
            scheduler: scheduler,
            clock: appEnvironment.clock,
            calendar: calendar
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, appEnvironment)
                .environment(\.reminderCoordinator, reminderCoordinator)
                .environment(playerStore)
                // `colorScheme` ist nur in UI-Tests mit `-uitest-appearance`
                // gesetzt (siehe `LaunchConfiguration`/`AppEnvironment`).
                // `nil` lässt `.preferredColorScheme` unverändert das
                // Systemverhalten greifen - kein Unterschied zum
                // Release-Build.
                .preferredColorScheme(appEnvironment.colorScheme)
                // Erinnerungen neu planen: beim Start und jedes Mal, wenn
                // die App wieder aktiv wird.
                .task { await reminderCoordinator.reschedule() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await reminderCoordinator.reschedule() }
                    }
                }
        }
    }
}
