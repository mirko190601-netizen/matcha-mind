// HelpButton.swift
// Komponente "Regel-Button (?)" aus design/designsystem-README.md
// ("Komponenten"). In jedem Spiel oben rechts. Glas-Kreis 36pt sichtbar,
// Tippflaeche 44pt, Icon `questionmark` in `text-muted`. Öffnet das
// Regel-Fenster (Aufruf übernimmt der Call-Site via `action`).

import SwiftUI

public struct HelpButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "questionmark")
                .font(.system(size: Size.iconHelp, weight: .medium))
                .foregroundStyle(Color("text-muted"))
                .frame(width: Size.helpButton, height: Size.helpButton)
                .glassEffect(.regular.interactive(), in: .circle)
                .frame(width: Size.touchMin, height: Size.touchMin)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Spielregeln")
    }
}

#Preview("Hell") {
    HelpButton {}
        .padding(Space.space6)
        .background(Color("bg-garden"))
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    HelpButton {}
        .padding(Space.space6)
        .background(Color("bg-garden"))
        .preferredColorScheme(.dark)
}
