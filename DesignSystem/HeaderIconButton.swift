// HeaderIconButton.swift
// Komponente "Kopfzeilen-Button" aus design/designsystem-README.md
// ("Komponenten"). Fuer Zurück, Pause, ?. Runder Glas-Kreis 44pt,
// Icon 18-20pt.

import SwiftUI

public struct HeaderIconButton: View {
    private let systemImage: String
    private let accessibilityLabel: String
    private let action: () -> Void

    public init(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: Size.iconHeader, weight: .medium))
                .foregroundStyle(Color("text"))
                .frame(width: Size.touchMin, height: Size.touchMin)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Hell") {
    GlassEffectContainer {
        HStack(spacing: Space.space3) {
            HeaderIconButton(systemImage: "chevron.left", accessibilityLabel: "Zurück") {}
            HeaderIconButton(systemImage: "pause.fill", accessibilityLabel: "Pause") {}
        }
    }
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GlassEffectContainer {
        HStack(spacing: Space.space3) {
            HeaderIconButton(systemImage: "chevron.left", accessibilityLabel: "Zurück") {}
            HeaderIconButton(systemImage: "pause.fill", accessibilityLabel: "Pause") {}
        }
    }
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}
