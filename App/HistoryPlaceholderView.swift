import SwiftUI

/// Platzhalter-Screen für den Verlauf-Tab (Grundgerüst, Block B1).
/// Ruhiger Screen wie Teepause/Einstellungen → Hintergrund `bg-tea`
/// (design/designsystem-README.md, Abschnitt "Farben"). Die echte
/// Verlaufsansicht folgt in einem späteren Block.
struct HistoryPlaceholderView: View {
    var body: some View {
        VStack(spacing: Space.space3) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: Size.touchMin, weight: .medium, design: .rounded))
                .foregroundStyle(Color("ink"))
                .accessibilityHidden(true)
            Text(String(localized: "tab.history.title", defaultValue: "Verlauf"))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))
            Text(String(localized: "placeholder.history.body", defaultValue: "Hier siehst du bald deinen Verlauf."))
                .font(.mmBody)
                .foregroundStyle(Color("text"))
                .multilineTextAlignment(.center)
        }
        .padding(Space.space6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bg-tea"))
    }
}

#Preview("Hell") {
    HistoryPlaceholderView()
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    HistoryPlaceholderView()
        .preferredColorScheme(.dark)
}
