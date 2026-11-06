// NotificationScheduling.swift
// Erinnerung (MASTER-PROMPT.md, Block B4 Aufgabe 7): schmale Schnittstelle zum
// System, damit Logik und Tests nicht an `UNUserNotificationCenter` haengen.
// Die echte Variante legt nur lokale Einmal-Mitteilungen an (nie `repeats`)
// und ersetzt bei jedem Planen alle offenen.

import Foundation
import UserNotifications

/// Wie die Mitteilungs-Erlaubnis angefragt wird.
enum ReminderAuthorizationMode: Equatable, Sendable {
    /// Ohne gewaehlte Uhrzeit: vorlaeufige Erlaubnis, kein Dialog, stille
    /// Zustellung (damit die 17-Uhr-Einladung ankommen kann).
    case provisional
    /// Nach dem Waehlen einer Uhrzeit: echte Abfrage (Hinweis und Ton).
    case standard
}

/// Wie das System Mitteilungen gerade behandelt (fuer den Hinweis im Profil).
enum ReminderAuthorizationState: Equatable, Sendable {
    /// Noch keine Entscheidung (auch vorlaeufige Erlaubnis zaehlt hier nicht als Ablehnung).
    case notDetermined
    /// Mitteilungen duerfen zugestellt werden.
    case allowed
    /// In den iOS-Einstellungen ausgeschaltet.
    case denied
}

protocol NotificationScheduling: Sendable {
    /// Fragt die Erlaubnis an; liefert, ob Mitteilungen zugestellt werden duerfen.
    @discardableResult
    func requestAuthorization(_ mode: ReminderAuthorizationMode) async -> Bool
    /// Ersetzt alle offenen Mitteilungen durch genau diese.
    func replaceAll(with reminders: [PlannedReminder]) async
    /// Aktueller Berechtigungsstatus, ohne eine Abfrage auszuloesen.
    func authorizationState() async -> ReminderAuthorizationState
}

/// Wird genutzt, wenn der Erststart uebersprungen ist (UI-Tests), damit dort
/// nichts beim System landet.
struct NoopNotificationScheduler: NotificationScheduling {
    func requestAuthorization(_ mode: ReminderAuthorizationMode) async -> Bool { false }
    func replaceAll(with reminders: [PlannedReminder]) async {}
    func authorizationState() async -> ReminderAuthorizationState { .notDetermined }
}

/// Echte Umsetzung ueber `UNUserNotificationCenter`. Das Center wird in jeder
/// Methode frisch geholt, damit der Typ ohne gespeicherte nicht-Sendable
/// Werte `Sendable` bleibt.
struct SystemNotificationScheduler: NotificationScheduling {
    let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func requestAuthorization(_ mode: ReminderAuthorizationMode) async -> Bool {
        let center = UNUserNotificationCenter.current()
        var options: UNAuthorizationOptions = [.alert, .sound]
        if mode == .provisional {
            options.insert(.provisional)
        }
        do {
            return try await center.requestAuthorization(options: options)
        } catch {
            return false
        }
    }

    func authorizationState() async -> ReminderAuthorizationState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        default:
            return .allowed
        }
    }

    func replaceAll(with reminders: [PlannedReminder]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for (index, reminder) in reminders.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = ReminderTexts.title
            content.body = ReminderTexts.body(for: reminder.kind)
            content.sound = .default
            // Lokale Datumsteile ohne Zeitzone: die Mitteilung gilt als
            // Wanduhrzeit des Geraets, auch nach einem Zeitzonenwechsel.
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: reminder.date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "reminder.\(index)", content: content, trigger: trigger
            )
            try? await center.add(request)
        }
    }
}

/// Texte der Mitteilungen: Neugier statt Druck, kein Zaehler, keine
/// Gesundheitsversprechen.
enum ReminderTexts {
    static var title: String {
        String(localized: "notification.title", defaultValue: "Matcha Mind")
    }

    static func body(for kind: ReminderKind) -> String {
        switch kind {
        case .daily:
            String(localized: "notification.daily.body", defaultValue: "Im Teegarten ist etwas aufgeblüht. Magst du nachsehen?")
        case .returnDay3:
            String(localized: "notification.return3.body", defaultValue: "Im Bambushain raschelt es. Magst du mal reinschauen?")
        case .returnDay7:
            String(localized: "notification.return7.body", defaultValue: "Der Fuchs war wieder im Garten. Schau gern vorbei, wenn du Lust hast.")
        case .invitation:
            String(localized: "notification.invitation.body", defaultValue: "Wenn du magst: Eine kleine Teepause im Garten wartet auf dich.")
        }
    }
}
