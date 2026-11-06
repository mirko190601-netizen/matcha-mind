import XCTest
@testable import MatchaMind

/// Prüft die Profil-Logik: Ton- und Haptik-Schalter (auch nach Neustart),
/// `GameHaptics`, Anzeige der Erinnerung, Ablehnungs-Hinweis und Links.
@MainActor
final class ProfileSettingsTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func makeClock() -> FixedClock {
        FixedClock(date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 12))!)
    }

    private func makeStore() throws -> PlayerStore {
        let container = try PlayerStore.makeContainer(inMemory: true)
        return PlayerStore(container: container, clock: makeClock(), calendar: calendar)
    }

    private final class Counter {
        var value = 0
    }

    override func tearDown() async throws {
        GameHaptics.backing = nil
        GameHaptics.trigger = { }
        try await super.tearDown()
    }

    // MARK: - Schalter

    func testSoundAndHapticsAreOnByDefault() throws {
        let store = try makeStore()

        XCTAssertTrue(store.soundEnabled)
        XCTAssertTrue(store.hapticsEnabled)
    }

    func testSwitchesSurviveRestartWithFileContainer() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("matcha-mind-profile-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("player.store")

        do {
            let container = try PlayerStore.makeContainer(inMemory: false, url: storeURL)
            let store = PlayerStore(container: container, clock: makeClock(), calendar: calendar)
            store.setSoundEnabled(false)
            store.setHapticsEnabled(false)
        }

        let reopened = PlayerStore(
            container: try PlayerStore.makeContainer(inMemory: false, url: storeURL),
            clock: makeClock(),
            calendar: calendar
        )
        XCTAssertFalse(reopened.soundEnabled)
        XCTAssertFalse(reopened.hapticsEnabled)
    }

    func testSwitchesCanBeTurnedBackOn() throws {
        let store = try makeStore()
        store.setSoundEnabled(false)
        store.setHapticsEnabled(false)

        store.setSoundEnabled(true)
        store.setHapticsEnabled(true)

        XCTAssertTrue(store.soundEnabled)
        XCTAssertTrue(store.hapticsEnabled)
    }

    // MARK: - Haptik

    func testHitTriggersWhenHapticsAreOn() throws {
        let counter = Counter()
        GameHaptics.backing = try makeStore()
        GameHaptics.trigger = { counter.value += 1 }

        GameHaptics.hit()

        XCTAssertEqual(counter.value, 1)
    }

    func testHitTriggersNothingWhenHapticsAreOff() throws {
        let counter = Counter()
        let store = try makeStore()
        store.setHapticsEnabled(false)
        GameHaptics.backing = store
        GameHaptics.trigger = { counter.value += 1 }

        GameHaptics.hit()

        XCTAssertEqual(counter.value, 0)
    }

    func testHitTriggersNothingWithoutBacking() {
        let counter = Counter()
        GameHaptics.backing = nil
        GameHaptics.trigger = { counter.value += 1 }

        GameHaptics.hit()

        XCTAssertEqual(counter.value, 0)
    }

    // MARK: - Erinnerung im Profil

    func testReminderStatusShowsTimeOffOrNotChosen() {
        let time = ReminderTime(hour: 7, minute: 45)

        XCTAssertEqual(ProfileLogic.reminderStatus(time: time, isOff: false), .time(time))
        XCTAssertEqual(ProfileLogic.reminderStatus(time: time, isOff: true), .off)
        XCTAssertEqual(ProfileLogic.reminderStatus(time: nil, isOff: false), .notChosen)
        XCTAssertEqual(ProfileLogic.reminderStatus(time: nil, isOff: true), .off)
    }

    func testDeniedHintOnlyForAnActiveReminderWithDeniedPermission() {
        let active = ProfileLogic.ReminderStatus.time(ReminderTime(hour: 12, minute: 30))

        XCTAssertTrue(ProfileLogic.showsDeniedHint(status: active, authorization: .denied))
        XCTAssertFalse(ProfileLogic.showsDeniedHint(status: active, authorization: .allowed))
        XCTAssertFalse(ProfileLogic.showsDeniedHint(status: active, authorization: .notDetermined))
        XCTAssertFalse(ProfileLogic.showsDeniedHint(status: .off, authorization: .denied))
        XCTAssertFalse(ProfileLogic.showsDeniedHint(status: .notChosen, authorization: .denied))
    }

    func testDateForReminderTimeKeepsHourAndMinute() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 3))!

        let result = ProfileLogic.date(for: ReminderTime(hour: 7, minute: 45), now: now, calendar: calendar)

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 45)
    }

    func testCoordinatorPassesAuthorizationStateThrough() async throws {
        let store = try makeStore()
        let spy = SpyNotificationScheduler()
        let coordinator = ReminderCoordinator(store: store, scheduler: spy, clock: makeClock(), calendar: calendar)

        spy.state = .denied
        let denied = await coordinator.authorizationState()
        spy.state = .allowed
        let allowed = await coordinator.authorizationState()

        XCTAssertEqual(denied, .denied)
        XCTAssertEqual(allowed, .allowed)
    }

    func testNoopSchedulerReportsNoDecision() async {
        let state = await NoopNotificationScheduler().authorizationState()

        XCTAssertEqual(state, .notDetermined)
    }

    // MARK: - Links

    func testPrivacyPolicyLinkIsOneHttpsUrlWithoutEmail() throws {
        let url = try XCTUnwrap(AppLinks.privacyPolicy)

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.absoluteString, AppLinks.privacyPolicyString)
        XCTAssertFalse(AppLinks.privacyPolicyString.contains("@"))
    }
}
