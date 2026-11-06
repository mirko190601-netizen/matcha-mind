import SwiftData
import XCTest
@testable import MatchaMind

/// Zeit-Randfaelle der Spielerdaten (MASTER-PROMPT.md, Block B4 Gate):
/// Mitternacht, Zeitzonenwechsel und Sommerzeit (Europe/Berlin, 29.03.2026 und
/// 25.10.2026). Immer feste Kalender und `FixedClock`; die Uhr wird mit `set`
/// auf lokale Zeitpunkte gestellt, nie um 24 Stunden verschoben (ein Tag mit
/// Umstellung hat 23 bzw. 25 Stunden).
@MainActor
final class TimeEdgeCaseTests: XCTestCase {

    private func makeCalendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private var berlin: Calendar { makeCalendar("Europe/Berlin") }

    private func local(
        _ calendar: Calendar, _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ))!
    }

    private func utc(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    private func makeStore(
        container: ModelContainer? = nil, clock: FixedClock, calendar: Calendar
    ) throws -> (store: PlayerStore, container: ModelContainer) {
        let resolved = try container ?? PlayerStore.makeContainer(inMemory: true)
        return (PlayerStore(container: resolved, clock: clock, calendar: calendar), resolved)
    }

    // MARK: - Mitternacht

    func testOneSecondBeforeAndAtMidnightAreDifferentDays() {
        let before = local(berlin, 2026, 1, 10, 23, 59, 59)
        let after = local(berlin, 2026, 1, 11, 0, 0, 0)

        XCTAssertEqual(DayKey.string(for: before, calendar: berlin), "2026-01-10")
        XCTAssertEqual(DayKey.string(for: after, calendar: berlin), "2026-01-11")
        XCTAssertNotEqual(DayKey.string(for: before, calendar: berlin), DayKey.string(for: after, calendar: berlin))
    }

    func testTeaBreaksAt2359And0001GiveTwoActiveDays() throws {
        let clock = FixedClock(date: local(berlin, 2026, 1, 10, 23, 59))
        let (store, _) = try makeStore(clock: clock, calendar: berlin)

        store.completeTeaBreak()
        XCTAssertTrue(store.isTeaBreakCompletedToday)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 1)

        clock.set(local(berlin, 2026, 1, 11, 0, 1))
        XCTAssertFalse(store.isTeaBreakCompletedToday, "Nach Mitternacht ist ein neuer Tag")
        store.completeTeaBreak()

        XCTAssertEqual(store.activeDaysAtCurrentLevel, 2)
    }

    func testWeeklyGoalCrossesSundayToMondayBoundary() throws {
        // Woche Mo 05.01. bis So 11.01.2026: vier aktive Tage, Ziel erreicht.
        let clock = FixedClock(date: local(berlin, 2026, 1, 5))
        let (store, _) = try makeStore(clock: clock, calendar: berlin)
        for day in [5, 6, 7] {
            clock.set(local(berlin, 2026, 1, day))
            store.completeTeaBreak()
        }
        clock.set(local(berlin, 2026, 1, 11, 23, 59))
        store.completeTeaBreak()

        XCTAssertEqual(store.activeDaysThisWeek, 4)
        XCTAssertEqual(store.weekActiveDayStates, [true, true, true, false, false, false, true])
        XCTAssertEqual(store.bonusBlossomCount, 1)

        // Zwei Minuten spaeter beginnt die neue Woche bei null; die Bluete bleibt.
        clock.set(local(berlin, 2026, 1, 12, 0, 1))
        XCTAssertEqual(store.activeDaysThisWeek, 0)
        XCTAssertEqual(store.weekActiveDayStates, Array(repeating: false, count: 7))
        XCTAssertEqual(store.bonusBlossomCount, 1)

        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysThisWeek, 1)
        XCTAssertEqual(store.weekActiveDayStates, [true, false, false, false, false, false, false])
    }

    // MARK: - Zeitzonenwechsel

    func testTravelWestKeepsOneActiveDayPerDayKeyAndAllData() throws {
        let losAngeles = makeCalendar("America/Los_Angeles")
        // 10.01.2026 20:00 in Berlin (= 11:00 in Los Angeles).
        let evening = local(berlin, 2026, 1, 10, 20)
        let clock = FixedClock(date: evening)

        let (first, container) = try makeStore(clock: clock, calendar: berlin)
        first.setLevel(.oolong)
        first.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 7, misses: 1, duration: 60))
        first.completeTeaBreak()
        XCTAssertEqual(DayKey.string(for: evening, calendar: berlin), "2026-01-10")

        // Reise nach Westen: gleicher Container, Kalender Los Angeles.
        let (traveller, _) = try makeStore(container: container, clock: clock, calendar: losAngeles)
        XCTAssertEqual(DayKey.string(for: evening, calendar: losAngeles), "2026-01-10")
        XCTAssertEqual(traveller.level, .oolong)
        XCTAssertEqual(traveller.dewEarnedTotal, PlayerStore.dewPerGame)
        XCTAssertEqual(traveller.resultCount, 1)
        XCTAssertTrue(traveller.isTeaBreakCompletedToday)

        // 11.01. 06:00 UTC ist in Berlin schon der 11., in Los Angeles noch der
        // 10. Gleicher Tagesschluessel: weiterhin genau ein aktiver Tag.
        clock.set(utc("2026-01-11T06:00:00Z"))
        XCTAssertEqual(DayKey.string(for: clock.now(), calendar: losAngeles), "2026-01-10")
        XCTAssertTrue(traveller.isTeaBreakCompletedToday)
        traveller.completeTeaBreak()
        XCTAssertEqual(traveller.activeDaysAtCurrentLevel, 1)
    }

    func testTravelEastStartsNewDayKeyWithoutLosingData() throws {
        let tokyo = makeCalendar("Asia/Tokyo")
        // 10.01.2026 20:00 in Berlin (= 11.01. 04:00 in Tokio).
        let evening = local(berlin, 2026, 1, 10, 20)
        let clock = FixedClock(date: evening)

        let (first, container) = try makeStore(clock: clock, calendar: berlin)
        first.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 5, misses: 0, duration: 60))
        first.completeTeaBreak()

        // Reise nach Osten: derselbe Zeitpunkt ist in Tokio schon der 11.
        let (traveller, _) = try makeStore(container: container, clock: clock, calendar: tokyo)
        XCTAssertEqual(DayKey.string(for: evening, calendar: tokyo), "2026-01-11")
        XCTAssertFalse(traveller.isTeaBreakCompletedToday, "Der 11. in Tokio ist ein neuer Tagesschluessel")
        XCTAssertEqual(traveller.dewEarnedTotal, PlayerStore.dewPerGame)
        XCTAssertEqual(traveller.resultCount, 1)

        traveller.completeTeaBreak()
        traveller.completeTeaBreak()
        XCTAssertEqual(traveller.activeDaysAtCurrentLevel, 2, "Zwei verschiedene Schluessel, je einmal gezaehlt")
        XCTAssertTrue(traveller.isTeaBreakCompletedToday)
    }

    // MARK: - Sommerzeit

    func testSpringForwardCountsEveryDayExactlyOnce() throws {
        // 29.03.2026: 02:00 springt auf 03:00. Tage 28. bis 31.03., am 29. mehrfach.
        let clock = FixedClock(date: local(berlin, 2026, 3, 28))
        let (store, _) = try makeStore(clock: clock, calendar: berlin)

        store.completeTeaBreak()
        // 01:59:59 CET und 03:00:00 CEST liegen eine Sekunde auseinander.
        clock.set(utc("2026-03-29T00:59:59Z"))
        XCTAssertEqual(DayKey.string(for: clock.now(), calendar: berlin), "2026-03-29")
        store.completeTeaBreak()
        clock.set(utc("2026-03-29T01:00:00Z"))
        XCTAssertEqual(DayKey.string(for: clock.now(), calendar: berlin), "2026-03-29")
        store.completeTeaBreak()
        clock.set(local(berlin, 2026, 3, 29, 23, 30))
        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 2)

        clock.set(local(berlin, 2026, 3, 30))
        store.completeTeaBreak()
        clock.set(local(berlin, 2026, 3, 31))
        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 4)
    }

    func testFallBackCountsAmbiguousHourOnce() throws {
        // 25.10.2026: 03:00 CEST faellt auf 02:00 CET zurueck, 02:30 gibt es zweimal.
        let clock = FixedClock(date: local(berlin, 2026, 10, 24))
        let (store, _) = try makeStore(clock: clock, calendar: berlin)
        store.completeTeaBreak()

        let firstHalfPastTwo = utc("2026-10-25T00:30:00Z") // 02:30 CEST
        let secondHalfPastTwo = utc("2026-10-25T01:30:00Z") // 02:30 CET
        XCTAssertEqual(DayKey.string(for: firstHalfPastTwo, calendar: berlin), "2026-10-25")
        XCTAssertEqual(DayKey.string(for: secondHalfPastTwo, calendar: berlin), "2026-10-25")

        clock.set(firstHalfPastTwo)
        store.completeTeaBreak()
        clock.set(secondHalfPastTwo)
        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 2)

        clock.set(local(berlin, 2026, 10, 26))
        store.completeTeaBreak()
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 3)
    }

    func testWeeklyGoalInSpringForwardWeek() throws {
        // Woche Mo 23.03. bis So 29.03.2026 (Umstellung am Sonntag).
        let keys = WeeklyGoal.dayKeys(ofWeekContaining: local(berlin, 2026, 3, 29), calendar: berlin)
        XCTAssertEqual(keys, [
            "2026-03-23", "2026-03-24", "2026-03-25", "2026-03-26",
            "2026-03-27", "2026-03-28", "2026-03-29",
        ])
        XCTAssertEqual(WeeklyGoal.weekKey(for: local(berlin, 2026, 3, 29), calendar: berlin), "2026-W13")

        let clock = FixedClock(date: local(berlin, 2026, 3, 23))
        let (store, _) = try makeStore(clock: clock, calendar: berlin)
        for day in [23, 24, 25, 29] {
            clock.set(local(berlin, 2026, 3, day))
            store.completeTeaBreak()
        }
        XCTAssertEqual(store.activeDaysThisWeek, 4)
        XCTAssertEqual(store.weekActiveDayStates, [true, true, true, false, false, false, true])
        XCTAssertEqual(store.bonusBlossomCount, 1)
    }

    func testWeeklyGoalInFallBackWeek() throws {
        // Woche Mo 19.10. bis So 25.10.2026 (Umstellung am Sonntag, 25 Stunden).
        let keys = WeeklyGoal.dayKeys(ofWeekContaining: local(berlin, 2026, 10, 25), calendar: berlin)
        XCTAssertEqual(keys, [
            "2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22",
            "2026-10-23", "2026-10-24", "2026-10-25",
        ])
        XCTAssertEqual(WeeklyGoal.weekKey(for: local(berlin, 2026, 10, 25), calendar: berlin), "2026-W43")

        let clock = FixedClock(date: local(berlin, 2026, 10, 19))
        let (store, _) = try makeStore(clock: clock, calendar: berlin)
        for day in [19, 22, 24, 25] {
            clock.set(local(berlin, 2026, 10, day))
            store.completeTeaBreak()
        }
        XCTAssertEqual(store.activeDaysThisWeek, 4)
        XCTAssertEqual(store.weekActiveDayStates, [true, false, false, true, false, true, true])
        XCTAssertEqual(store.bonusBlossomCount, 1)
    }
}
