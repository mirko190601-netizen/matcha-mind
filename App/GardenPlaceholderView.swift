import SwiftUI

/// Platzhalter-Screen für den Garten-Tab (Grundgerüst, Block B1).
/// Die echte Garten-Szene (Illustration v2) folgt in einem späteren Block;
/// hier stehen nur Icon, Titel und ein kurzer Hinweistext - dazu der Einstieg
/// in die Teepause (Block B4): ein Knopf, oder, wenn die Teepause heute schon
/// erledigt ist, ein ruhiger Hinweis.
struct GardenPlaceholderView: View {
    @Environment(PlayerStore.self) private var playerStore
    @State private var showTeaBreak = false

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

            teaBreakEntry
        }
        .padding(Space.space6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bg-garden"))
        .fullScreenCover(isPresented: $showTeaBreak) {
            TeaBreakView(onClose: { showTeaBreak = false })
        }
    }

    private var teaBreakDoneText: String {
        String(localized: "garden.teabreak.done", defaultValue: "Deine Teepause für heute ist getrunken. Im Spiele-Tab kannst du frei weiterspielen.")
    }

    @ViewBuilder
    private var teaBreakEntry: some View {
        if playerStore.isTeaBreakCompletedToday {
            Text(teaBreakDoneText)
            .font(.mmBody)
            .foregroundStyle(Color("text"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: Size.readingMax)
        } else {
            PrimaryButton(String(localized: "garden.teabreak.start", defaultValue: "Teepause starten")) {
                showTeaBreak = true
            }
            .accessibilityIdentifier("teabreak.start")
            .frame(maxWidth: Size.readingMax)
        }
    }
}

#Preview("Hell") {
    GardenPlaceholderView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    GardenPlaceholderView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
