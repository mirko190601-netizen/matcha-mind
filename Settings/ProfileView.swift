// ProfileView.swift
// Profil (MASTER-PROMPT.md, Block B4 Aufgabe 8): Stufe, Auto-Aufstieg,
// Erinnerung, Ton, Haptik, Sprache, Datenschutz und der Platzhalter fuer
// Kauf/Wiederherstellen (inaktiv, Logik erst in B7). Ruhiger Screen →
// Hintergrund `bg-tea` (design/designsystem-README.md, Abschnitt "Farben").
// Die Erinnerung laeuft ueber `ReminderCoordinator` (in Vorschauen `nil`).

import SwiftUI
import UIKit

/// Feste Links der App. Die Datenschutz-Seite entsteht erst in Block B10.
enum AppLinks {
    static let privacyPolicyString = "https://mirko190601-netizen.github.io/matcha-mind-site/datenschutz/"
    static let privacyPolicy = URL(string: privacyPolicyString)
}

/// Anzeige-Logik des Profils, ohne SwiftUI, damit sie testbar bleibt.
enum ProfileLogic {
    enum ReminderStatus: Equatable {
        /// Taegliche Erinnerung zur gewaehlten Zeit.
        case time(ReminderTime)
        /// Im Profil ausgeschaltet.
        case off
        /// Keine Zeit gewaehlt (nur die einmalige Einladung).
        case notChosen
    }

    static func reminderStatus(time: ReminderTime?, isOff: Bool) -> ReminderStatus {
        if isOff { return .off }
        if let time { return .time(time) }
        return .notChosen
    }

    /// Hinweis mit Weg in die iOS-Einstellungen: nur, wenn eine Erinnerung
    /// gewaehlt ist und das System Mitteilungen ausgeschaltet hat.
    static func showsDeniedHint(status: ReminderStatus, authorization: ReminderAuthorizationState) -> Bool {
        guard authorization == .denied else { return false }
        if case .time = status { return true }
        return false
    }

    /// Uhrzeit als Datum von heute (fuer Anzeige und Picker).
    static func date(for time: ReminderTime, now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: now) ?? now
    }
}

