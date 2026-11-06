import SwiftData
import XCTest
@testable import MatchaMind

// `UITestSeed` existiert nur in DEBUG-Builds (siehe MASTER-PROMPT.md
// Abschnitt 7.5) - dieser Test entsprechend auch.
#if DEBUG

/// Prueft die UI-Test-Spielstaende (`Progress/UITestSeed.swift`): Stufe,
/// Anzahl aktiver Tage, 80 % Genauigkeit, und dass die heutige Teepause das
/// Angebot ausloest, auch bei schlechtem Spiel am heutigen Tag.
@MainActor
final class UITestSeedTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func makeStore(seed: UITestSeed) throws -> PlayerStore {
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 9))!
        let container = try PlayerStore.makeContainer(inMemory: true)
        seed.populate(container: container, now: now, calendar: calendar)
        return PlayerStore(container: container, clock: FixedClock(date: now), calendar: calendar)
    }

    func testOolongSeedStartsAtSenchaWithThirteenActiveDays() throws {
        let store = try makeStore(seed: .promotionOolong)

        XCTAssertEqual(store.level, .sencha)
        XCTAssertEqual(store.highestLevel, .sencha)
        XCTAssertTrue(store.autoAdvance)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 13)
        XCTAssertFalse(store.isTeaBreakCompletedToday)
        XCTAssertNil(store.pendingPromotion(), "13 Tage reichen noch nicht")
    }

    func testMatchaSeedStartsAtOolongWithTwentyActiveDays() throws {
        let store = try makeStore(seed: .promotionMatcha)

        XCTAssertEqual(store.level, .oolong)
        XCTAssertEqual(store.highestLevel, .oolong)
        XCTAssertTrue(store.autoAdvance)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 20)
        XCTAssertFalse(store.isTeaBreakCompletedToday)
        XCTAssertNil(store.pendingPromotion(), "20 Tage reichen noch nicht")
    }

    func testTodaysTeaBreakOffersOolongFromOolongSeed() throws {
        let store = try makeStore(seed: .promotionOolong)
        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 10, misses: 0, duration: 60))

        XCTAssertEqual(store.completeTeaBreak(), .oolong)
    }

    func testTodaysTeaBreakOffersMatchaFromMatchaSeed() throws {
        let store = try makeStore(seed: .promotionMatcha)
        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 10, misses: 0, duration: 60))

        XCTAssertEqual(store.completeTeaBreak(), .matcha)
    }

    func testOfferSurvivesAWorstCaseTeaBreakWithOnlyMisses() throws {
        // Drei Spiele ohne einen Treffer und mit sehr vielen Fehlgriffen.
        for seed in UITestSeed.allCases {
            let store = try makeStore(seed: seed)
            for _ in 0..<3 {
                store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 0, misses: 450, duration: 75))
            }

            XCTAssertNotNil(store.completeTeaBreak(), "\(seed.rawValue): Angebot trotz schlechtem Tag")
        }
    }

    func testSeedAccuracyIsEightyPercent() {
        XCTAssertEqual(
            100 * UITestSeed.hitsPerDay,
            80 * (UITestSeed.hitsPerDay + UITestSeed.missesPerDay)
        )
    }

    func testAutoAdvanceOffBlocksTheOfferEvenWithSeed() throws {
        let store = try makeStore(seed: .promotionOolong)
        store.setAutoAdvance(false)
        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 10, misses: 0, duration: 60))

        XCTAssertNil(store.completeTeaBreak())
    }

    func testRawValuesMatchTheLaunchArgumentNames() {
        XCTAssertEqual(UITestSeed(rawValue: "promotion-oolong"), .promotionOolong)
        XCTAssertEqual(UITestSeed(rawValue: "promotion-matcha"), .promotionMatcha)
        XCTAssertNil(UITestSeed(rawValue: "unknown"))
    }
}

#endif
