import XCTest
@testable import MatchaMind

/// Prüft `FireflyPondSpawnGenerator` und die Katalog-Parameter von
/// `FireflyPondGame` (`Games/FireflyPond/FireflyPondGame.swift`,
/// MASTER-PROMPT.md Block B3 Aufgabe 2, Abschnitt 6 Zeile 2): je Stufe
/// liegt der beobachtete Ablenkungsanteil über viele Durchläufe nahe am
/// Katalog-Wert (30 % Sencha, 50 % Oolong/Matcha), nur erlaubte Farben
/// erscheinen, und Matcha kann die Zielfarbe für die zweite Rundenhälfte
/// wechseln.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung, daher konnte
/// dieser Test nicht kompiliert oder ausgeführt werden - siehe offene
/// Punkte in der Commit-Antwort.
final class FireflyPondGeneratorTests: XCTestCase {
    private let game = FireflyPondGame()

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

    func testSenchaDistractionRatioIsAboutThirtyPercent() {
        assertDistractionRatioMatchesCatalog(for: .sencha, tolerance: 0.05)
    }

    func testOolongDistractionRatioIsAboutFiftyPercent() {
        assertDistractionRatioMatchesCatalog(for: .oolong, tolerance: 0.05)
    }

    func testMatchaDistractionRatioIsAboutFiftyPercent() {
        assertDistractionRatioMatchesCatalog(for: .matcha, tolerance: 0.05)
    }

    /// Erzeugt viele Objekte für eine Stufe und prüft, dass der Anteil der
    /// Ablenkung (Falter + andersfarbige Glühwürmchen) nahe am
    /// Katalog-Wert liegt und ausschließlich erlaubte Farben vorkommen.
    private func assertDistractionRatioMatchesCatalog(for level: TeaLevel, tolerance: Double) {
        guard let parameters = game.parameters[level], let targetColor = parameters.availableColors.first else {
            XCTFail("Keine Parameter für \(level)")
            return
        }
        var rng = SeededGenerator(seed: 1234)
        let sampleCount = 4000
        let spawns = FireflyPondSpawnGenerator.generate(
            count: sampleCount,
            parameters: parameters,
            targetColor: targetColor,
            using: &rng
        )

        XCTAssertEqual(spawns.count, sampleCount)

        let distractorCount = spawns.filter { spawn in
            if case .firefly(let color) = spawn { return color != targetColor }
            return true // Falter
        }.count
        let observedRatio = Double(distractorCount) / Double(sampleCount)

        XCTAssertEqual(
            observedRatio,
            parameters.distractionRatio,
            accuracy: tolerance,
            "Beobachteter Ablenkungsanteil \(observedRatio) muss nahe am Katalog-Wert \(parameters.distractionRatio) liegen"
        )

        for spawn in spawns {
            if case .firefly(let color) = spawn {
                XCTAssertTrue(parameters.availableColors.contains(color), "Nur in dieser Stufe erlaubte Farben dürfen vorkommen")
            }
        }
    }

    func testSenchaHasOnlyOneFireflyColorSoDistractionIsOnlyMoths() {
        guard let parameters = game.parameters[.sencha] else {
            XCTFail("Keine Parameter für Sencha")
            return
        }
        XCTAssertEqual(parameters.availableColors, [.gold])

        var rng = SeededGenerator(seed: 99)
        let spawns = FireflyPondSpawnGenerator.generate(count: 500, parameters: parameters, targetColor: .gold, using: &rng)

        for spawn in spawns {
            if case .firefly(let color) = spawn {
                XCTAssertEqual(color, .gold, "In Sencha kann es nur die eine Zielfarbe geben")
            }
        }
    }

    func testOolongAndMatchaOfferThreeSimilarFireflyColors() {
        XCTAssertEqual(game.parameters[.oolong]?.availableColors.count, 3)
        XCTAssertEqual(game.parameters[.matcha]?.availableColors.count, 3)
    }

    func testOnlyMatchaSwitchesTargetColorMidRound() {
        XCTAssertEqual(game.parameters[.sencha]?.targetSwitchesMidRound, false)
        XCTAssertEqual(game.parameters[.oolong]?.targetSwitchesMidRound, false)
        XCTAssertEqual(game.parameters[.matcha]?.targetSwitchesMidRound, true)
    }

    func testMatchaCanGenerateTwoRoundHalvesWithDifferentTargetColors() {
        guard let parameters = game.parameters[.matcha] else {
            XCTFail("Keine Parameter für Matcha")
            return
        }
        var rng = SeededGenerator(seed: 5)

        let firstHalf = FireflyPondSpawnGenerator.generate(count: 20, parameters: parameters, targetColor: .gold, using: &rng)
        let secondHalf = FireflyPondSpawnGenerator.generate(count: 20, parameters: parameters, targetColor: .blossom, using: &rng)

        XCTAssertEqual(firstHalf.count, 20)
        XCTAssertEqual(secondHalf.count, 20)
    }
}
