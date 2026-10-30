import SwiftUI

/// Platzhalter-Screen für den Garten-Tab (Grundgerüst, Block B1).
/// Die echte Garten-Szene (Illustration v2) folgt in einem späteren Block;
/// hier stehen nur Icon, Titel und ein kurzer Hinweistext.
struct GardenPlaceholderView: View {
    var body: some View {
        VStack(spacing: Space.space3) {
            Image(systemName: "leaf.fill")
                .font(.system(size: Size.touchMin, weight: .medium, design: .rounded))
                .foregroundStyle(Color("ink"))
                .accessibilityHidden(true)
            Text(String(localized: "tab.garden.title", defaultValue: "Garten"))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))
            Text(String(localized: "placeholder.garden.body", defaultValue: "Hier wächst bald dein Garten."))
                .font(.mmBody)
                .foregroundStyle(Color("text"))
                .multilineTextAlignment(.center)
        }
        .padding(Space.space6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bg-garden"))
    }
}

#Preview("Hell") {
    GardenPlaceholderView()
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GardenPlaceholderView()
        .preferredColorScheme(.dark)
}
