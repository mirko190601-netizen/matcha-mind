import XCTest
@testable import MatchaMind

/// Prüft die Verlaufs-Auswertung (`HistoryCalculator`) und ihre Anbindung im
/// `PlayerStore`: Wochen (ISO, Jahreswechsel), Genauigkeit je Bereich der
/// letzten vier Wochen und das Schreiben der `ResultRecord`s.
@MainActor
final class HistoryTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func makeStore(clock: FixedClock) throws -> PlayerStore {
        let container = try PlayerStore.makeContainer(inMemory: true)
        return PlayerStore(container: container, clock: clock, calendar: calendar)
    }

    private func summary(_ day: String, _ area: GameArea, hits: Int, misses: Int) -> ResultSummary {
        ResultSummary(dayKey: day, areaRaw: area.rawValue, hits: hits, misses: misses)
    }

    // MARK: - ResultRecord

    func testRecordGameResultWritesResultWithAreaFromCatalog() throws {
        let store = try makeStore(clock: FixedClock(date: date(2026, 1, 10)))
        let expected = GameCatalog.allGames.first { $0.id == "teapot-row" }?.area

        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 6, misses: 2, duration: 60))

        XCTAssertEqual(store.resultCount, 1)
        XCTAssertEqual(store.areaAccuracy.first?.area, expected)
        XCTAssertEqual(store.areaAccuracy.first?.percent, 75)
    }

    func testUnknownGameWritesNoResultButStillCountsTheDay() throws {
        let store = try makeStore(clock: FixedClock(date: date(2026, 1, 10)))

        store.recordGameResult(gameID: "does-not-exist", result: GameResult(hits: 6, misses: 2, duration: 60))

        XCTAssertEqual(store.resultCount, 0)
        XCTAssertTrue(store.areaAccuracy.isEmpty)
        XCTAssertEqual(store.dewEarnedTotal, PlayerStore.dewPerGame)
    }

    // MARK: - Wochen

    func testEmptyHistoryHasSixInactiveWeeksOfSevenDays() throws {
        let store = try makeStore(clock: FixedClock(date: date(2026, 1, 10)))

        let weeks = store.historyWeeks

        XCTAssertEqual(weeks.count, HistoryCalculator.weekCount)
        for week in weeks {
            XCTAssertEqual(week.dayKeys.count, 7)
            XCTAssertEqual(week.activeStates.count, 7)
            XCTAssertEqual(week.activeCount, 0)
        }
    }

    func testWeeksAcrossNewYearUseIsoWeeks() throws {
        // 10. Januar 2026 ist ein Samstag in 2026-W02.
        let store = try makeStore(clock: FixedClock(date: date(2026, 1, 10)))

        let weeks = store.historyWeeks

        XCTAssertEqual(weeks[0].weekKey, "2026-W02")
        XCTAssertEqual(weeks[0].dayKeys.first, "2026-01-05")
        XCTAssertEqual(weeks[0].dayKeys.last, "2026-01-11")
        XCTAssertEqual(weeks[1].weekKey, "2026-W01")
        XCTAssertEqual(weeks[1].dayKeys.first, "2025-12-29")
        XCTAssertEqual(weeks[1].dayKeys.last, "2026-01-04")
        XCTAssertEqual(weeks[2].weekKey, "2025-W52")
    }

    func testActiveDaysAreMarkedInTheirWeeks() throws {
        let clock = FixedClock(date: date(2025, 12, 31))
        let store = try makeStore(clock: clock)
        store.completeTeaBreak()
        clock.set(date(2026, 1, 10))
        store.completeTeaBreak()

        let weeks = store.historyWeeks

        // Woche 0 (5. bis 11. Januar): Samstag ist Index 5.
        XCTAssertEqual(weeks[0].activeStates, [false, false, false, false, false, true, false])
        // Woche 1 (29. Dezember bis 4. Januar): Mittwoch 31. ist Index 2.
        XCTAssertEqual(weeks[1].activeStates, [false, false, true, false, false, false, false])
        XCTAssertEqual(weeks[2].activeCount, 0)
    }

    func testPlayingWithoutTeaBreakIsNotAnActiveDay() throws {
        let store = try makeStore(clock: FixedClock(date: date(2026, 1, 10)))

        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 5, misses: 0, duration: 60))

        XCTAssertEqual(store.historyWeeks[0].activeCount, 0)
    }

    func testWeeksAreIndependentOfTimeOfDay() {
        let late = HistoryCalculator.weeks(
            now: date(2026, 1, 11, 23),
            completedDayKeys: ["2026-01-11"],
            calendar: calendar
        )
        XCTAssertEqual(late[0].weekKey, "2026-W02")
        XCTAssertEqual(late[0].activeStates.last, true)

        let early = HistoryCalculator.weeks(
            now: date(2026, 1, 12, 0),
            completedDayKeys: ["2026-01-11"],
            calendar: calendar
        )
        XCTAssertEqual(early[0].weekKey, "2026-W03")
        XCTAssertEqual(early[1].activeStates.last, true)
    }

    // MARK: - Genauigkeit

    func testPercentRoundsAndNeverDividesByZero() {
        XCTAssertEqual(HistoryCalculator.percent(hits: 0, attempts: 0), 0)
        XCTAssertEqual(HistoryCalculator.percent(hits: 1, attempts: 3), 33)
        XCTAssertEqual(HistoryCalculator.percent(hits: 2, attempts: 3), 67)
        XCTAssertEqual(HistoryCalculator.percent(hits: 8, attempts: 8), 100)
    }

    func testAccuracyOnlyCountsTheLastFourWeeks() {
        // 10. Januar 2026: Fenster beginnt am Montag, 15. Dezember 2025.
        let results = [
            summary("2025-12-14", .focus, hits: 0, misses: 10),
            summary("2025-12-15", .focus, hits: 3, misses: 1),
            summary("2026-01-10", .focus, hits: 3, misses: 1),
        ]

        let accuracy = HistoryCalculator.accuracy(results: results, now: date(2026, 1, 10), calendar: calendar)

        XCTAssertEqual(accuracy, [AreaAccuracy(area: .focus, percent: 75)])
    }

    func testAreasWithoutAttemptsAreLeftOut() {
        let results = [
            summary("2026-01-10", .logic, hits: 0, misses: 0),
            summary("2026-01-10", .mentalMath, hits: 0, misses: 4),
        ]

        let accuracy = HistoryCalculator.accuracy(results: results, now: date(2026, 1, 10), calendar: calendar)

        XCTAssertEqual(accuracy, [AreaAccuracy(area: .mentalMath, percent: 0)])
    }

    func testAccuracyFollowsAreaOrderAndSumsRounds() {
        let results = [
            summary("2026-01-09", .mentalMath, hits: 1, misses: 1),
            summary("2026-01-10", .mentalMath, hits: 3, misses: 1),
            summary("2026-01-10", .spatialMemory, hits: 2, misses: 0),
        ]

        let accuracy = HistoryCalculator.accuracy(results: results, now: date(2026, 1, 10), calendar: calendar)

        XCTAssertEqual(accuracy.map(\.area), [.spatialMemory, .mentalMath])
        XCTAssertEqual(accuracy.map(\.percent), [100, 67])
    }

    func testEmptyResultsGiveNoAccuracy() {
        XCTAssertTrue(HistoryCalculator.accuracy(results: [], now: date(2026, 1, 10), calendar: calendar).isEmpty)
    }

    func testResultsSurviveRestartWithFileContainer() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("matcha-mind-history-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("player.store")
        let clock = FixedClock(date: date(2026, 1, 10))

        do {
            let container = try PlayerStore.makeContainer(inMemory: false, url: storeURL)
            let store = PlayerStore(container: container, clock: clock, calendar: calendar)
            store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 3, misses: 1, duration: 60))
        }

        let reopened = PlayerStore(
            container: try PlayerStore.makeContainer(inMemory: false, url: storeURL),
            clock: clock,
            calendar: calendar
        )
        XCTAssertEqual(reopened.resultCount, 1)
        XCTAssertEqual(reopened.areaAccuracy.first?.percent, 75)
    }
}
