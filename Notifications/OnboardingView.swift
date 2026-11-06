// OnboardingView.swift
// Erststart (MASTER-PROMPT.md, Block B4 Aufgabe 7): Begruessung, dann die
// Uhrzeit der Erinnerung (Vorschlag 12:30). Die Mitteilungs-Abfrage des
// Systems kommt erst, wenn die Zeit bestaetigt wird. "Ohne Erinnerung" ist
// jederzeit moeglich; Ablehnen im Dialog ist in Ordnung.

import SwiftUI

struct OnboardingView: View {
    @Environment(PlayerStore.self) private var playerStore
    @Environment(\.reminderCoordinator) private var coordinator

    private enum Step {
        case welcome
        case time
    }

    @State private var step: Step = .welcome
    @State private var selectedTime: Date = OnboardingView.suggestedDate()

    var body: some View {
        ZStack {
            Color("bg-tea").ignoresSafeArea()
            switch step {
            case .welcome:
                welcome
            case .time:
                timePicker
            }
        }
    }

    // MARK: - Begruessung

    private var welcome: some View {
        VStack(spacing: Space.space6) {
            Spacer()
            VStack(spacing: Space.space3) {
                Text(String(localized: "onboarding.welcome.title", defaultValue: "Willkommen bei Matcha Mind"))
                    .font(.mmDisplay)
                    .foregroundStyle(Color("ink"))
                    .multilineTextAlignment(.center)
                Text(String(localized: "onboarding.welcome.body", defaultValue: "Gehirnjogging im Teegarten. Jeden Tag eine kleine Teepause mit drei kurzen Spielen."))
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(String(localized: "onboarding.welcome.next", defaultValue: "Weiter")) {
                step = .time
            }
            .accessibilityIdentifier("onboarding.next")
        }
        .frame(maxWidth: Size.readingMax)
        .padding(Space.space6)
    }

    // MARK: - Uhrzeit

    private var timePicker: some View {
        VStack(spacing: Space.space6) {
            Spacer()
            VStack(spacing: Space.space3) {
                Text(String(localized: "onboarding.time.title", defaultValue: "Wann magst du erinnert werden?"))
                    .font(.mmTitle)
                    .foregroundStyle(Color("ink"))
                    .multilineTextAlignment(.center)
                Text(String(localized: "onboarding.time.body", defaultValue: "Zu dieser Zeit bekommst du einen leisen Hinweis. Du kannst das jederzeit ändern."))
                    .font(.mmBody)
                    .foregroundStyle(Color("text"))
                    .multilineTextAlignment(.center)
            }
            DatePicker(
                String(localized: "onboarding.time.picker", defaultValue: "Uhrzeit der Erinnerung"),
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .accessibilityIdentifier("onboarding.timePicker")
            Spacer()
            VStack(spacing: Space.space3) {
                PrimaryButton(String(localized: "onboarding.time.confirm", defaultValue: "Erinnerung festlegen")) {
                    confirm()
                }
                .accessibilityIdentifier("onboarding.confirm")
                GlassButton(String(localized: "onboarding.time.skip", defaultValue: "Ohne Erinnerung")) {
                    skip()
                }
                .accessibilityIdentifier("onboarding.skip")
            }
        }
        .frame(maxWidth: Size.readingMax)
        .padding(Space.space6)
    }

    // MARK: - Aktionen

    private func confirm() {
        let time = Self.reminderTime(from: selectedTime)
        if let coordinator {
            Task { await coordinator.confirmReminderTime(time) }
        } else {
            playerStore.setReminderTime(time)
            playerStore.completeOnboarding()
        }
    }

    private func skip() {
        if let coordinator {
            Task { await coordinator.skipReminderTime() }
        } else {
            playerStore.completeOnboarding()
        }
    }

    // MARK: - Hilfen

    /// Stunde und Minute aus dem Picker-Wert (lokaler Kalender).
    static func reminderTime(from date: Date, calendar: Calendar = .autoupdatingCurrent) -> ReminderTime {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return ReminderTime(hour: components.hour ?? ReminderTime.suggested.hour, minute: components.minute ?? ReminderTime.suggested.minute)
    }

    /// Vorschlag 12:30 als Datum von heute.
    static func suggestedDate(calendar: Calendar = .autoupdatingCurrent) -> Date {
        let suggested = ReminderTime.suggested
        return calendar.date(bySettingHour: suggested.hour, minute: suggested.minute, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    OnboardingView()
        .environment(PlayerStore.preview())
}
