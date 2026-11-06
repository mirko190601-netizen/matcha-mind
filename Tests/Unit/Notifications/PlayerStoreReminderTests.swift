import XCTest
@testable import MatchaMind

/// Prüft die Erinnerungs-Felder des `PlayerStore` und `DayKey.date(from:)`.
@MainActor
final class PlayerStoreReminderTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func january(_ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour))!
    }

    private func makeStore(clock: FixedClock) throws -> PlayerStore {
        let container = try PlayerStore.makeContainer(inMemory: true)
        return PlayerStore(container: container, clock: clock, calendar: calendar)
    }

    func testNewStoreHasNoReminderAndOnboardingOpen() throws {
        let store = try makeStore(clock: FixedClock(date: january(10, 12)))

        XCTAssertFalse(store.onboardingCompleted)
        XCTAssertNil(store.reminderTime)
        XCTAssertFalse(store.reminderOff)
        XCTAssertNil(store.invitationDate)
    }

    func testSettingTimeStoresItAndClearsOff() throws {
        let store = try makeStore(clock: FixedClock(date: january(10, 12)))
        store.setReminderOff(true)

        store.setReminderTime(ReminderTime(hour: 7, minute: 45))

        XCTAssertEqual(store.reminderTime, ReminderTime(hour: 7, minute: 45))
        XCTAssertFalse(store.reminderOff)
    }

    func testTurningOffKeepsTheStoredTime() throws {
        let store = try makeStore(clock: FixedClock(date: january(10, 12)))
        store.setReminderTime(ReminderTime(hour: 7, minute: 45))

        store.setReminderOff(true)

        XCTAssertTrue(store.reminderOff)
        XCTAssertEqual(store.reminderTime, ReminderTime(hour: 7, minute: 45))
    }

    func testOnboardingAndInvitationDateAreStored() throws {
        let store = try makeStore(clock: FixedClock(date: january(10, 12)))

        store.completeOnboarding()
        store.setInvitationDate(january(10, 17))

        XCTAssertTrue(store.onboardingCompleted)
        XCTAssertEqual(store.invitationDate, january(10, 17))
    }

    func testLastActiveDayIsInstallDayUntilATeaBreakIsDone() throws {
        let clock = FixedClock(date: january(10, 12))
        let store = try makeStore(clock: clock)

        XCTAssertEqual(store.lastActiveDay, january(10))

        clock.set(january(12, 9))
        XCTAssertEqual(store.lastActiveDay, january(10))

        store.completeTeaBreak()
        XCTAssertEqual(store.lastActiveDay, january(12))
    }

    func testDayKeyDateRoundTrip() {
        let date = DayKey.date(from: "2026-01-09", calendar: calendar)

        XCTAssertEqual(date, january(9))
        XCTAssertEqual(DayKey.string(for: date!, calendar: calendar), "2026-01-09")
    }

    func testDayKeyDateRejectsInvalidKeys() {
        XCTAssertNil(DayKey.date(from: "", calendar: calendar))
        XCTAssertNil(DayKey.date(from: "2026-01", calendar: calendar))
        XCTAssertNil(DayKey.date(from: "heute", calendar: calendar))
    }
}
