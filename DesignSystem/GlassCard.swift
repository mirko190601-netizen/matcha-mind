// GlassCard.swift
// Komponente "Glas-Karte" aus design/designsystem-README.md ("Komponenten").
// Fuer Teepause, Hinweise, Regeln, Einstellungen. Glas, Radius 22 oder 28,
// Innenabstand 16-20.

import SwiftUI

public struct GlassCard<Content: View>: View {
    private let radius: CGFloat
    private let padding: CGFloat
    private let content: Content

    /// - Parameters:
    ///   - radius: `Radius.radiusLg` (22, Listenkarten/Regeln) oder
    ///     `Radius.radiusXl` (28, Hauptkarten/Fenster). Standard: `radiusXl`.
    ///   - padding: Innenabstand, laut Designsystem 16-20pt
    ///     (`Space.space4` oder `Space.space5`). Standard: `space5`.
    public init(
        radius: CGFloat = Radius.radiusXl,
        padding: CGFloat = Space.space5,
        @ViewBuilder content: () -> Content
    ) {
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(minWidth: Size.touchMin, minHeight: Size.touchMin)
            .glassEffect(.regular, in: .rect(cornerRadius: radius))
    }
}

#Preview("Hell") {
    VStack(spacing: Space.space3) {
        GlassCard {
            VStack(alignment: .leading, spacing: Space.space2) {
                Text("Deine Teepause wartet")
                    .font(.mmHeadline)
                    .foregroundStyle(Color("ink"))
                Text("Im Bambushain ist etwas aufgeblüht.")
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))
            }
        }
        GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            Text("Tautropfen 62 / 100")
                .font(.mmCallout)
                .foregroundStyle(Color("tau-700"))
        }
    }
    .padding(Space.space6)
    .background(Color("bg-tea"))
    .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    VStack(spacing: Space.space3) {
        GlassCard {
            VStack(alignment: .leading, spacing: Space.space2) {
                Text("Deine Teepause wartet")
                    .font(.mmHeadline)
                    .foregroundStyle(Color("ink"))
                Text("Im Bambushain ist etwas aufgeblüht.")
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))
            }
        }
        GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            Text("Tautropfen 62 / 100")
                .font(.mmCallout)
                .foregroundStyle(Color("tau-700"))
        }
    }
    .padding(Space.space6)
    .background(Color("bg-tea"))
    .preferredColorScheme(.dark)
}
