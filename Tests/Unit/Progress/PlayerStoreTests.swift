import XCTest
@testable import MatchaMind

/// Prüft `PlayerStore` (`Progress/PlayerStore.swift`) mit In-Memory-Container,
/// festem Kalender (Europe/Berlin) und verschiebbarer `FixedClock`. Dazu die
/// Anbindung von `GameInstructionsSeenStore`/`FineLevelStore` und ein
/// Neustart-Test mit Datei-Container.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung; die Tests laufen
/// erst im CI.
@MainActor
final class PlayerStoreTests: XCTestCase {

    private let oneDay: TimeInterval = 24 * 60 * 60

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func makeClock() -> FixedClock {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 12))!
        return FixedClock(date: start)
    }

    private func makeStore(clock: FixedClock) throws -> PlayerStore {
        let container = try PlayerStore.makeContainer(inMemory: true)
        return PlayerStore(container: container, clock: clock, calendar: calendar)
    }

    /// Spielt einen Tag: ein Ergebnis mit den gegebenen Werten, dann Teepause
    /// abschließen. Liefert das Aufstiegsangebot.
    @discardableResult
    private func playDay(_ store: PlayerStore, hits: Int = 8, misses: Int = 2) -> TeaLevel? {
        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: hits, misses: misses, duration: 60))
        return store.completeTeaBreak()
    }

    // MARK: - Start

    func testNewStoreStartsAtSenchaWithAutoAdvance() throws {
        let store = try makeStore(clock: makeClock())

        XCTAssertEqual(store.level, .sencha)
        XCTAssertEqual(store.highestLevel, .sencha)
        XCTAssertTrue(store.autoAdvance)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 0)
        XCTAssertFalse(store.isTeaBreakCompletedToday)
    }

    // MARK: - Aktive Tage

    func testCompletingTeaBreakTwiceOnSameDayCountsOneActiveDay() throws {
        let store = try makeStore(clock: makeClock())

        store.completeTeaBreak()
        store.completeTeaBreak()

        XCTAssertEqual(store.activeDaysAtCurrentLevel, 1)
        XCTAssertTrue(store.isTeaBreakCompletedToday)
    }

    func testGameResultAloneIsNotAnActiveDay() throws {
        let store = try makeStore(clock: makeClock())

        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 5, misses: 1, duration: 60))

        XCTAssertEqual(store.activeDaysAtCurrentLevel, 0)
        XCTAssertFalse(store.isTeaBreakCompletedToday)
    }

    func testNewDayIsNotCompletedYet() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.completeTeaBreak()

        clock.advance(by: oneDay)

        XCTAssertFalse(store.isTeaBreakCompletedToday)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 1)
    }

    // MARK: - Aufstieg

    func testPromotionToOolongIsOfferedOnFourteenthActiveDay() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)

        for day in 1...14 {
            let offer = playDay(store)
            if day < 14 {
                XCTAssertNil(offer, "Tag \(day) darf noch kein Angebot liefern")
            } else {
                XCTAssertEqual(offer, .oolong)
            }
            clock.advance(by: oneDay)
        }
        XCTAssertEqual(store.pendingPromotion(), .oolong)
    }

    func testNoPromotionWhenAccuracyBelowThreshold() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)

        for _ in 1...14 {
            XCTAssertNil(playDay(store, hits: 7, misses: 3))
            clock.advance(by: oneDay)
        }
    }

    func testNoPromotionWithAutoAdvanceOff() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.setAutoAdvance(false)

        for _ in 1...14 {
            XCTAssertNil(playDay(store))
            clock.advance(by: oneDay)
        }
        XCTAssertFalse(store.autoAdvance)
    }

    func testAcceptPromotionSwitchesLevelAndRestartsCounting() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        for _ in 1...14 {
            playDay(store)
            clock.advance(by: oneDay)
        }

        store.acceptPromotion(to: .oolong)

        XCTAssertEqual(store.level, .oolong)
        XCTAssertEqual(store.highestLevel, .oolong)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 0)
        XCTAssertNil(store.pendingPromotion())
    }

    func testPromotionOnSameDayAsTeaBreakDoesNotCountThatDayTwice() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        playDay(store)

        store.acceptPromotion(to: .oolong)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 0)

        clock.advance(by: oneDay)
        playDay(store)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 1)
    }

    func testManualLevelChangeResetsCountingButKeepsHighestLevel() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.setLevel(.oolong)
        for _ in 1...3 {
            playDay(store)
            clock.advance(by: oneDay)
        }
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 3)

        store.setLevel(.sencha)

        XCTAssertEqual(store.level, .sencha)
        XCTAssertEqual(store.highestLevel, .oolong)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 0)
    }

    /// Spielt 14 aktive Tage: Tag 1–13 kein Angebot, Tag 14 Angebot `expected`.
    private func assertOfferOnFourteenthActiveDay(_ store: PlayerStore, clock: FixedClock, expected: TeaLevel) {
        for day in 1...14 {
            let offer = playDay(store)
            if day < 14 {
                XCTAssertNil(offer, "Tag \(day) nach manueller Senkung darf noch kein Angebot liefern")
            } else {
                XCTAssertEqual(offer, expected, "Tag 14 nach manueller Senkung muss das Angebot liefern")
            }
            clock.advance(by: oneDay)
        }
    }

    func testManuallyLoweredToSenchaOffersPromotionAfterFourteenNewActiveDays() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.setLevel(.oolong)
        for _ in 1...5 {
            playDay(store)
            clock.advance(by: oneDay)
        }

        store.setLevel(.sencha)
        XCTAssertTrue(store.autoAdvance)

        assertOfferOnFourteenthActiveDay(store, clock: clock, expected: .oolong)
    }

    func testManuallyLoweredToOolongOffersPromotionAfterFourteenNewActiveDays() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.setLevel(.matcha)
        for _ in 1...5 {
            playDay(store)
            clock.advance(by: oneDay)
        }

        store.setLevel(.oolong)
        XCTAssertTrue(store.autoAdvance)

        assertOfferOnFourteenthActiveDay(store, clock: clock, expected: .matcha)
    }

    func testLoweringAfterTodaysTeaBreakCountsFromTomorrow() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.setLevel(.oolong)
        playDay(store)

        store.setLevel(.sencha)
        XCTAssertEqual(store.activeDaysAtCurrentLevel, 0)
        clock.advance(by: oneDay)

        assertOfferOnFourteenthActiveDay(store, clock: clock, expected: .oolong)
    }

    func testRaisingAfterManualLoweringUsesRegularDays() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        store.setLevel(.matcha)
        store.setLevel(.sencha)
        store.setLevel(.oolong)

        for day in 1...21 {
            let offer = playDay(store)
            if day < 21 {
                XCTAssertNil(offer, "Tag \(day) nach manuellem Hochsetzen: reguläre 21 Tage")
            } else {
                XCTAssertEqual(offer, .matcha)
            }
            clock.advance(by: oneDay)
        }
    }

    func testDeferPromotionPostponesOfferBySevenActiveDays() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        for _ in 1...14 {
            playDay(store)
            clock.advance(by: oneDay)
        }
        XCTAssertEqual(store.pendingPromotion(), .oolong)

        store.deferPromotion()
        XCTAssertNil(store.pendingPromotion())

        // Aktive Tage 15 bis 20: weiterhin kein Angebot.
        for day in 15...20 {
            XCTAssertNil(playDay(store), "Tag \(day) darf noch kein Angebot liefern")
            clock.advance(by: oneDay)
        }
        // Tag 21 = 14 + 7: das Angebot kehrt zurück.
        XCTAssertEqual(playDay(store), .oolong)
    }

    // MARK: - Spiele

    func testGameResultRecordsLastPlayedDate() throws {
        let clock = makeClock()
        let store = try makeStore(clock: clock)
        XCTAssertNil(store.lastPlayed(gameID: "teapot-row"))

        store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 3, misses: 1, duration: 30))

        XCTAssertEqual(store.lastPlayed(gameID: "teapot-row"), clock.now())
        XCTAssertNil(store.lastPlayed(gameID: "firefly-pond"))
    }

    func testInstructionsSeenIsPerGame() throws {
        let store = try makeStore(clock: makeClock())
        XCTAssertFalse(store.instructionsSeen(gameID: "teapot-row"))

        store.markInstructionsSeen(gameID: "teapot-row")
        store.markInstructionsSeen(gameID: "teapot-row")

        XCTAssertTrue(store.instructionsSeen(gameID: "teapot-row"))
        XCTAssertFalse(store.instructionsSeen(gameID: "firefly-pond"))
    }

    func testFineLevelRoundTrip() throws {
        let store = try makeStore(clock: makeClock())
        XCTAssertNil(store.fineLevel(gameID: "teapot-row"))

        store.saveFineLevel(gameID: "teapot-row", level: 4)

        XCTAssertEqual(store.fineLevel(gameID: "teapot-row"), 4)
        XCTAssertNil(store.fineLevel(gameID: "firefly-pond"))
    }

    func testStaticStoresWriteThroughToBackingStore() throws {
        let store = try makeStore(clock: makeClock())
        GameInstructionsSeenStore.backing = store
        FineLevelStore.backing = store
        defer {
            GameInstructionsSeenStore.backing = nil
            FineLevelStore.backing = nil
        }
        let gameID = "test-game-\(UUID().uuidString)"

        GameInstructionsSeenStore.markSeen(gameID: gameID)
        FineLevelStore.save(gameID: gameID, level: 5)

        XCTAssertTrue(store.instructionsSeen(gameID: gameID))
        XCTAssertEqual(store.fineLevel(gameID: gameID), 5)
        XCTAssertEqual(FineLevelStore.startLevel(gameID: gameID), 5)
    }

    func testInstructionsSeenInBackingStoreCountsAsSeen() throws {
        let store = try makeStore(clock: makeClock())
        let gameID = "test-game-\(UUID().uuidString)"
        store.markInstructionsSeen(gameID: gameID)
        XCTAssertFalse(GameInstructionsSeenStore.hasSeenInstructions(gameID: gameID))

        GameInstructionsSeenStore.backing = store
        defer { GameInstructionsSeenStore.backing = nil }

        XCTAssertTrue(GameInstructionsSeenStore.hasSeenInstructions(gameID: gameID))
    }

    func testFineLevelStoreWithoutBackingReturnsNil() {
        FineLevelStore.backing = nil

        FineLevelStore.save(gameID: "teapot-row", level: 4)

        XCTAssertNil(FineLevelStore.startLevel(gameID: "teapot-row"))
    }

    // MARK: - Neustart

    func testDataSurvivesRestartWithFileContainer() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("matcha-mind-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("player.store")
        let clock = makeClock()

        do {
            let container = try PlayerStore.makeContainer(inMemory: false, url: storeURL)
            let store = PlayerStore(container: container, clock: clock, calendar: calendar)
            store.setLevel(.oolong)
            store.setAutoAdvance(false)
            store.recordGameResult(gameID: "teapot-row", result: GameResult(hits: 6, misses: 2, duration: 60))
            store.completeTeaBreak()
            store.markInstructionsSeen(gameID: "teapot-row")
            store.saveFineLevel(gameID: "teapot-row", level: 4)
            // Paket F: Tau, Deko, Erinnerung, Erststart, Ton, Haptik, Ergebnisse.
            store.recordGameResult(gameID: "firefly-pond", result: GameResult(hits: 9, misses: 1, duration: 60))
            store.recordGameResult(gameID: "bamboo-math", result: GameResult(hits: 4, misses: 4, duration: 60))
            XCTAssertTrue(store.purchaseDecoration(id: "stepping-stones")) // 36 Tau - 24
            store.setReminderTime(ReminderTime(hour: 7, minute: 45))
            store.setReminderOff(true)
            store.completeOnboarding()
            store.setSoundEnabled(false)
            store.setHapticsEnabled(false)
        }

        let reopenedContainer = try PlayerStore.makeContainer(inMemory: false, url: storeURL)
        let reopened = PlayerStore(container: reopenedContainer, clock: clock, calendar: calendar)

        XCTAssertEqual(reopened.level, .oolong)
        XCTAssertEqual(reopened.highestLevel, .oolong)
        XCTAssertFalse(reopened.autoAdvance)
        XCTAssertEqual(reopened.activeDaysAtCurrentLevel, 1)
        XCTAssertTrue(reopened.isTeaBreakCompletedToday)
        XCTAssertTrue(reopened.instructionsSeen(gameID: "teapot-row"))
        XCTAssertEqual(reopened.fineLevel(gameID: "teapot-row"), 4)
        XCTAssertEqual(reopened.lastPlayed(gameID: "teapot-row"), clock.now())

        // Paket F: die neuen Felder ueberleben den Neustart ebenfalls.
        XCTAssertEqual(reopened.dewEarnedTotal, 36)
        XCTAssertEqual(reopened.dewDrops, 12)
        XCTAssertEqual(reopened.ownedDecorationIDs, ["stepping-stones"])
        XCTAssertEqual(reopened.reminderTime, ReminderTime(hour: 7, minute: 45))
        XCTAssertTrue(reopened.reminderOff)
        XCTAssertTrue(reopened.onboardingCompleted)
        XCTAssertFalse(reopened.soundEnabled)
        XCTAssertFalse(reopened.hapticsEnabled)
        XCTAssertEqual(reopened.resultCount, 3)
        XCTAssertEqual(reopened.areaAccuracy.count, 3, "Je ein Eintrag pro gespieltem Bereich")
        XCTAssertTrue(reopened.instructionsSeen(gameID: "teapot-row"))
        XCTAssertFalse(reopened.instructionsSeen(gameID: "firefly-pond"))
    }
}
