import SwiftUI

/// Wurzel der App: zeigt beim allerersten Start den Erststart
/// (`OnboardingView`: Begrüßung, Uhrzeit der Erinnerung), danach die
/// Haupt-Navigation. In DEBUG-UI-Tests entfällt der Erststart, außer mit
/// `-uitest-show-onboarding` (siehe `AppEnvironment.showsOnboarding`).
struct RootView: View {
    @Environment(PlayerStore.self) private var playerStore
    @Environment(\.appEnvironment) private var appEnvironment

    var body: some View {
        if appEnvironment.showsOnboarding && !playerStore.onboardingCompleted {
            OnboardingView()
        } else {
            ContentView()
        }
    }
}

#Preview {
    RootView()
        .environment(PlayerStore.preview())
}