struct ProfileView: View {
    @Environment(PlayerStore.self) private var playerStore
    @Environment(\.reminderCoordinator) private var coordinator
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var showsTimeSheet = false
    @State private var authorization: ReminderAuthorizationState = .notDetermined

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.space4) {
                    header
                    levelRow
                    autoAdvanceRow
                    reminderCard
                    toggleCard(
                        title: String(localized: "profile.sound.title", defaultValue: "Ton"),
                        isOn: soundBinding,
                        identifier: "profile.sound"
                    )
                    toggleCard(
                        title: String(localized: "profile.haptics.title", defaultValue: "Haptik"),
                        isOn: hapticsBinding,
                        identifier: "profile.haptics"
                    )
                    languageRow
                    privacyRow
                    purchaseRow
                }
                .frame(maxWidth: Size.readingMax, alignment: .leading)
                .padding(Space.space6)
                .frame(maxWidth: .infinity)
            }
            .background(Color("bg-tea"))
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsTimeSheet) {
            ReminderTimeSheet(
                initial: ProfileLogic.date(for: currentTime ?? ReminderTime.suggested),
                onSave: { time in
                    showsTimeSheet = false
                    confirm(time)
                },
                onCancel: { showsTimeSheet = false }
            )
        }
        .task { await refreshAuthorization() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await refreshAuthorization() }
            }
        }
    }

    // MARK: - Kopf

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.space2) {
            Text(String(localized: "tab.profile.title", defaultValue: "Profil"))
                .font(.mmTitle)
                .foregroundStyle(Color("ink"))
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "profile.intro", defaultValue: "Hier stellst du alles so ein, wie es dir gefällt."))
                .font(.mmBody)
                .foregroundStyle(Color("text"))
        }
    }

    // MARK: - Stufe

    private var levelRow: some View {
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
    }

    private var autoAdvanceRow: some View {
        GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            VStack(alignment: .leading, spacing: Space.space2) {
                Toggle(isOn: autoAdvanceBinding) {
                    Text(String(localized: "level.auto.toggle", defaultValue: "Automatisch aufsteigen"))
                        .font(.mmCallout)
                        .foregroundStyle(Color("ink"))
                }
                .tint(Color("matcha-600"))
                .accessibilityIdentifier("profile.autoAdvance")
                Text(String(localized: "profile.autoAdvance.hint", defaultValue: "Wir schlagen dir die nächste Stufe vor. Du entscheidest."))
                    .font(.mmCaption)
                    .foregroundStyle(Color("text-muted"))
            }
        }
    }

    // MARK: - Erinnerung

    private var currentTime: ReminderTime? { playerStore.reminderTime }

    private var reminderStatus: ProfileLogic.ReminderStatus {
        ProfileLogic.reminderStatus(time: playerStore.reminderTime, isOff: playerStore.reminderOff)
    }

    private var reminderCard: some View {
        let status = reminderStatus
        return GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            VStack(alignment: .leading, spacing: Space.space3) {
                HStack {
                    Text(String(localized: "profile.reminder.title", defaultValue: "Erinnerung"))
                        .font(.mmCallout)
                        .foregroundStyle(Color("ink"))
                    Spacer()
                    reminderValue(status)
                }
                HStack(spacing: Space.space3) {
                    GlassButton(String(localized: "profile.reminder.change", defaultValue: "Ändern")) {
                        showsTimeSheet = true
                    }
                    .accessibilityIdentifier("profile.reminder.change")
                    if status != .off {
                        GlassButton(String(localized: "profile.reminder.off", defaultValue: "Aus")) {
                            turnOffReminder()
                        }
                        .accessibilityIdentifier("profile.reminder.off")
                    }
                }
                if ProfileLogic.showsDeniedHint(status: status, authorization: authorization) {
                    deniedHint
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profile.reminder")
    }

    @ViewBuilder
    private func reminderValue(_ status: ProfileLogic.ReminderStatus) -> some View {
        switch status {
        case .time(let time):
            Text(ProfileLogic.date(for: time), format: .dateTime.hour().minute())
                .font(.mmCallout)
                .foregroundStyle(Color("text"))
                .accessibilityIdentifier("profile.reminder.value")
        case .off:
            Text(String(localized: "profile.reminder.status.off", defaultValue: "Aus"))
                .font(.mmCallout)
                .foregroundStyle(Color("text-muted"))
                .accessibilityIdentifier("profile.reminder.value")
        case .notChosen:
            Text(String(localized: "profile.reminder.status.none", defaultValue: "Keine Uhrzeit"))
                .font(.mmCallout)
                .foregroundStyle(Color("text-muted"))
                .accessibilityIdentifier("profile.reminder.value")
        }
    }

    private var deniedHint: some View {
        VStack(alignment: .leading, spacing: Space.space2) {
            Text(String(localized: "profile.reminder.denied", defaultValue: "Mitteilungen sind für Matcha Mind ausgeschaltet. In den iOS-Einstellungen kannst du sie wieder erlauben."))
                .font(.mmCaption)
                .foregroundStyle(Color("text-muted"))
            GlassButton(String(localized: "profile.settings.open", defaultValue: "iOS-Einstellungen öffnen")) {
                openSystemSettings()
            }
            .accessibilityIdentifier("profile.reminder.settings")
        }
    }

    private func confirm(_ time: ReminderTime) {
        if let coordinator {
            Task {
                await coordinator.confirmReminderTime(time)
                authorization = await coordinator.authorizationState()
            }
        } else {
            playerStore.setReminderTime(time)
        }
    }

    private func turnOffReminder() {
        if let coordinator {
            Task { await coordinator.turnOff() }
        } else {
            playerStore.setReminderOff(true)
        }
    }

    private func refreshAuthorization() async {
        guard let coordinator else { return }
        authorization = await coordinator.authorizationState()
    }

    // MARK: - Ton und Haptik

    private func toggleCard(title: String, isOn: Binding<Bool>, identifier: String) -> some View {
        GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(.mmCallout)
                    .foregroundStyle(Color("ink"))
            }
            .tint(Color("matcha-600"))
            .accessibilityIdentifier(identifier)
        }
    }

    // MARK: - Sprache, Datenschutz, Kauf

    private var languageRow: some View {
        Button {
            openSystemSettings()
        } label: {
            GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
                HStack(spacing: Space.space3) {
                    VStack(alignment: .leading, spacing: Space.space1) {
                        Text(String(localized: "profile.language.title", defaultValue: "Sprache"))
                            .font(.mmCallout)
                            .foregroundStyle(Color("ink"))
                        Text(String(localized: "profile.language.hint", defaultValue: "Die Sprache stellst du in den iOS-Einstellungen ein."))
                            .font(.mmCaption)
                            .foregroundStyle(Color("text-muted"))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: Size.iconHelp, weight: .medium))
                        .foregroundStyle(Color("text-muted"))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.language")
    }

    private var privacyRow: some View {
        Button {
            if let url = AppLinks.privacyPolicy {
                openURL(url)
            }
        } label: {
            GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
                HStack {
                    Text(String(localized: "profile.privacy.title", defaultValue: "Datenschutz"))
                        .font(.mmCallout)
                        .foregroundStyle(Color("ink"))
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: Size.iconHelp, weight: .medium))
                        .foregroundStyle(Color("text-muted"))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.privacy")
    }

    /// Nicht tippbar: die Logik folgt in Block B7.
    private var purchaseRow: some View {
        GlassCard(radius: Radius.radiusLg, padding: Space.space4) {
            HStack {
                Text(String(localized: "profile.purchase.title", defaultValue: "Kauf und Wiederherstellen"))
                    .font(.mmCallout)
                    .foregroundStyle(Color("text-muted"))
                Spacer()
                Text(String(localized: "profile.purchase.soon", defaultValue: "Bald verfügbar"))
                    .font(.mmCaption)
                    .foregroundStyle(Color("text-muted"))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("profile.purchase")
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    // MARK: - Bindungen

    private var autoAdvanceBinding: Binding<Bool> {
        Binding(
            get: { playerStore.autoAdvance },
            set: { playerStore.setAutoAdvance($0) }
        )
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { playerStore.soundEnabled },
            set: { playerStore.setSoundEnabled($0) }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { playerStore.hapticsEnabled },
            set: { playerStore.setHapticsEnabled($0) }
        )
    }
}

/// Fenster zum Aendern der Erinnerungszeit.
private struct ReminderTimeSheet: View {
    @State private var selected: Date
    private let onSave: (ReminderTime) -> Void
    private let onCancel: () -> Void

    init(initial: Date, onSave: @escaping (ReminderTime) -> Void, onCancel: @escaping () -> Void) {
        _selected = State(initialValue: initial)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: Space.space6) {
            Text(String(localized: "profile.reminder.sheet.title", defaultValue: "Wann magst du erinnert werden?"))
                .font(.mmTitle)
                .foregroundStyle(Color("ink"))
                .multilineTextAlignment(.center)
            DatePicker(
                String(localized: "onboarding.time.picker", defaultValue: "Uhrzeit der Erinnerung"),
                selection: $selected,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .accessibilityIdentifier("profile.reminder.picker")
            VStack(spacing: Space.space3) {
                PrimaryButton(String(localized: "profile.reminder.sheet.save", defaultValue: "Speichern")) {
                    onSave(OnboardingView.reminderTime(from: selected))
                }
                .accessibilityIdentifier("profile.reminder.save")
                GlassButton(String(localized: "profile.reminder.sheet.cancel", defaultValue: "Abbrechen")) {
                    onCancel()
                }
                .accessibilityIdentifier("profile.reminder.cancel")
            }
        }
        .frame(maxWidth: Size.readingMax)
        .padding(Space.space6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bg-tea"))
        .presentationDetents([.medium])
    }
}

#Preview("Hell") {
    ProfileView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.light)
}

#Preview("Dunkel") {
    ProfileView()
        .environment(PlayerStore.preview())
        .preferredColorScheme(.dark)
}
