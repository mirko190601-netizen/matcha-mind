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
/// - `-uitest-show-onboarding`: zeigt den Erststart (Begrüßung, Uhrzeit)
///   trotz UI-Test. Sonst überspringt ihn jedes `-uitest-*`-Argument.
/// - `-uitest-seed <promotion-oolong|promotion-matcha>`: füllt den
///   In-Memory-Speicher mit einem Spielstand kurz vor dem Aufstieg (siehe
///   `Progress/UITestSeed.swift`). Wirkt nur zusammen mit `-uitest-persona`.
/// - `-uitest-teabreak-games <id,id,id>`: legt die Spiele der Teepause fest
///   (Kennungen aus `GameCatalog`, durch Komma getrennt), damit UI-Tests nicht
///   vom Zufall abhängen. Wirkt nur zusammen mit `-uitest-persona`.
/// - `-uitest-round-seconds <n>`: verkürzt die Rundendauer der Spiele auf n
///   Sekunden (Standard 75, siehe `Games/Core/GameRound.swift`). Wirkt nur
///   zusammen mit `-uitest-persona`.
struct LaunchConfiguration {
    let personaID: String?
    let clock: FixedClock?
    let colorScheme: ColorScheme?
    let gameLevel: TeaLevel?
    /// Mindestens ein `-uitest-*`-Argument ist gesetzt (egal welches).
    let hasUITestArguments: Bool
    /// `-uitest-show-onboarding`: der Erststart soll trotz UI-Test erscheinen.
    let showOnboarding: Bool
    /// `-uitest-seed`: gewählter Spielstand, `nil` bei fehlendem oder unbekanntem Wert.
    let seed: UITestSeed?
    /// `-uitest-teabreak-games`: feste Spiele der Teepause, leer ohne Argument.
    let teaBreakGameIDs: [String]
    /// `-uitest-round-seconds`: verkuerzte Rundendauer, `nil` ohne gueltigen Wert (> 0).
    let roundSeconds: TimeInterval?

    /// Der Spielstand gilt nur mit Persona (also nur im In-Memory-Speicher).
    var effectiveSeed: UITestSeed? { personaID == nil ? nil : seed }

    /// Die festen Teepause-Spiele gelten nur mit Persona.
    var effectiveTeaBreakGameIDs: [String] { personaID == nil ? [] : teaBreakGameIDs }

    /// Die verkuerzte Rundendauer gilt nur mit Persona.
    var effectiveRoundSeconds: TimeInterval? { personaID == nil ? nil : roundSeconds }

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
        let seed = value(after: "-uitest-seed", in: arguments).flatMap { UITestSeed(rawValue: $0) }
        let roundSeconds = value(after: "-uitest-round-seconds", in: arguments)
            .flatMap { TimeInterval($0) }
            .flatMap { $0 > 0 ? $0 : nil }
        let teaBreakGameIDs = (value(after: "-uitest-teabreak-games", in: arguments) ?? "")
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

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

        return LaunchConfiguration(
            personaID: personaID,
            clock: clock,
            colorScheme: colorScheme,
            gameLevel: gameLevel,
            hasUITestArguments: arguments.contains { $0.hasPrefix("-uitest-") },
            showOnboarding: arguments.contains("-uitest-show-onboarding"),
            seed: seed,
            teaBreakGameIDs: teaBreakGameIDs,
            roundSeconds: roundSeconds
        )
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
