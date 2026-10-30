import XCTest
@testable import MatchaMind

/// Prüft `GameCatalog` (`Games/Core/GameCatalog.swift`, MASTER-PROMPT.md
/// Block B3 Aufgabe 4): alle 14 Spiele aus dem Spiele-Katalog (Abschnitt 6)
/// sind vorhanden, nach Stufe gruppiert, und genau die 5 Sencha-Spiele sind
/// freigeschaltet - alles andere ist gesperrt, da der Aufstieg erst in
/// Block B4 kommt.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class GameCatalogTests: XCTestCase {
    private let expectedUnlockedIds: Set<String> = [
        "teapot-row",
        "firefly-pond",
        "mosaic-bed",
        "tea-leaf-sort",
        "bamboo-math",
    ]

    func testCatalogContainsAllFourteenGames() {
        XCTAssertEqual(GameCatalog.allGames.count, 14)
    }

    func testAllGameIdsAreUnique() {
        let ids = GameCatalog.allGames.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Spiel-IDs müssen eindeutig sein")
    }

    func testOnlyTheFiveSenchaGamesAreUnlocked() {
        let unlockedIds = Set(GameCatalog.allGames.filter(\.isUnlocked).map(\.id))
        XCTAssertEqual(unlockedIds, expectedUnlockedIds)
    }

    func testSenchaSectionHasFiveUnlockedGames() {
        let senchaGames = GameCatalog.games(for: .sencha)
        XCTAssertEqual(senchaGames.count, 5)
        XCTAssertTrue(senchaGames.allSatisfy(\.isUnlocked))
        XCTAssertTrue(senchaGames.allSatisfy { $0.lockLabel == nil })
    }

    func testOolongSectionHasFiveLockedGames() {
        let oolongGames = GameCatalog.games(for: .oolong)
        XCTAssertEqual(oolongGames.count, 5)
        XCTAssertTrue(oolongGames.allSatisfy { !$0.isUnlocked })
        XCTAssertTrue(oolongGames.allSatisfy { $0.lockLabel == .oolong })
    }

    func testMatchaSectionHasFourLockedGames() {
        let matchaGames = GameCatalog.games(for: .matcha)
        XCTAssertEqual(matchaGames.count, 4)
        XCTAssertTrue(matchaGames.allSatisfy { !$0.isUnlocked })
        XCTAssertTrue(matchaGames.allSatisfy { $0.lockLabel == .matcha })
    }

    func testBambooMathIsPartOfTheSenchaSection() {
        let senchaIds = Set(GameCatalog.games(for: .sencha).map(\.id))
        XCTAssertTrue(senchaIds.contains("bamboo-math"))
    }
}
