import XCTest
@testable import MatchaMind

/// Test-Double für `NotificationScheduling`: merkt sich Abfragen und die
/// zuletzt geplante Liste.
final class SpyNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var storedModes: [ReminderAuthorizationMode] = []
    private var storedPlans: [[PlannedReminder]] = []
    private var storedState: ReminderAuthorizationState = .notDetermined

    var authorizationModes: [ReminderAuthorizationMode] {
        lock.lock()
        defer { lock.unlock() }
        return storedModes
    }

    var plans: [[PlannedReminder]] {
        lock.lock()
        defer { lock.unlock() }
        return storedPlans
    }

    var state: ReminderAuthorizationState {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedState
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedState = newValue
        }
    }

    func authorizationState() async -> ReminderAuthorizationState {
        state
    }

    func requestAuthorization(_ mode: ReminderAuthorizationMode) async -> Bool {
        lock.lock()
        defer { lock.unlock() }
        storedModes.append(mode)
        return true
    }

    func replaceAll(with reminders: [PlannedReminder]) async {
        lock.lock()
        defer { lock.unlock() }
        storedPlans.append(reminders)
    }
}

/// Prüft `ReminderCoordinator` mit In-Memory-Store, fester Uhr (10. Januar
/// 2026, 12:00, Europe/Berlin) und dem Test-Double.
@MainActor
final class ReminderCoordinatorTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func january(_ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }

    private struct Fixture {
        let store: PlayerStore
        let spy: SpyNotificationScheduler
        let coordinator: ReminderCoordinator
    }

    private func makeFixture() throws -> Fixture {
        let clock = FixedClock(date: january(10, 12))
        let container = try PlayerStore.makeContainer(inMemory: true)
        let store = PlayerStore(container: container, clock: clock, calendar: calendar)
        let spy = SpyNotificationScheduler()
        let coordinator = ReminderCoordinator(store: store, scheduler: spy, clock: clock, calendar: calendar)
        return Fixture(store: store, spy: spy, coordinator: coordinator)
    }

    func testRescheduleBeforeOnboardingDoesNothing() async throws {
        let fixture = try makeFixture()

        await fixture.coordinator.reschedule()

        XCTAssertTrue(fixture.spy.authorizationModes.isEmpty)
        XCTAssertTrue(fixture.spy.plans.isEmpty)
    }

    func testSkippingAsksOnlyProvisionallyAndPlansOneInvitation() async throws {
        let fixture = try makeFixture()

        await fixture.coordinator.skipReminderTime()

        XCTAssertTrue(fixture.store.onboardingCompleted)
        XCTAssertNil(fixture.store.reminderTime)
        XCTAssertEqual(fixture.spy.authorizationModes, [.provisional])
        XCTAssertEqual(fixture.spy.plans.last, [PlannedReminder(date: january(10, 17), kind: .invitation)])
        XCTAssertEqual(fixture.store.invitationDate, january(10, 17))
    }

    func testInvitationStaysTheSameOnRepeatedPlanning() async throws {
        let fixture = try makeFixture()
        await fixture.coordinator.skipReminderTime()

        await fixture.coordinator.reschedule()
        await fixture.coordinator.reschedule()

        XCTAssertEqual(fixture.spy.plans.last, [PlannedReminder(date: january(10, 17), kind: .invitation)])
        XCTAssertEqual(fixture.store.invitationDate, january(10, 17))
    }

    func testConfirmingTimeStoresItAsksStandardAndPlansDailyReminders() async throws {
        let fixture = try makeFixture()

        await fixture.coordinator.confirmReminderTime(ReminderTime(hour: 12, minute: 30))

        XCTAssertTrue(fixture.store.onboardingCompleted)
        XCTAssertEqual(fixture.store.reminderTime, ReminderTime(hour: 12, minute: 30))
        XCTAssertEqual(fixture.spy.authorizationModes, [.standard])
        let kinds = fixture.spy.plans.last?.map(\.kind)
        XCTAssertEqual(kinds, [.daily, .daily, .daily, .returnDay3, .returnDay7])
        XCTAssertEqual(fixture.spy.plans.last?.first?.date, january(10, 12, 30))
    }

    func testChoosingATimeReplacesAPendingInvitation() async throws {
        let fixture = try makeFixture()
        await fixture.coordinator.skipReminderTime()

        await fixture.coordinator.confirmReminderTime(ReminderTime(hour: 18, minute: 0))

        XCTAssertFalse(fixture.spy.plans.last?.contains { $0.kind == .invitation } ?? true)
    }

    func testTurningOffPlansNothingAndSkipsAuthorization() async throws {
        let fixture = try makeFixture()
        await fixture.coordinator.confirmReminderTime(ReminderTime(hour: 12, minute: 30))

        await fixture.coordinator.turnOff()

        XCTAssertTrue(fixture.store.reminderOff)
        XCTAssertEqual(fixture.spy.plans.last, [])
        XCTAssertEqual(fixture.spy.authorizationModes, [.standard])
    }

    func testTurningOffWithoutTimePlansNoInvitation() async throws {
        let fixture = try makeFixture()
        fixture.store.completeOnboarding()

        await fixture.coordinator.turnOff()

        XCTAssertEqual(fixture.spy.plans.last, [])
        XCTAssertNil(fixture.store.invitationDate)
    }

    func testTeaBreakDoneTodayDropsTodayAfterRescheduling() async throws {
        let fixture = try makeFixture()
        await fixture.coordinator.confirmReminderTime(ReminderTime(hour: 12, minute: 30))
        XCTAssertEqual(fixture.spy.plans.last?.first?.date, january(10, 12, 30))

        fixture.store.completeTeaBreak()
        await fixture.coordinator.reschedule()

        XCTAssertEqual(fixture.spy.plans.last?.first?.date, january(11, 12, 30))
    }

    func testChoosingATimeAfterTurningOffSwitchesRemindersBackOn() async throws {
        let fixture = try makeFixture()
        await fixture.coordinator.turnOff()

        await fixture.coordinator.confirmReminderTime(ReminderTime(hour: 9, minute: 0))

        XCTAssertFalse(fixture.store.reminderOff)
        XCTAssertFalse(fixture.spy.plans.last?.isEmpty ?? true)
    }
}
