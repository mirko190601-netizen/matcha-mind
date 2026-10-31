import XCTest
@testable import MatchaMind

/// Prüft `GameCatalog` (`Games/Core/GameCatalog.swift`, MASTER-PROMPT.md
/// Block B3 Aufgabe 4): alle 14 Spiele aus dem Spiele-Katalog (Abschnitt 6)
/// sind vorhanden, nach Stufe gruppiert, und genau die 5 Sencha-Spiele sind
/// gebaut (`isImplemented`). Die Freischaltung hängt seit Block B4 von der
/// Spielerstufe ab (`GameCatalog.isUnlocked(_:playerLevel:)`).
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

    func testOnlyTheFiveSenchaGamesAreImplemented() {
        let implementedIds = Set(GameCatalog.allGames.filter(\.isImplemented).map(\.id))
        XCTAssertEqual(implementedIds, expectedUnlockedIds)
        XCTAssertEqual(GameCatalog.playableGameIDs, expectedUnlockedIds)
    }

    func testSenchaPlayerUnlocksTheFiveSenchaGames() {
        let unlocked = GameCatalog.allGames.filter { GameCatalog.isUnlocked($0, playerLevel: .sencha) }
        XCTAssertEqual(Set(unlocked.map(\.id)), expectedUnlockedIds)
    }

    func testOolongAndMatchaPlayersUnlockOnlyBuiltGames() {
        // Die Oolong-/Matcha-Spiele sind noch nicht gebaut (B5/B6): auch mit
        // erreichter Stufe bleiben sie nicht spielbar.
        for level in [TeaLevel.oolong, TeaLevel.matcha] {
            let unlocked = GameCatalog.allGames.filter { GameCatalog.isUnlocked($0, playerLevel: level) }
            XCTAssertEqual(Set(unlocked.map(\.id)), expectedUnlockedIds, "Stufe \(level)")
        }
    }

    func testPlayableGamesForLevelMatchUnlockedGames() {
        for level in TeaLevel.allCases {
            let playable = Set(GameCatalog.playableGames(for: level).map(\.id))
            let unlocked = Set(
                GameCatalog.allGames
                    .filter { GameCatalog.isUnlocked($0, playerLevel: level) }
                    .map(\.id)
            )
            XCTAssertEqual(playable, unlocked)
        }
    }

    func testUnlockingRequiresPlayerLevelAtLeastMinLevel() {
        let higherLevelEntry = GameCatalogEntry(
            id: "test",
            nameKey: "test",
            area: .focus,
            minLevel: .oolong,
            isImplemented: true
        )
        XCTAssertFalse(GameCatalog.isUnlocked(higherLevelEntry, playerLevel: .sencha))
        XCTAssertTrue(GameCatalog.isUnlocked(higherLevelEntry, playerLevel: .oolong))
        XCTAssertTrue(GameCatalog.isUnlocked(higherLevelEntry, playerLevel: .matcha))
    }

    func testUnbuiltGameStaysLockedEvenAtItsMinLevel() {
        let unbuiltEntry = GameCatalogEntry(
            id: "test",
            nameKey: "test",
            area: .focus,
            minLevel: .sencha,
            isImplemented: false
        )
        XCTAssertFalse(GameCatalog.isUnlocked(unbuiltEntry, playerLevel: .matcha))
    }

    func testSenchaSectionHasFiveBuiltGames() {
        let senchaGames = GameCatalog.games(for: .sencha)
        XCTAssertEqual(senchaGames.count, 5)
        XCTAssertTrue(senchaGames.allSatisfy(\.isImplemented))
        XCTAssertTrue(senchaGames.allSatisfy { $0.lockLabel == nil })
    }

    func testOolongSectionHasFiveUnbuiltGames() {
        let oolongGames = GameCatalog.games(for: .oolong)
        XCTAssertEqual(oolongGames.count, 5)
        XCTAssertTrue(oolongGames.allSatisfy { !$0.isImplemented })
        XCTAssertTrue(oolongGames.allSatisfy { $0.lockLabel == .oolong })
    }

    func testMatchaSectionHasFourUnbuiltGames() {
        let matchaGames = GameCatalog.games(for: .matcha)
        XCTAssertEqual(matchaGames.count, 4)
        XCTAssertTrue(matchaGames.allSatisfy { !$0.isImplemented })
        XCTAssertTrue(matchaGames.allSatisfy { $0.lockLabel == .matcha })
    }

    func testBambooMathIsPartOfTheSenchaSection() {
        let senchaIds = Set(GameCatalog.games(for: .sencha).map(\.id))
        XCTAssertTrue(senchaIds.contains("bamboo-math"))
    }
}
