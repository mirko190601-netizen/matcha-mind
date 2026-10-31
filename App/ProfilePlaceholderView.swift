import SwiftUI

/// Platzhalter-Screen für den Profil-Tab (Grundgerüst, Block B1).
/// Ruhiger Screen wie Teepause/Einstellungen → Hintergrund `bg-tea`
/// (design/designsystem-README.md, Abschnitt "Farben"). Die echte
/// Profilansicht folgt in einem späteren Block. Seit Block B4 führt eine
/// Zeile "Stufe" zum Stufen-Screen (`Settings/LevelSettingsView.swift`).
struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Space.space6) {
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

                NavigationLink {
                    LevelSettingsView()
                } label: {
                    GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
                        HStack {
                            Text(String(localized: "level.title", defaultValue: "Stufe"))
                                .font(.mmCallout)
                                .foregroundStyle(Color("ink"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: Size.iconHelp, weight: .medium))
                                .foregroundStyle(Color("text-muted"))
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile.level")
                .frame(maxWidth: Size.readingMax)
            }
            .padding(Space.space6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("bg-tea"))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview("Hell") {
    ProfilePlaceholderView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    ProfilePlaceholderView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
