import XCTest
@testable import MatchaMind

/// Prüft, wann der Erststart erscheint: im Release (Standard) immer, in
/// DEBUG-UI-Tests nur mit `-uitest-show-onboarding`. Dazu die Hilfen der
/// `OnboardingView`.
@MainActor
final class OnboardingGateTests: XCTestCase {

    func testDefaultEnvironmentShowsOnboarding() {
        XCTAssertTrue(AppEnvironment().showsOnboarding)
    }

    func testReminderTimeIsTakenFromPickerDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 7, minute: 45))!

        XCTAssertEqual(OnboardingView.reminderTime(from: date, calendar: calendar), ReminderTime(hour: 7, minute: 45))
    }

    func testSuggestedDateIsHalfPastTwelve() {
        let calendar = Calendar.autoupdatingCurrent
        let time = OnboardingView.reminderTime(from: OnboardingView.suggestedDate(calendar: calendar), calendar: calendar)

        XCTAssertEqual(time, ReminderTime.suggested)
        XCTAssertEqual(ReminderTime.suggested, ReminderTime(hour: 12, minute: 30))
    }

    #if DEBUG
    private func environment(_ arguments: [String]) -> AppEnvironment {
        AppEnvironment.make(from: LaunchConfiguration.makeConfiguration(arguments: ["AppName"] + arguments))
    }

    func testNoTestArgumentsShowOnboarding() {
        XCTAssertTrue(environment([]).showsOnboarding)
    }

    func testAnyUITestArgumentSkipsOnboarding() {
        XCTAssertFalse(environment(["-uitest-date", "2026-01-15T08:00:00Z"]).showsOnboarding)
        XCTAssertFalse(environment(["-uitest-game-level", "sencha"]).showsOnboarding)
        XCTAssertFalse(environment(["-uitest-appearance", "dark"]).showsOnboarding)
        XCTAssertFalse(environment(["-uitest-persona", "tea"]).showsOnboarding)
        XCTAssertFalse(
            environment(["-uitest-date", "2026-01-15T08:00:00Z", "-uitest-persona", "tea"]).showsOnboarding
        )
    }

    func testShowOnboardingArgumentBringsItBack() {
        XCTAssertTrue(environment(["-uitest-show-onboarding"]).showsOnboarding)
        XCTAssertTrue(environment(["-uitest-persona", "tea", "-uitest-show-onboarding"]).showsOnboarding)
    }

    func testLaunchConfigurationDetectsTestArguments() {
        XCTAssertFalse(LaunchConfiguration.makeConfiguration(arguments: ["AppName"]).hasUITestArguments)
        XCTAssertTrue(LaunchConfiguration.makeConfiguration(arguments: ["AppName", "-uitest-x"]).hasUITestArguments)
        XCTAssertFalse(LaunchConfiguration.makeConfiguration(arguments: ["AppName"]).showOnboarding)
        XCTAssertTrue(
            LaunchConfiguration.makeConfiguration(arguments: ["AppName", "-uitest-show-onboarding"]).showOnboarding
        )
    }
    #endif
}
