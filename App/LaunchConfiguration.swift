import Foundation
import SwiftUI

// Sicherheitsvorgabe aus MASTER-PROMPT.md Abschnitt 7.5 ("Testzugänge nur in
// DEBUG"): dieser gesamte Datei-Inhalt wird im Release-Build nicht
// kompiliert. `scripts/check_debug_only.py` prüft das automatisch.
#if DEBUG

/// Liest UI-Test-Startargumente, die ein UI-Test-Runner beim App-Start
/// übergibt (siehe `MASTER-PROMPT.md`, Block B1 Aufgabe 7 und B9 Aufgabe 2
/// "3 simulierte Spieler").
///
/// Erwartete Argumente:
/// - `-uitest-persona <id>`: Kennung der Persona, z. B. `"lena"`, `"tom"`,
///   `"claire"`. Die Personas selbst (ihre Daten, Sprache, Darstellung)
///   werden erst in B9 gebaut - hier steht nur die Infrastruktur, die ihr
///   Startargument liest.
/// - `-uitest-date <ISO8601>`: das simulierte Startdatum, z. B.
///   `"2026-01-15T08:00:00Z"`.
/// - `-uitest-appearance <light|dark>`: erzwingt das Farbschema für
///   Screenshot-Erzeugung im UI-Test (Gate-Punkt aus MASTER-PROMPT.md
///   Block B1: "Screenshots hell + dunkel geprüft"). Ohne dieses Argument
///   bleibt das Systemverhalten unverändert (kein Unterschied zum
///   Release-Build).
/// - `-uitest-game-level <sencha|oolong|matcha>`: überschreibt in
///   `App/GamesLibraryView.swift` die Tee-Stufe, mit der eine Spiel-View
///   geöffnet wird (Block B3 Aufgabe 5 P5b: "Start-bis-Ergebnis-Durchlauf
///   für alle 3 Stufen"). Echte Spielerstufen kommen erst in Block B4 -
///   ohne dieses Argument bleibt es bei `.sencha`, wie im Release-Build.
struct LaunchConfiguration {
    let personaID: String?
    let clock: FixedClock?
    let colorScheme: ColorScheme?
    let gameLevel: TeaLevel?

    /// Liest die Argumente aus `ProcessInfo.processInfo.arguments`.
    static func fromProcessArguments() -> LaunchConfiguration {
        makeConfiguration(arguments: ProcessInfo.processInfo.arguments)
    }

    /// Testbare Variante: parst eine explizit übergebene Argumentliste,
    /// ohne auf den echten Prozess zuzugreifen.
    static func makeConfiguration(arguments: [String]) -> LaunchConfiguration {
        let personaID = value(after: "-uitest-persona", in: arguments)
        let dateString = value(after: "-uitest-date", in: arguments)
        let appearance = value(after: "-uitest-appearance", in: arguments)
        let gameLevelString = value(after: "-uitest-game-level", in: arguments)

        let clock: FixedClock? = dateString
            .flatMap { ISO8601DateFormatter().date(from: $0) }
            .map { FixedClock(date: $0) }

        let colorScheme: ColorScheme?
        switch appearance {
        case "light":
            colorScheme = .light
        case "dark":
            colorScheme = .dark
        default:
            colorScheme = nil
        }

        let gameLevel: TeaLevel?
        switch gameLevelString {
        case "sencha":
            gameLevel = .sencha
        case "oolong":
            gameLevel = .oolong
        case "matcha":
            gameLevel = .matcha
        default:
            gameLevel = nil
        }

        return LaunchConfiguration(personaID: personaID, clock: clock, colorScheme: colorScheme, gameLevel: gameLevel)
    }

    /// Liefert den Wert, der unmittelbar nach `flag` in `arguments` steht,
    /// oder `nil`, wenn das Flag fehlt oder keinen Folgewert hat.
    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard
            let flagIndex = arguments.firstIndex(of: flag),
            arguments.index(after: flagIndex) < arguments.endIndex
        else {
            return nil
        }
        return arguments[arguments.index(after: flagIndex)]
    }
}

#endif
