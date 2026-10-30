// GameDefinition.swift
// Gemeinsamer Spiel-Baukasten (MASTER-PROMPT.md, Block B3 Aufgabe 1).
// Beschreibt, was jedes der 14 Spiele aus dem Spiele-Katalog (Abschnitt 6)
// dem Baukasten mitteilen muss, ohne dass der Baukasten Sonderfaelle fuer
// einzelne Spiele braucht: die Parameter je Stufe stammen als eigener,
// pro Spiel definierter Typ aus `Parameters`.

import Foundation

/// Die drei Tee-Stufen, in denen Matcha Mind gespielt wird. Zentral hier
/// angelegt, da `GameDefinition` sie fuer `minLevel` und die
/// Parameter-Map benoetigt; andere Bausteine (Garten, Fortschritt) nutzen
/// denselben Typ.
public enum TeaLevel: Int, CaseIterable, Comparable, Sendable {
    case sencha
    case oolong
    case matcha

    public static func < (lhs: TeaLevel, rhs: TeaLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Bereichs-Kategorien der 14 Spiele, eine je Spiel, aus der
/// "Bereich"-Spalte des Spiele-Katalogs (MASTER-PROMPT.md, Abschnitt 6).
public enum GameArea: String, CaseIterable, Sendable {
    /// Teekannen-Reihe (Corsi-Block).
    case spatialMemory
    /// Gluehwuermchen am Teich (Go/No-Go).
    case focus
    /// Das Mosaik-Beet (Platzierung nach Nachbarschaftsregeln).
    case logic
    /// Teeblaetter sortieren (Wisconsin-Prinzip).
    case flexibility
    /// Bambus-Rechnen (Rechenkette).
    case mentalMath
    /// Teezeremonie-Echo (N-Back).
    case workingMemory
    /// Laternen-Farbwort (Stroop).
    case impulseControl
    /// Die Steinlaterne (mentale Rotation 3D).
    case spatialReasoning
    /// Gartenpfad-Planer (Turm-von-London-Prinzip).
    case planning
    /// Wortgarten (Anagramme/Wortfindung).
    case language
    /// Mondbruecke (Dual-N-Back).
    case dualWorkingMemory
    /// Meister-Mosaik (Logikgitter, Einstein-Prinzip).
    case reasoning
    /// Koi-Schwarm (Objektverfolgung).
    case dividedAttention
    /// Gaertner-Muster (Folgen und Matrizen ergaenzen).
    case patternRecognition
}

/// Beschreibt ein Spiel fuer den Baukasten: Katalog-Metadaten (Name,
/// Bereich, ab welcher Stufe spielbar, Anleitung, Kurzregeln, Proberunde)
/// sowie die konkreten Spiel-Parameter je Stufe.
///
/// Jedes Spiel bringt seinen eigenen `Parameters`-Typ mit (z. B.
/// `TeapotRowParameters` fuer die Teekannen-Reihe) - der Baukasten selbst
/// kennt dessen Form nicht und braucht daher keinen Sonderfall-Code.
public protocol GameDefinition {
    /// Spiel-spezifischer Parameter-Typ, z. B. Folgenlaenge, Rasterform,
    /// Anzahl Regeln - frei durch das jeweilige Spiel definiert.
    associatedtype Parameters

    /// Stabile Kennung, z. B. "teapot-row". Wird u. a. fuer die
    /// Feinstufen-Speicherung (`FineLevelTracker` pro Spiel-ID) genutzt.
    var id: String { get }

    /// String-Katalog-Schluessel des Spielnamens.
    var nameKey: String { get }

    /// Bereichs-Kategorie aus dem Spiele-Katalog.
    var area: GameArea { get }

    /// Ab welcher Tee-Stufe dieses Spiel ueberhaupt freigeschaltet ist.
    var minLevel: TeaLevel { get }

    /// Anzahl der Seiten im Anleitungs-Fenster, 1 bis 3.
    var instructionPageCount: Int { get }

    /// String-Katalog-Schluessel der 3-4 Kurzregeln fuer das Regel-Fenster.
    var shortRuleKeys: [String] { get }

    /// Ob vor der gewerteten Runde eine Proberunde angeboten wird.
    var hasTrialRound: Bool { get }

    /// Spiel-Parameter je Tee-Stufe. Stufen, in denen das Spiel laut
    /// Katalog gesperrt ist ("-"), fehlen hier als Schluessel.
    var parameters: [TeaLevel: Parameters] { get }
}
