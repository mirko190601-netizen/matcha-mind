// PrimaryButton.swift
// Komponente "Primär-Button" aus design/designsystem-README.md ("Komponenten").
// Die eine Hauptaktion pro Screen. Voll gefuellt mit `matcha-600`, Text
// `on-primary` im Stil `button`, 54pt hoch, rund. Kein Glas (siehe
// "Liquid Glass": Haupt-Button ist voll matcha-600, kein Glas-Element).

import SwiftUI

public struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.mmButton)
                .foregroundStyle(Color("on-primary"))
                .frame(maxWidth: .infinity)
                .frame(height: Size.buttonHeight)
        }
        .buttonStyle(.plain)
        .background(Color("matcha-600"), in: .rect(cornerRadius: Radius.radiusPill))
        .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
        .contentShape(.rect(cornerRadius: Radius.radiusPill))
    }
}

#Preview("Hell") {
    VStack(spacing: Space.space4) {
        PrimaryButton("Teepause starten") {}
        PrimaryButton("Weiter") {}
    }
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    VStack(spacing: Space.space4) {
        PrimaryButton("Teepause starten") {}
        PrimaryButton("Weiter") {}
    }
    .padding(Space.space6)
    .background(Color("bg-garden"))
    .preferredColorScheme(.dark)
}
