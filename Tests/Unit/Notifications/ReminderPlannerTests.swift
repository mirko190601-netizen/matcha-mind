import XCTest
@testable import MatchaMind

/// Prüft `ReminderPlanner` (`Notifications/ReminderPlanner.swift`): alle
/// Regeln der Erinnerung (Tag 1/2 normal, Tag 3 und 7 Rückkehr, Tage 4-6 und
/// ab 8 nichts, heute entfällt nach der Teepause, Einladung nur einmal,
/// "Aus" plant nichts). Sommerzeit und Zeitzonenwechsel folgen in Paket F.
///
/// Fester Kalender Europe/Berlin; der letzte aktive Tag ist in den meisten
/// Fällen der 10. Januar 2026.
final class ReminderPlannerTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    /// Januar 2026 zu einer Uhrzeit.
    private func january(_ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }

    private let noon = ReminderTime(hour: 12, minute: 30)

    private func plan(
        now: Date,
        lastActiveDay: Date? = nil,
        done: Bool = false,
        time: ReminderTime?,
        off: Bool = false,
        invitation: Date? = nil
    ) -> [PlannedReminder] {
        ReminderPlanner.plan(
            now: now,
            lastActiveDay: lastActiveDay ?? january(10),
            teaBreakDoneToday: done,
            time: time,
            isOff: off,
            invitationDate: invitation,
            calendar: calendar
        )
    }

    private func reminder(_ day: Int, _ kind: ReminderKind, hour: Int = 12, minute: Int = 30) -> PlannedReminder {
        PlannedReminder(date: january(day, hour, minute), kind: kind)
    }

    // MARK: - Mit Uhrzeit

    func testInstallDayBeforeTimeSchedulesTodayAndFollowingDays() {
        let result = plan(now: january(10, 9), time: noon)

        XCTAssertEqual(result, [
            reminder(10, .daily),
            reminder(11, .daily),
            reminder(12, .daily),
            reminder(13, .returnDay3),
            reminder(17, .returnDay7),
        ])
    }

    func testTimeAlreadyPassedSkipsToday() {
        let result = plan(now: january(10, 13), time: noon)

        XCTAssertEqual(result.first, reminder(11, .daily))
        XCTAssertEqual(result.count, 4)
    }

    func testTeaBreakDoneTodayDropsTodaysReminder() {
        let result = plan(now: january(10, 9), done: true, time: noon)

        XCTAssertEqual(result, [
            reminder(11, .daily),
            reminder(12, .daily),
            reminder(13, .returnDay3),
            reminder(17, .returnDay7),
        ])
    }

    func testDayOneAndTwoAfterLastActiveDayAreNormal() {
        let dayOne = plan(now: january(11, 9), time: noon)
        XCTAssertEqual(Array(dayOne.prefix(2)), [reminder(11, .daily), reminder(12, .daily)])

        let dayTwo = plan(now: january(12, 9), time: noon)
        XCTAssertEqual(dayTwo.first, reminder(12, .daily))
    }

    func testDayThreeIsReturnMessageNotDaily() {
        let result = plan(now: january(13, 9), time: noon)

        XCTAssertEqual(result, [
            reminder(13, .returnDay3),
            reminder(17, .returnDay7),
        ])
    }

    func testDaysFourToSixScheduleNothingExceptTheDaySevenReturn() {
        for day in 14...16 {
            let result = plan(now: january(day, 9), time: noon)
            XCTAssertEqual(result, [reminder(17, .returnDay7)], "Tag \(day)")
        }
    }

    func testDaySevenIsReturnMessage() {
        let result = plan(now: january(17, 9), time: noon)

        XCTAssertEqual(result, [reminder(17, .returnDay7)])
    }

    func testFromDayEightNothingIsScheduled() {
        for day in [18, 19, 25] {
            XCTAssertEqual(plan(now: january(day, 9), time: noon), [], "Tag \(day)")
        }
        // Auch am siebten Tag, wenn die Zeit schon vorbei ist.
        XCTAssertEqual(plan(now: january(17, 13), time: noon), [])
    }

    func testAllRemindersLieInTheFuture() {
        let now = january(11, 12, 30)
        let result = plan(now: now, time: noon)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.date > now })
    }

    func testNoInvitationAndNoDuplicatesWithTime() {
        let result = plan(now: january(10, 9), time: noon)

        XCTAssertFalse(result.contains { $0.kind == .invitation })
        XCTAssertEqual(Set(result.map(\.date)).count, result.count)
    }

    func testReminderFiresAtChosenHourAndMinute() {
        let result = plan(now: january(10, 9), time: ReminderTime(hour: 7, minute: 5))

        XCTAssertEqual(result.first?.date, january(11, 7, 5))
    }

    // MARK: - Aus

    func testOffSchedulesNothingWithTime() {
        XCTAssertEqual(plan(now: january(10, 9), time: noon, off: true), [])
    }

    func testOffSchedulesNothingWithoutTimeNotEvenAnInvitation() {
        XCTAssertEqual(plan(now: january(10, 9), time: nil, off: true), [])
    }

    // MARK: - Einladung ohne Uhrzeit

    func testWithoutTimeExactlyOneInvitationAtFivePm() {
        let result = plan(now: january(10, 10), time: nil)

        XCTAssertEqual(result, [PlannedReminder(date: january(10, 17), kind: .invitation)])
    }

    func testInvitationAfterFivePmMovesToTomorrow() {
        let result = plan(now: january(10, 18), time: nil)

        XCTAssertEqual(result, [PlannedReminder(date: january(11, 17), kind: .invitation)])
    }

    func testPendingInvitationIsKeptAtItsStoredDate() {
        let stored = january(10, 17)
        let result = plan(now: january(10, 11), time: nil, invitation: stored)

        XCTAssertEqual(result, [PlannedReminder(date: stored, kind: .invitation)])
    }

    func testInvitationIsNeverScheduledASecondTime() {
        // Das gespeicherte Datum liegt in der Vergangenheit: die Einladung kam schon.
        let result = plan(now: january(11, 10), time: nil, invitation: january(10, 17))

        XCTAssertEqual(result, [])
    }

    func testInvitationLapsesWhenTeaBreakIsDoneThatDay() {
        XCTAssertEqual(plan(now: january(10, 10), done: true, time: nil), [])
        XCTAssertEqual(plan(now: january(10, 10), done: true, time: nil, invitation: january(10, 17)), [])
    }

    func testInvitationOnALaterDayIsKeptEvenIfTeaBreakIsDoneToday() {
        let tomorrow = january(11, 17)
        let result = plan(now: january(10, 18), done: true, time: nil, invitation: tomorrow)

        XCTAssertEqual(result, [PlannedReminder(date: tomorrow, kind: .invitation)])
    }

    func testNoReturnMessagesWithoutTime() {
        for day in [10, 13, 17] {
            let result = plan(now: january(day, 9), time: nil)
            XCTAssertTrue(result.allSatisfy { $0.kind == .invitation }, "Tag \(day)")
        }
    }
}
