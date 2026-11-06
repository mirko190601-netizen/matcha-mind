// ReminderPlanner.swift
// Erinnerung (MASTER-PROMPT.md, Block B4 Aufgabe 7): reine Planungslogik ohne
// UserNotifications. Sie liefert nur, WANN WELCHE Art Mitteilung faellig ist;
// Texte und das Eintragen beim System machen `ReminderTexts` und
// `NotificationScheduling`.
//
// Regeln:
// - "Aus" im Profil: nichts, auch keine Einladung.
// - Mit Uhrzeit: heute (Zeit noch nicht vorbei, Teepause offen), Tag 1 und 2
//   nach dem letzten aktiven Tag normal, Tag 3 und 7 je eine
//   Rueckkehr-Nachricht, Tage 4-6 und ab Tag 8 nichts.
// - Ohne Uhrzeit: genau eine Einladung um 17:00 (naechster Termin). Ihr
//   Datum wird gespeichert, damit nie eine zweite folgt. Hat der Spieler an
//   dem Tag die Teepause erledigt, verfaellt sie. Keine Rueckkehr-Nachrichten.
// Alle Mitteilungen sind Einmal-Termine; bei jedem Planen werden alle
// offenen ersetzt.

import Foundation

/// Gewaehlte Uhrzeit der Erinnerung (lokale Zeit).
struct ReminderTime: Equatable, Sendable {
    let hour: Int
    let minute: Int

    /// Vorschlag im Erststart.
    static let suggested = ReminderTime(hour: 12, minute: 30)
}

enum ReminderKind: Equatable, Sendable {
    /// Taegliche Erinnerung zur gewaehlten Zeit.
    case daily
    /// Rueckkehr-Nachricht am dritten Tag nach dem letzten aktiven Tag.
    case returnDay3
    /// Rueckkehr-Nachricht am siebten Tag nach dem letzten aktiven Tag.
    case returnDay7
    /// Einmalige Einladung um 17:00, wenn keine Zeit gewaehlt wurde.
    case invitation
}

struct PlannedReminder: Equatable, Sendable {
    let date: Date
    let kind: ReminderKind
}

enum ReminderPlanner {
    /// Uhrzeit der Einladung.
    static let invitationHour = 17

    /// Tage nach dem letzten aktiven Tag und die Art der Mitteilung.
    /// Offset 0 ist der letzte aktive Tag selbst (relevant am Installationstag,
    /// solange noch keine Teepause erledigt ist).
    private static let schedule: [(offset: Int, kind: ReminderKind)] = [
        (0, .daily),
        (1, .daily),
        (2, .daily),
        (3, .returnDay3),
        (7, .returnDay7),
    ]

    /// - Parameters:
    ///   - now: aktueller Zeitpunkt.
    ///   - lastActiveDay: ein Zeitpunkt am letzten aktiven Tag (sonst am Installationstag).
    ///   - teaBreakDoneToday: Teepause heute erledigt?
    ///   - time: gewaehlte Uhrzeit, `nil` = keine gewaehlt.
    ///   - isOff: Erinnerung im Profil ausgeschaltet.
    ///   - invitationDate: bereits geplante Einladung (gespeichertes Datum), sonst `nil`.
    static func plan(
        now: Date,
        lastActiveDay: Date,
        teaBreakDoneToday: Bool,
        time: ReminderTime?,
        isOff: Bool,
        invitationDate: Date?,
        calendar: Calendar
    ) -> [PlannedReminder] {
        guard !isOff else { return [] }
        if let time {
            return timedReminders(
                now: now,
                lastActiveDay: lastActiveDay,
                teaBreakDoneToday: teaBreakDoneToday,
                time: time,
                calendar: calendar
            )
        }
        return invitationReminders(
            now: now,
            teaBreakDoneToday: teaBreakDoneToday,
            invitationDate: invitationDate,
            calendar: calendar
        )
    }

    private static func timedReminders(
        now: Date,
        lastActiveDay: Date,
        teaBreakDoneToday: Bool,
        time: ReminderTime,
        calendar: Calendar
    ) -> [PlannedReminder] {
        let lastDay = calendar.startOfDay(for: lastActiveDay)
        var result: [PlannedReminder] = []
        for step in schedule {
            guard let day = calendar.date(byAdding: .day, value: step.offset, to: lastDay),
                  let fire = calendar.date(
                      bySettingHour: time.hour, minute: time.minute, second: 0, of: day
                  ) else { continue }
            guard fire > now else { continue }
            if teaBreakDoneToday, calendar.isDate(fire, inSameDayAs: now) { continue }
            result.append(PlannedReminder(date: fire, kind: step.kind))
        }
        return result
    }

    private static func invitationReminders(
        now: Date,
        teaBreakDoneToday: Bool,
        invitationDate: Date?,
        calendar: Calendar
    ) -> [PlannedReminder] {
        let target: Date
        if let invitationDate {
            // Schon einmal geplant: nur erhalten, solange sie noch aussteht.
            guard invitationDate > now else { return [] }
            target = invitationDate
        } else {
            guard let next = nextInvitationSlot(after: now, calendar: calendar) else { return [] }
            target = next
        }
        if teaBreakDoneToday, calendar.isDate(target, inSameDayAs: now) { return [] }
        return [PlannedReminder(date: target, kind: .invitation)]
    }

    /// Naechster 17-Uhr-Termin nach `now` (heute, sonst morgen).
    private static func nextInvitationSlot(after now: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        for dayOffset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let slot = calendar.date(bySettingHour: invitationHour, minute: 0, second: 0, of: day),
                  slot > now else { continue }
            return slot
        }
        return nil
    }
}
