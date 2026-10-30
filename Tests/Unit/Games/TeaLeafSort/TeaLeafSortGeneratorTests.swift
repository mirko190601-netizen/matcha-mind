import XCTest
@testable import MatchaMind

/// Prüft `TeaLeafSortGenerator` und die Katalog-Parameter von
/// `TeaLeafSortGame` (`Games/TeaLeafSort/TeaLeafSortGame.swift`,
/// MASTER-PROMPT.md Block B3 Aufgabe 3, Abschnitt 6 Zeile 4): je Stufe die
/// richtige Regel-Anzahl/Ankündigung, dass eine generierte Karte immer zu
/// genau der Ablage mit Index `targetPileIndex` passt (unabhängig davon,
/// ob 1 oder 2 Eigenschaften aktiv sind), und dass ein Regelwechsel immer
/// zu einer anderen Eigenschafts-Menge führt.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class TeaLeafSortGeneratorTests: XCTestCase {
    private let game = TeaLeafSortGame()

    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0xdead_beef : seed
        }

        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    func testSenchaHasOneAnnouncedRule() {
        XCTAssertEqual(game.parameters[.sencha]?.activeDimensionCount, 1)
        XCTAssertEqual(game.parameters[.sencha]?.announceRuleChange, true)
    }

    func testOolongHasOneUnannouncedRule() {
        XCTAssertEqual(game.parameters[.oolong]?.activeDimensionCount, 1)
        XCTAssertEqual(game.parameters[.oolong]?.announceRuleChange, false)
    }

    func testMatchaHasTwoUnannouncedRules() {
        XCTAssertEqual(game.parameters[.matcha]?.activeDimensionCount, 2)
        XCTAssertEqual(game.parameters[.matcha]?.announceRuleChange, false)
    }

    func testGeneratedCardAlwaysMatchesTargetPileWithOneActiveDimension() {
        var rng = SeededGenerator(seed: 21)
        for targetPileIndex in 0..<TeaLeafSortGenerator.valueCount {
            for dimension in TeaLeafDimension.allCases {
                let card = TeaLeafSortGenerator.generateCard(
                    targetPileIndex: targetPileIndex,
                    activeDimensions: [dimension],
                    using: &rng
                )
                XCTAssertEqual(
                    card.valueIndex(for: dimension),
                    targetPileIndex,
                    "Die aktive Eigenschaft muss immer den Zielwert tragen"
                )
            }
        }
    }

    func testGeneratedCardAlwaysMatchesTargetPileWithTwoActiveDimensions() {
        var rng = SeededGenerator(seed: 22)
        let activeDimensions: Set<TeaLeafDimension> = [.color, .shape]
        for targetPileIndex in 0..<TeaLeafSortGenerator.valueCount {
            let card = TeaLeafSortGenerator.generateCard(
                targetPileIndex: targetPileIndex,
                activeDimensions: activeDimensions,
                using: &rng
            )
            for dimension in activeDimensions {
                XCTAssertEqual(card.valueIndex(for: dimension), targetPileIndex)
            }
        }
    }

    func testPossibleActiveDimensionSetsCoverAllSingleDimensions() {
        let sets = TeaLeafSortGenerator.possibleActiveDimensionSets(count: 1)
        XCTAssertEqual(sets.count, 3)
        for dimension in TeaLeafDimension.allCases {
            XCTAssertTrue(sets.contains([dimension]))
        }
    }

    func testPossibleActiveDimensionSetsCoverAllPairsForMatcha() {
        let sets = TeaLeafSortGenerator.possibleActiveDimensionSets(count: 2)
        XCTAssertEqual(sets.count, 3)
        for set in sets {
            XCTAssertEqual(set.count, 2)
        }
    }

    func testPickNewActiveDimensionsNeverRepeatsThePrevious() {
        var rng = SeededGenerator(seed: 23)
        for _ in 0..<200 {
            let previous: Set<TeaLeafDimension> = [.shape]
            let next = TeaLeafSortGenerator.pickNewActiveDimensions(count: 1, excluding: previous, using: &rng)
            XCTAssertNotEqual(next, previous)
        }
    }
}
