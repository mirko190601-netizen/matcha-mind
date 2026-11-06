import XCTest
@testable import MatchaMind

/// `ReminderPlanner` bei Zeitzonenwechsel und Sommerzeit (Europe/Berlin,
/// 29.03.2026 und 25.10.2026): die gewaehlte Uhrzeit bleibt lokale Uhrzeit,
/// L+3 und L+7 fallen auf die richtigen Kalendertage.
final class ReminderPlannerTimeTests: XCTestCase {

    private func makeCalendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private var berlin: Calendar { makeCalendar("Europe/Berlin") }

    private func local(
        _ calendar: Calendar, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, year: Int = 2026
    ) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func plan(
        now: Date, lastActive: Date, time: ReminderTime, calendar: Calendar
    ) -> [PlannedReminder] {
        ReminderPlanner.plan(
            now: now,
            lastActiveDay: lastActive,
            teaBreakDoneToday: false,
            time: time,
            isOff: false,
            invitationDate: nil,
            calendar: calendar
        )
    }

    private func components(_ date: Date, _ calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.month, .day, .hour, .minute], from: date)
    }

    // MARK: - Zeitzonenwechsel

    func testPlansLocalTimeInTheNewTimeZoneAfterTravel() {
        let losAngeles = makeCalendar("America/Los_Angeles")
        let tokyo = makeCalendar("Asia/Tokyo")
        let noon = ReminderTime(hour: 12, minute: 30)
        // 10.01.2026 20:00 Berlin = 11:00 Los Angeles = 11.01. 04:00 Tokio.
        let now = local(berlin, 1, 10, 20)

        for calendar in [berlin, losAngeles, tokyo] {
            let reminders = plan(now: now, lastActive: calendar.startOfDay(for: now), time: noon, calendar: calendar)
            XCTAssertFalse(reminders.isEmpty)
            for reminder in reminders {
                let parts = components(reminder.date, calendar)
                XCTAssertEqual(parts.hour, 12, "Uhrzeit bleibt lokal in \(calendar.timeZone.identifier)")
                XCTAssertEqual(parts.minute, 30)
                XCTAssertGreaterThan(reminder.date, now)
            }
        }
    }

    func testTravelWestMovesTodaysReminderIntoTheFuture() {
        let losAngeles = makeCalendar("America/Los_Angeles")
        let noon = ReminderTime(hour: 12, minute: 30)
        let now = local(berlin, 1, 10, 20) // in Los Angeles erst 11:00

        let inBerlin = plan(now: now, lastActive: berlin.startOfDay(for: now), time: noon, calendar: berlin)
        let inLosAngeles = plan(now: now, lastActive: losAngeles.startOfDay(for: now), time: noon, calendar: losAngeles)

        XCTAssertEqual(components(inBerlin[0].date, berlin).day, 11, "In Berlin ist 12:30 heute vorbei")
        XCTAssertEqual(components(inLosAngeles[0].date, losAngeles).day, 10, "In Los Angeles steht 12:30 noch aus")
        XCTAssertEqual(inLosAngeles[0].kind, .daily)
    }

    // MARK: - Sommerzeit Fruehjahr (29.03.2026)

    func testNoonStaysNoonLocalAcrossSpringForward() {
        let noon = ReminderTime(hour: 12, minute: 30)
        // Letzter aktiver Tag Do 26.03.: L+1 Fr, L+2 Sa, L+3 So (Umstellung), L+7 Do 02.04.
        let reminders = plan(
            now: local(berlin, 3, 26, 13), lastActive: local(berlin, 3, 26), time: noon, calendar: berlin
        )

        XCTAssertEqual(reminders, [
            PlannedReminder(date: local(berlin, 3, 27, 12, 30), kind: .daily),
            PlannedReminder(date: local(berlin, 3, 28, 12, 30), kind: .daily),
            PlannedReminder(date: local(berlin, 3, 29, 12, 30), kind: .returnDay3),
            PlannedReminder(date: local(berlin, 4, 2, 12, 30), kind: .returnDay7),
        ])
    }

    func testReturnDaysThreeAndSevenLandOnTheRightCalendarDaysInSpring() {
        let noon = ReminderTime(hour: 12, minute: 30)
        // Letzter aktiver Tag Fr 27.03.: L+3 = Mo 30.03., L+7 = Fr 03.04.
        let reminders = plan(
            now: local(berlin, 3, 27, 13), lastActive: local(berlin, 3, 27), time: noon, calendar: berlin
        )

        let returnDay3 = reminders.first { $0.kind == .returnDay3 }
        let returnDay7 = reminders.first { $0.kind == .returnDay7 }
        XCTAssertEqual(returnDay3.map { components($0.date, berlin) }?.day, 30)
        XCTAssertEqual(returnDay3.map { components($0.date, berlin) }?.month, 3)
        XCTAssertEqual(returnDay7.map { components($0.date, berlin) }?.day, 3)
        XCTAssertEqual(returnDay7.map { components($0.date, berlin) }?.month, 4)
    }

    func testTwoThirtyOnSpringForwardDayYieldsValidAppointmentThatDay() {
        // 02:30 gibt es am 29.03.2026 nicht (02:00 springt auf 03:00).
        let early = ReminderTime(hour: 2, minute: 30)
        let now = local(berlin, 3, 27, 13)
        let reminders = plan(now: now, lastActive: local(berlin, 3, 27), time: early, calendar: berlin)

        let onSwitchDay = reminders.filter { components($0.date, berlin).day == 29 && components($0.date, berlin).month == 3 }
        XCTAssertEqual(onSwitchDay.count, 1, "Genau ein Termin am Umstellungstag")
        let parts = onSwitchDay.first.map { components($0.date, berlin) }
        XCTAssertGreaterThanOrEqual(parts?.hour ?? 0, 3, "Der Termin liegt nach der Luecke")
        XCTAssertLessThan(parts?.hour ?? 99, 4)
        XCTAssertGreaterThan(onSwitchDay.first?.date ?? .distantPast, now)
        // Alle uebrigen Tage bleiben bei 02:30.
        for reminder in reminders where components(reminder.date, berlin).day != 29 {
            XCTAssertEqual(components(reminder.date, berlin).hour, 2)
            XCTAssertEqual(components(reminder.date, berlin).minute, 30)
        }
        // Strikt aufsteigend, keine doppelten Termine.
        XCTAssertEqual(reminders.map(\.date), reminders.map(\.date).sorted())
        XCTAssertEqual(Set(reminders.map(\.date)).count, reminders.count)
    }

    // MARK: - Sommerzeit Herbst (25.10.2026)

    func testNoonStaysNoonLocalAcrossFallBack() {
        let noon = ReminderTime(hour: 12, minute: 30)
        // Letzter aktiver Tag Do 22.10.: L+1 Fr, L+2 Sa, L+3 So (Umstellung), L+7 Do 29.10.
        let reminders = plan(
            now: local(berlin, 10, 22, 13), lastActive: local(berlin, 10, 22), time: noon, calendar: berlin
        )

        XCTAssertEqual(reminders, [
            PlannedReminder(date: local(berlin, 10, 23, 12, 30), kind: .daily),
            PlannedReminder(date: local(berlin, 10, 24, 12, 30), kind: .daily),
            PlannedReminder(date: local(berlin, 10, 25, 12, 30), kind: .returnDay3),
            PlannedReminder(date: local(berlin, 10, 29, 12, 30), kind: .returnDay7),
        ])
    }

    func testAmbiguousTwoThirtyOnFallBackDayIsScheduledExactlyOnce() {
        // 02:30 kommt am 25.10.2026 zweimal vor (CEST und CET).
        let early = ReminderTime(hour: 2, minute: 30)
        let now = local(berlin, 10, 23, 13)
        let reminders = plan(now: now, lastActive: local(berlin, 10, 22), time: early, calendar: berlin)

        let onSwitchDay = reminders.filter { components($0.date, berlin).day == 25 && components($0.date, berlin).month == 10 }
        XCTAssertEqual(onSwitchDay.count, 1)
        XCTAssertEqual(onSwitchDay.first.flatMap { components($0.date, berlin).hour }, 2)
        XCTAssertEqual(onSwitchDay.first.flatMap { components($0.date, berlin).minute }, 30)
    }

    func testReturnDaysThreeAndSevenLandOnTheRightCalendarDaysInAutumn() {
        let noon = ReminderTime(hour: 12, minute: 30)
        // Letzter aktiver Tag Sa 24.10.: L+3 = Di 27.10., L+7 = Sa 31.10.
        let reminders = plan(
            now: local(berlin, 10, 24, 13), lastActive: local(berlin, 10, 24), time: noon, calendar: berlin
        )

        XCTAssertEqual(reminders.first { $0.kind == .returnDay3 }?.date, local(berlin, 10, 27, 12, 30))
        XCTAssertEqual(reminders.first { $0.kind == .returnDay7 }?.date, local(berlin, 10, 31, 12, 30))
    }
}
