import XCTest
@testable import MatchaMind

/// Prüft `GameInstructionsSeenStore` (`Games/Core/GameInstructionsSeenStore.swift`):
/// reine Prozesslaufzeit-Markierung ohne Persistenz, pro Spiel-ID.
///
/// Nutzt überall eindeutige, zufällige Spiel-IDs statt echter Katalog-IDs
/// (z. B. "teapot-row"): der Speicher ist `static` und damit über den
/// gesamten Testlauf hinweg geteilt - eindeutige IDs verhindern, dass
/// dieser Test von anderen Tests (oder umgekehrt) beeinflusst wird.
@MainActor
final class GameInstructionsSeenStoreTests: XCTestCase {
    private func uniqueGameID() -> String {
        "test-game-\(UUID().uuidString)"
    }

    func testUnseenGameReturnsFalse() {
        XCTAssertFalse(GameInstructionsSeenStore.hasSeenInstructions(gameID: uniqueGameID()))
    }

    func testMarkSeenMakesHasSeenInstructionsTrue() {
        let gameID = uniqueGameID()

        GameInstructionsSeenStore.markSeen(gameID: gameID)

        XCTAssertTrue(GameInstructionsSeenStore.hasSeenInstructions(gameID: gameID))
    }

    func testMarkSeenDoesNotAffectOtherGameIDs() {
        let seenID = uniqueGameID()
        let otherID = uniqueGameID()

        GameInstructionsSeenStore.markSeen(gameID: seenID)

        XCTAssertFalse(GameInstructionsSeenStore.hasSeenInstructions(gameID: otherID))
    }

    func testMarkSeenIsIdempotent() {
        let gameID = uniqueGameID()

        GameInstructionsSeenStore.markSeen(gameID: gameID)
        GameInstructionsSeenStore.markSeen(gameID: gameID)

        XCTAssertTrue(GameInstructionsSeenStore.hasSeenInstructions(gameID: gameID))
    }
}
