// Font+MatchaMind.swift
// Typografie-Tokens aus design/designsystem-README.md ("Schrift") und
// design/designsystem-tokens.json ("type.groups"). Zen Maru Gothic fuer
// Ueberschriften, Nunito fuer alles andere. Alle Stile sind relativ zu
// einer SF-Dynamic-Type-Textstil-Groesse, damit Dynamic Type funktioniert.
//
// Schrift-Dateien liegen unter Resources/Fonts und sind in project.yml
// als UIAppFonts registriert. Die PostScript-Namen wurden geprueft,
// siehe Resources/Fonts/LIZENZ.md.

import SwiftUI

extension Font {
    /// Screen-Titel auf der Startseite. Zen Maru Gothic 700, 30pt, relativ zu `.largeTitle`.
    public static var mmDisplay: Font {
        .custom("ZenMaruGothic-Bold", size: 30, relativeTo: .largeTitle)
    }

    /// Titel von Spielen und Unterseiten. Zen Maru Gothic 700, 24pt, relativ zu `.title`.
    public static var mmTitle: Font {
        .custom("ZenMaruGothic-Bold", size: 24, relativeTo: .title)
    }

    /// Ueberschrift in Karten und Fenstern. Zen Maru Gothic 700, 20pt, relativ zu `.title3`.
    public static var mmHeadline: Font {
        .custom("ZenMaruGothic-Bold", size: 20, relativeTo: .title3)
    }

    /// Anleitungen, Regeln, Fliesstext. Nunito SemiBold 600, 16pt, relativ zu `.body`.
    public static var mmBody: Font {
        .custom("Nunito-SemiBold", size: 16, relativeTo: .body)
    }

    /// Beschriftung von Haupt-Buttons. Nunito ExtraBold 800, 17pt, relativ zu `.headline`.
    public static var mmButton: Font {
        .custom("Nunito-ExtraBold", size: 17, relativeTo: .headline)
    }

    /// Werte, Zaehler, Hinweise in Karten. Nunito Bold 700, 14pt, relativ zu `.callout`.
    public static var mmCallout: Font {
        .custom("Nunito-Bold", size: 14, relativeTo: .callout)
    }

    /// Untertitel und Nebeninfos. Nunito Regular 400, 13pt, relativ zu `.footnote`.
    public static var mmCaption: Font {
        .custom("Nunito-Regular", size: 13, relativeTo: .footnote)
    }

    /// Abzeichen, Tab-Beschriftungen. Nunito ExtraBold 800, 12pt, relativ zu `.caption`.
    public static var mmLabel: Font {
        .custom("Nunito-ExtraBold", size: 12, relativeTo: .caption)
    }
}
