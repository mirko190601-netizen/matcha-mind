import XCTest
@testable import MatchaMind

/// Prüft `TeapotRowSequenceGenerator` und die Katalog-Parameter von
/// `TeapotRowGame` (`Games/TeapotRow/TeapotRowGame.swift`, MASTER-PROMPT.md
/// Block B3 Aufgabe 2, Abschnitt 6 Zeile 1): je Stufe erzeugt die untere
/// und die obere Grenze der erlaubten Sequenzlänge tatsächlich eine
/// Sequenz dieser Länge aus gültigen Positionen, und Matcha verlangt
/// rückwärts statt vorwärts.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class TeapotRowGeneratorTests: XCTestCase {
    private let game = TeapotRowGame()

    /// Einfacher, deterministischer Zufallszahlengenerator für
    /// reproduzierbare Testläufe (kein kryptographischer Anspruch).
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

    func testSenchaSequenceLengthStaysWithinCatalogRange() {
        assertSequenceLengthMatchesRequestedLength(for: .sencha)
    }

    func testOolongSequenceLengthStaysWithinCatalogRange() {
        assertSequenceLengthMatchesRequestedLength(for: .oolong)
    }

    func testMatchaSequenceLengthStaysWithinCatalogRange() {
        assertSequenceLengthMatchesRequestedLength(for: .matcha)
    }

    /// Erzeugt für die untere und obere Grenze der Sequenzlänge dieser
    /// Stufe je eine Sequenz und prüft Länge und Wertebereich.
    private func assertSequenceLengthMatchesRequestedLength(for level: TeaLevel) {
        guard let parameters = game.parameters[level] else {
            XCTFail("Keine Parameter für \(level)")
            return
        }
        var rng = SeededGenerator(seed: 42)

        for length in [parameters.sequenceLengthRange.lowerBound, parameters.sequenceLengthRange.upperBound] {
            let sequence = TeapotRowSequenceGenerator.generate(
                length: length,
                positionCount: TeapotRowGame.positionCount,
                using: &rng
            )
            XCTAssertEqual(sequence.count, length, "Sequenzlänge für \(level) muss \(length) sein")
            XCTAssertTrue(
                sequence.allSatisfy { (0..<TeapotRowGame.positionCount).contains($0) },
                "Alle Positionen müssen innerhalb des Rasters liegen"
            )
        }
    }

    func testGeneratedSequenceNeverRepeatsAPositionImmediately() {
        var rng = SeededGenerator(seed: 7)
        for _ in 0..<200 {
            let sequence = TeapotRowSequenceGenerator.generate(length: 9, positionCount: 9, using: &rng)
            for (previous, current) in zip(sequence, sequence.dropFirst()) {
                XCTAssertNotEqual(previous, current, "Zwei gleiche Positionen direkt hintereinander sind nicht erlaubt")
            }
        }
    }

    func testMatchaRequiresBackwardDirection() {
        XCTAssertEqual(game.parameters[.matcha]?.direction, .backward)
    }

    func testSenchaAndOolongRequireForwardDirection() {
        XCTAssertEqual(game.parameters[.sencha]?.direction, .forward)
        XCTAssertEqual(game.parameters[.oolong]?.direction, .forward)
    }
}
