// GlassButton.swift
// Komponente "Glas-Button" aus design/designsystem-README.md ("Komponenten").
// Fuer Nebenaktionen. Glas, Text in `text`-Farbe im Stil `button`, 50pt
// hoch, rund.

import SwiftUI

public struct GlassButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Space.space1) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.mmButton)
            .foregroundStyle(Color("text"))
            .padding(.horizontal, Space.space5)
            .frame(height: Size.glassButtonHeight)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Radius.radiusPill))
        .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
    }
}

#Preview("Hell") {
    GlassEffectContainer {
        VStack(spacing: Space.space4) {
            GlassButton("Überspringen") {}
            GlassButton("Weiterspielen", systemImage: "arrow.right") {}
        }
    }
    .padding(Space.space6)
    .background(Color("bg-tea"))
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GlassEffectContainer {
        VStack(spacing: Space.space4) {
            GlassButton("Überspringen") {}
            GlassButton("Weiterspielen", systemImage: "arrow.right") {}
        }
    }
    .padding(Space.space6)
    .background(Color("bg-tea"))
    .preferredColorScheme(.dark)
}
