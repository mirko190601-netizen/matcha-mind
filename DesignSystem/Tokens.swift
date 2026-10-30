// Tokens.swift
// Automatisch generiert von scripts/tokens.py aus design/designsystem-tokens.json.
// NICHT MANUELL BEARBEITEN - Aenderungen werden beim naechsten Lauf ueberschrieben.

import CoreGraphics

public enum Space {
    /// Abstand Icon zu Beschriftung.
    public static let space1: CGFloat = 4
    /// Abstand zwischen Spielbrett-Feldern und Zeilen in Listen.
    public static let space2: CGFloat = 8
    /// Abstand zwischen Karten.
    public static let space3: CGFloat = 12
    /// Innenabstand kleiner Karten.
    public static let space4: CGFloat = 16
    /// Seitenrand von Karten und Leisten.
    public static let space5: CGFloat = 20
    /// Seitenrand von Text und Kopfzeile; Innenabstand großer Karten.
    public static let space6: CGFloat = 24
    /// Abstand zwischen Abschnitten.
    public static let space8: CGFloat = 32
}

public enum Radius {
    /// Spielbrett-Felder, kleine Kacheln.
    public static let radiusSm: CGFloat = 12
    /// Listen-Kacheln, Hinweis-Chips.
    public static let radiusMd: CGFloat = 16
    /// Karten in Listen, Regeln-Fenster.
    public static let radiusLg: CGFloat = 22
    /// Hauptkarten, Spielanleitungs-Fenster, Tab-Leiste.
    public static let radiusXl: CGFloat = 28
    /// Buttons, Abzeichen, runde Glas-Buttons.
    public static let radiusPill: CGFloat = 999
}

public enum Size {
    /// Mindestgröße jedes tippbaren Elements.
    public static let touchMin: CGFloat = 44
    /// Höhe von Haupt-Buttons.
    public static let buttonHeight: CGFloat = 54
    /// Sichtbarer Kreis des ?-Regel-Buttons; Tippfläche bleibt 44px.
    public static let helpButton: CGFloat = 36
    /// Neu v2: maximale Breite von Lesespalten und Spielbrettern auf dem iPad.
    public static let readingMax: CGFloat = 640
    /// Höhe des Glas-Buttons (Nebenaktionen), siehe Komponenten-Tabelle.
    public static let glassButtonHeight: CGFloat = 50
    /// Icon-Größe im Kopfzeilen-Button (Komponenten-Tabelle nennt 18–20pt; oberes Ende gewählt).
    public static let iconHeader: CGFloat = 20
    /// Icon-Größe im Regel-Button (?); in der Komponenten-Tabelle nicht in pt benannt, proportional zum 36pt-Kreis gewählt.
    public static let iconHelp: CGFloat = 16
}
