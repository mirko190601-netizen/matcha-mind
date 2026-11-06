import SwiftUI

/// Zentrale Laufzeit-Umgebung der App: hält die aktive `AppClock` und ob
/// gerade ein UI-Test mit simulierter Persona läuft (siehe
/// `MASTER-PROMPT.md`, Block B1 Aufgabe 7 und B9 Aufgabe 2).
///
/// Entscheidung `struct` statt `@Observable`-Klasse: alle drei Werte stehen
/// beim App-Start fest und ändern sich danach nicht mehr (die *Uhrzeit*, die
/// `clock` liefert, kann sich ändern - siehe `FixedClock` -, aber *welche*
/// Clock verwendet wird, nicht). Ein unveränderlicher Wert-Typ ist
/// automatisch `Sendable`, sofern seine Felder es sind (hier erfüllt:
/// `AppClock: Sendable`, `Bool`, `String?`), und braucht daher keine
/// Actor-Isolation, um Swift 6 strict concurrency zu erfüllen. `@Observable`
/// böte hier keinen Vorteil, da kein View-Code auf Änderungen dieser Werte
/// reagieren muss.
///
/// Konkrete SwiftData-Anbindung ist NICHT Teil dieses Pakets (kommt erst in
/// B4) - `isUITesting` ist bewusst nur die Weiche, an der später zwischen
/// echter Persistenz und einem In-Memory-Speicher für Tests entschieden
/// wird.
struct AppEnvironment: Sendable {
    let clock: AppClock
    let isUITesting: Bool
    let personaID: String?
    /// Erzwungenes Farbschema für Screenshot-Erzeugung in UI-Tests (siehe
    /// `LaunchConfiguration`, Argument `-uitest-appearance`). `nil` im
    /// Release-Build und in jedem UI-Test ohne dieses Argument - dann gilt
    /// unverändert das Systemverhalten.
    let colorScheme: ColorScheme?
    /// Ob der Erststart (Begrüßung, Uhrzeit der Erinnerung) erscheinen darf.
    /// Im Release immer `true`; in DEBUG-UI-Tests aus (siehe
    /// `fromLaunchArguments()`), damit bestehende Abläufe unverändert bleiben.
    let showsOnboarding: Bool
    #if DEBUG
    /// Feste Spiele der Teepause (nur DEBUG-UI-Tests, damit der Ablauf nicht vom
    /// Zufall abhaengt). Leer = normale Auswahl durch `TeaBreakPlanner`.
    var forcedTeaBreakGameIDs: [String] = []
    #endif

    init(
        clock: AppClock = SystemClock(),
        isUITesting: Bool = false,
        personaID: String? = nil,
        colorScheme: ColorScheme? = nil,
        showsOnboarding: Bool = true
    ) {
        self.clock = clock
        self.isUITesting = isUITesting
        self.personaID = personaID
        self.colorScheme = colorScheme
        self.showsOnboarding = showsOnboarding
    }

    #if DEBUG
    /// Baut die Umgebung aus den UI-Test-Startargumenten (nur DEBUG, siehe
    /// `LaunchConfiguration`). Ohne `-uitest-persona` verhält sich die App
    /// wie im Release: echte Systemzeit, `isUITesting == false`. Das
    /// erzwungene Farbschema (`-uitest-appearance`) ist davon unabhängig
    /// und gilt auch ohne gesetzte Persona.
    static func fromLaunchArguments() -> AppEnvironment {
        let configuration = LaunchConfiguration.fromProcessArguments()
        return make(from: configuration)
    }

    /// Testbare Variante von `fromLaunchArguments()`. Der Erststart erscheint
    /// nur ohne jedes `-uitest-*`-Argument oder mit `-uitest-show-onboarding`.
    static func make(from configuration: LaunchConfiguration) -> AppEnvironment {
        let showsOnboarding = !configuration.hasUITestArguments || configuration.showOnboarding
        guard let personaID = configuration.personaID else {
            return AppEnvironment(colorScheme: configuration.colorScheme, showsOnboarding: showsOnboarding)
        }
        var environment = AppEnvironment(
            clock: configuration.clock ?? SystemClock(),
            isUITesting: true,
            personaID: personaID,
            colorScheme: configuration.colorScheme,
            showsOnboarding: showsOnboarding
        )
        environment.forcedTeaBreakGameIDs = configuration.effectiveTeaBreakGameIDs
        return environment
    }
    #endif
}

/// `EnvironmentKey`, um `AppEnvironment` per `.environment(\.appEnvironment, ...)`
/// zu injizieren.
private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
