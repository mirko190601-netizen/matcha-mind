import SwiftUI

/// Platzhalter-Screen für den Profil-Tab (Grundgerüst, Block B1).
/// Ruhiger Screen wie Teepause/Einstellungen → Hintergrund `bg-tea`
/// (design/designsystem-README.md, Abschnitt "Farben"). Die echte
/// Profilansicht folgt in einem späteren Block.
struct ProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: Space.space3) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: Size.touchMin, weight: .medium, design: .rounded))
                .foregroundStyle(Color("ink"))
                .accessibilityHidden(true)
            Text(String(localized: "tab.profile.title", defaultValue: "Profil"))
                .font(.mmHeadline)
                .foregroundStyle(Color("ink"))
            Text(String(localized: "placeholder.profile.body", defaultValue: "Hier findest du bald dein Profil."))
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
    ProfilePlaceholderView()
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    ProfilePlaceholderView()
        .preferredColorScheme(.dark)
}
