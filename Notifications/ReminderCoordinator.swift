// ReminderCoordinator.swift
// Erinnerung (MASTER-PROMPT.md, Block B4 Aufgabe 7): verbindet Spielerdaten,
// `ReminderPlanner` und das System. Neu geplant wird, wenn die Szene aktiv
// wird, nach einer Teepause und nach einer Aenderung der Erinnerung.
//
// `@MainActor`: liest den `PlayerStore`. Die Anfragen ans System laufen
// ueber `NotificationScheduling` (Sendable) und sind `async`.

import Foundation
import SwiftUI

@MainActor
final class ReminderCoordinator {
    private let store: PlayerStore
    private let scheduler: any NotificationScheduling
    private let clock: AppClock
    private let calendar: Calendar
    private var lastRun: Task<Void, Never>?

    init(
        store: PlayerStore,
        scheduler: any NotificationScheduling,
        clock: AppClock,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.store = store
        self.scheduler = scheduler
        self.clock = clock
        self.calendar = calendar
    }

    /// Plant alle Mitteilungen neu. Die Laeufe folgen strikt nacheinander:
    /// `.task`, Szenenwechsel und Teepause koennen gleichzeitig ausloesen, und
    /// ein aelterer Plan darf keinen Eintrag des neueren ueberschreiben.
    func reschedule() async {
        let previous = lastRun
        let run = Task {
            await previous?.value
            await performReschedule()
        }
        lastRun = run
        await run.value
    }

    /// Vor Abschluss des Erststarts passiert nichts (es gibt noch keine
    /// Entscheidung und keine Abfrage).
    private func performReschedule() async {
        guard store.onboardingCompleted else { return }
        if store.reminderTime == nil, !store.reminderOff {
            // Keine Uhrzeit: vorlaeufige Erlaubnis, damit die Einladung ankommt.
            await scheduler.requestAuthorization(.provisional)
        }
        let reminders = ReminderPlanner.plan(
            now: clock.now(),
            lastActiveDay: store.lastActiveDay,
            teaBreakDoneToday: store.isTeaBreakCompletedToday,
            time: store.reminderTime,
            isOff: store.reminderOff,
            invitationDate: store.invitationDate,
            calendar: calendar
        )
        if store.invitationDate == nil,
           let invitation = reminders.first(where: { $0.kind == .invitation }) {
            store.setInvitationDate(invitation.date)
        }
        await scheduler.replaceAll(with: reminders)
    }

    /// Erststart oder Profil: Uhrzeit uebernehmen, dann echte Abfrage, dann planen.
    /// Die Zeit bleibt auch gespeichert, wenn die Abfrage abgelehnt wird.
    func confirmReminderTime(_ time: ReminderTime) async {
        store.setReminderTime(time)
        store.completeOnboarding()
        await scheduler.requestAuthorization(.standard)
        await reschedule()
    }

    /// Erststart: "Ohne Erinnerung" - keine Uhrzeit, keine Abfrage.
    func skipReminderTime() async {
        store.completeOnboarding()
        await reschedule()
    }

    /// Profil: aktueller Berechtigungsstatus fuer den Ablehnungs-Hinweis.
    func authorizationState() async -> ReminderAuthorizationState {
        await scheduler.authorizationState()
    }

    /// Profil: Erinnerung ausschalten (plant nichts mehr, auch keine Einladung).
    func turnOff() async {
        store.setReminderOff(true)
        await reschedule()
    }
}

// MARK: - Umgebung

private struct ReminderCoordinatorKey: EnvironmentKey {
    static let defaultValue: ReminderCoordinator? = nil
}

extension EnvironmentValues {
    /// `nil` in Vorschauen; die App setzt den echten Koordinator.
    var reminderCoordinator: ReminderCoordinator? {
        get { self[ReminderCoordinatorKey.self] }
        set { self[ReminderCoordinatorKey.self] = newValue }
    }
}
