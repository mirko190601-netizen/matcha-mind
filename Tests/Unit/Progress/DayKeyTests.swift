import XCTest
@testable import MatchaMind

/// Prüft `DayKey` (`Progress/DayKey.swift`): Format `yyyy-MM-dd` in der
/// Zeitzone des übergebenen Kalenders.
final class DayKeyTests: XCTestCase {

    private func calendar(timeZone identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    func testFormatsWithLeadingZeros() {
        let berlin = calendar(timeZone: "Europe/Berlin")
        let date = berlin.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 12))!

        XCTAssertEqual(DayKey.string(for: date, calendar: berlin), "2026-03-05")
    }

    func testUsesTimeZoneOfCalendar() {
        let berlin = calendar(timeZone: "Europe/Berlin")
        let tokyo = calendar(timeZone: "Asia/Tokyo")
        // 23:30 in Berlin ist in Tokio bereits der nächste Tag.
        let date = berlin.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 23, minute: 30))!

        XCTAssertEqual(DayKey.string(for: date, calendar: berlin), "2026-01-10")
        XCTAssertEqual(DayKey.string(for: date, calendar: tokyo), "2026-01-11")
    }

    func testKeysCompareChronologicallyAsStrings() {
        let berlin = calendar(timeZone: "Europe/Berlin")
        let earlier = berlin.date(from: DateComponents(year: 2026, month: 1, day: 9, hour: 12))!
        let later = berlin.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 12))!

        XCTAssertLessThan(
            DayKey.string(for: earlier, calendar: berlin),
            DayKey.string(for: later, calendar: berlin)
        )
    }
}
