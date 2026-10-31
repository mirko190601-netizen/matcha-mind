import XCTest
@testable import MatchaMind

/// Reine Logik des Gartens: Wachstumsstufen, Deko-Katalog, ISO-Wochen.
final class GardenLogicTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: - GardenGrowth

    func testGrowthThresholds() {
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 0), 0)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 35), 0)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 36), 1)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 119), 1)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 120), 2)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 299), 2)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 300), 3)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 599), 3)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 600), 4)
        XCTAssertEqual(GardenGrowth.stage(dewEarnedTotal: 100_000), 4)
    }

    func testVisiblePlantCountGrowsAndIsClamped() {
        XCTAssertEqual(GardenGrowth.visiblePlantCount(stage: 0), 0)
        XCTAssertEqual(GardenGrowth.visiblePlantCount(stage: 4), 8)
        XCTAssertEqual(GardenGrowth.visiblePlantCount(stage: 9), 8)
        XCTAssertEqual(GardenGrowth.visiblePlantCount(stage: -1), 0)
    }

    // MARK: - DecorationCatalog

    func testCatalogPricesAndLookup() {
        let prices = Dictionary(uniqueKeysWithValues: DecorationCatalog.items.map { ($0.id, $0.price) })
        XCTAssertEqual(prices, [
            "stepping-stones": 24, "stone-lantern": 36, "bonsai": 48,
            "lantern-chain": 60, "moon-bridge-lantern": 84, "cherry-tree": 120,
        ])
        XCTAssertEqual(DecorationCatalog.item(id: "bonsai")?.price, 48)
        XCTAssertNil(DecorationCatalog.item(id: "unbekannt"))
    }

    func testEveryItemHasReadableName() {
        for item in DecorationCatalog.items {
            XCTAssertFalse(item.name.isEmpty)
            XCTAssertNotEqual(item.name, item.id)
        }
    }

    // MARK: - WeeklyGoal

    func testWeekKeyIsIsoWeekAcrossSundayMonday() {
        // 2026-01-04 ist Sonntag (Woche 53 von 2025), 2026-01-05 Montag (Woche 1).
        XCTAssertEqual(WeeklyGoal.weekKey(for: date(2026, 1, 4), calendar: calendar), "2025-W53")
        XCTAssertEqual(WeeklyGoal.weekKey(for: date(2026, 1, 5), calendar: calendar), "2026-W01")
        XCTAssertEqual(WeeklyGoal.weekKey(for: date(2026, 10, 26), calendar: calendar), "2026-W44")
    }

    func testDayKeysRunMondayToSunday() {
        let keys = WeeklyGoal.dayKeys(ofWeekContaining: date(2026, 1, 8), calendar: calendar)
        XCTAssertEqual(keys.first, "2026-01-05")
        XCTAssertEqual(keys.last, "2026-01-11")
        XCTAssertEqual(keys.count, 7)
    }

    func testIsReached() {
        XCTAssertFalse(WeeklyGoal.isReached(activeDays: 3, goal: 4))
        XCTAssertTrue(WeeklyGoal.isReached(activeDays: 4, goal: 4))
    }
}
