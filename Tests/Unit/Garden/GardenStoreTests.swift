import XCTest
@testable import MatchaMind

/// Tau, Deko-Kauf und Wochenziel im `PlayerStore` (In-Memory, Europe/Berlin).
@MainActor
final class GardenStoreTests: XCTestCase {

    private let oneDay: TimeInterval = 24 * 60 * 60

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    /// Montag, 2026-01-05, mittags.
    private func makeClock() -> FixedClock {
        FixedClock(date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 12))!)
    }

    private func makeStore(clock: FixedClock) throws -> PlayerStore {
        let container = try PlayerStore.makeContainer(inMemory: true)
        return PlayerStore(container: container, clock: clock, calendar: calendar)
    }

    private func earn(_ store: PlayerStore, games: Int) {
        for _ in 0..<games {
            store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 8, misses: 2, duration: 60))
        }
    }

    // MARK: - Tau

    func testEachGameAddsTwelveDewToBothCounters() throws {
        let store = try makeStore(clock: makeClock())
        XCTAssertEqual(PlayerStore.dewPerGame, 12)

        earn(store, games: 1)
        XCTAssertEqual(store.dewDrops, 12)
        XCTAssertEqual(store.dewEarnedTotal, 12)

        earn(store, games: 2)
        XCTAssertEqual(store.dewDrops, 36)
        XCTAssertEqual(store.dewEarnedTotal, 36)
    }

    // MARK: - Kauf

    func testPurchaseSucceedsWithEnoughDewAndDeductsPrice() throws {
        let store = try makeStore(clock: makeClock())
        earn(store, games: 2) // 24 Tau

        XCTAssertTrue(store.purchaseDecoration(id: "stepping-stones"))
        XCTAssertEqual(store.dewDrops, 0)
        XCTAssertEqual(store.ownedDecorationIDs, ["stepping-stones"])
    }

    func testPurchaseFailsWithTooLittleDew() throws {
        let store = try makeStore(clock: makeClock())
        earn(store, games: 1) // 12 Tau

        XCTAssertFalse(store.purchaseDecoration(id: "stepping-stones"))
        XCTAssertEqual(store.dewDrops, 12)
        XCTAssertTrue(store.ownedDecorationIDs.isEmpty)
    }

    func testPurchaseTwiceIsRejected() throws {
        let store = try makeStore(clock: makeClock())
        earn(store, games: 5) // 60 Tau

        XCTAssertTrue(store.purchaseDecoration(id: "stepping-stones"))
        XCTAssertFalse(store.purchaseDecoration(id: "stepping-stones"))
        XCTAssertEqual(store.dewDrops, 36)
    }

    func testPurchaseOfUnknownItemIsRejected() throws {
        let store = try makeStore(clock: makeClock())
        earn(store, games: 3)

        XCTAssertFalse(store.purchaseDecoration(id: "unbekannt"))
        XCTAssertEqual(store.dewDrops, 36)
    }

    func testPurchaseDoesNotLowerEarnedTotal() throws {
        let store = try makeStore(clock: makeClock())
        earn(store, games: 2)

        store.purchaseDecoration(id: "stepping-stones")

        XCTAssertEqual(store.dewEarnedTotal, 24)
        XCTAssertEqual(store.dewDrops, 0)
    }

    // MARK: - Wochenziel

    func testActiveDaysThisWeekCountsOnlyCurrentWeek() throws {
        let clock = makeClock() // Montag
        let store = try makeStore(clock: clock)

        store.completeTeaBreak()
        clock.advance(by: oneDay)
        store.completeTeaBreak()
        clock.advance(by: oneDay)
        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysThisWeek, 3)
        XCTAssertEqual(store.bonusBlossomCount, 0)

        // Mittwoch + 5 Tage = Montag der Folgewoche: Zaehler beginnt bei 0.
        clock.advance(by: 5 * oneDay)
        XCTAssertEqual(store.activeDaysThisWeek, 0)
        XCTAssertEqual(store.weekActiveDayStates, Array(repeating: false, count: 7))
    }

    func testBonusBlossomAtFourDaysOnlyOncePerWeek() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)

        for _ in 0..<4 {
            store.completeTeaBreak()
            clock.advance(by: oneDay)
        }
        XCTAssertEqual(store.activeDaysThisWeek, 4)
        XCTAssertEqual(store.bonusBlossomCount, 1)

        // Fuenfter Tag derselben Woche, doppelter Abschluss: keine zweite Bluete.
        store.completeTeaBreak()
        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysThisWeek, 5)
        XCTAssertEqual(store.bonusBlossomCount, 1)
    }

    func testThreeDaysGiveNoBlossomAndNewWeekCanEarnAgain() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)

        for _ in 0..<3 {
            store.completeTeaBreak()
            clock.advance(by: oneDay)
        }
        XCTAssertEqual(store.bonusBlossomCount, 0)

        clock.advance(by: 4 * oneDay) // Donnerstag + 4 Tage = naechster Montag
        for _ in 0..<4 {
            store.completeTeaBreak()
            clock.advance(by: oneDay)
        }
        XCTAssertEqual(store.bonusBlossomCount, 1)
    }

    func testWeekRolloverKeepsEarnedBlossom() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        for _ in 0..<4 {
            store.completeTeaBreak()
            clock.advance(by: oneDay)
        }
        clock.advance(by: 3 * oneDay) // Freitag + 3 Tage = Montag der Folgewoche

        XCTAssertEqual(store.bonusBlossomCount, 1)
        XCTAssertEqual(store.activeDaysThisWeek, 0)
    }
}
