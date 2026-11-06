import XCTest
@testable import MatchaMind

/// Prüft `TeaBreakPlanner` (`Teepause/TeaBreakPlanner.swift`): drei
/// verschiedene Spiele aus verschiedenen Bereichen, nie gespielte zuerst,
/// dann die am längsten nicht gespielten; deterministisch mit festem Seed.
///
/// In dieser Umgebung steht kein macOS/Xcode zur Verfügung; die Tests laufen
/// erst im CI.
final class TeaBreakPlannerTests: XCTestCase {

    /// Kleiner SplitMix64-Generator mit festem Startwert (nur für Tests).
    private struct SplitMix64: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func day(_ offset: Int) -> Date {
        now.addingTimeInterval(TimeInterval(offset) * 24 * 60 * 60)
    }

    /// Fünf Kandidaten mit fünf verschiedenen Bereichen, alle nie gespielt.
    private func fiveFreshCandidates() -> [TeaBreakCandidate] {
        [
            TeaBreakCandidate(gameID: "a", area: .spatialMemory, lastPlayed: nil),
            TeaBreakCandidate(gameID: "b", area: .focus, lastPlayed: nil),
            TeaBreakCandidate(gameID: "c", area: .logic, lastPlayed: nil),
            TeaBreakCandidate(gameID: "d", area: .flexibility, lastPlayed: nil),
            TeaBreakCandidate(gameID: "e", area: .mentalMath, lastPlayed: nil),
        ]
    }

    private func plan(_ candidates: [TeaBreakCandidate], count: Int = 3, seed: UInt64 = 42) -> [String] {
        var rng = SplitMix64(seed: seed)
        return TeaBreakPlanner.plan(candidates: candidates, count: count, using: &rng)
    }

    func testPlanReturnsExactlyThreeDistinctIDs() {
        let result = plan(fiveFreshCandidates())

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(Set(result).count, 3)
    }

    func testPlanPicksDifferentAreas() {
        let candidates = fiveFreshCandidates()
        let areaByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.gameID, $0.area) })

        for seed in UInt64(1)...20 {
            let areas = plan(candidates, seed: seed).compactMap { areaByID[$0] }
            XCTAssertEqual(Set(areas).count, 3, "Seed \(seed): Bereiche müssen verschieden sein")
        }
    }

    func testNeverPlayedGamesComeBeforePlayedOnes() {
        let candidates = [
            TeaBreakCandidate(gameID: "played1", area: .spatialMemory, lastPlayed: day(-1)),
            TeaBreakCandidate(gameID: "played2", area: .focus, lastPlayed: day(-2)),
            TeaBreakCandidate(gameID: "fresh1", area: .logic, lastPlayed: nil),
            TeaBreakCandidate(gameID: "fresh2", area: .flexibility, lastPlayed: nil),
            TeaBreakCandidate(gameID: "played3", area: .mentalMath, lastPlayed: day(-3)),
        ]

        for seed in UInt64(1)...20 {
            let result = plan(candidates, seed: seed)
            XCTAssertTrue(result.contains("fresh1"), "Seed \(seed)")
            XCTAssertTrue(result.contains("fresh2"), "Seed \(seed)")
            // Das dritte Spiel ist das am längsten nicht gespielte.
            XCTAssertTrue(result.contains("played3"), "Seed \(seed)")
        }
    }

    func testOlderLastPlayedComesBeforeNewer() {
        let candidates = [
            TeaBreakCandidate(gameID: "newest", area: .spatialMemory, lastPlayed: day(-1)),
            TeaBreakCandidate(gameID: "oldest", area: .focus, lastPlayed: day(-30)),
            TeaBreakCandidate(gameID: "middle", area: .logic, lastPlayed: day(-10)),
            TeaBreakCandidate(gameID: "recent", area: .flexibility, lastPlayed: day(-2)),
        ]

        for seed in UInt64(1)...20 {
            let result = plan(candidates, seed: seed)
            XCTAssertEqual(result, ["oldest", "middle", "recent"], "Seed \(seed)")
        }
    }

    func testFewerCandidatesThanCountReturnsAll() {
        let candidates = Array(fiveFreshCandidates().prefix(2))

        let result = plan(candidates)

        XCTAssertEqual(Set(result), ["a", "b"])
        XCTAssertEqual(result.count, 2)
    }

    func testNoCandidatesReturnsEmptyPlan() {
        XCTAssertEqual(plan([]), [])
    }

    func testFillsUpWithSameAreaWhenAreasAreNotEnough() {
        let candidates = [
            TeaBreakCandidate(gameID: "a", area: .focus, lastPlayed: day(-5)),
            TeaBreakCandidate(gameID: "b", area: .focus, lastPlayed: day(-4)),
            TeaBreakCandidate(gameID: "c", area: .logic, lastPlayed: day(-3)),
            TeaBreakCandidate(gameID: "d", area: .focus, lastPlayed: day(-2)),
        ]

        let result = plan(candidates)

        // Erst je ein Spiel pro Bereich (a: ältestes Focus, c: Logic), dann
        // mit dem ältesten verbleibenden aufgefüllt (b).
        XCTAssertEqual(result, ["a", "c", "b"])
    }

    func testSameSeedGivesSameResult() {
        let candidates = fiveFreshCandidates()

        XCTAssertEqual(plan(candidates, seed: 7), plan(candidates, seed: 7))
    }

    func testDifferentSeedsCanGiveDifferentResults() {
        let candidates = fiveFreshCandidates()
        let results = Set((UInt64(1)...30).map { plan(candidates, seed: $0) })

        XCTAssertGreaterThan(results.count, 1, "Die Auswahl unter gleichwertigen Spielen sollte variieren")
    }

    // MARK: - Luecken aus Paket F (Anzahl 0, feste Auswahl fuer UI-Tests)

    func testCountZeroOrNegativeReturnsEmptyPlan() {
        XCTAssertEqual(plan(fiveFreshCandidates(), count: 0), [])
        XCTAssertEqual(plan(fiveFreshCandidates(), count: -2), [])
    }

    #if DEBUG
    func testForcedPlanKeepsOrderWhenAllGamesArePlayable() {
        XCTAssertEqual(
            TeaBreakPlanner.forcedPlan(["c", "a", "b"], playable: ["a", "b", "c", "d"]),
            ["c", "a", "b"]
        )
    }

    func testForcedPlanIsNilForEmptyDuplicateOrUnplayableIDs() {
        XCTAssertNil(TeaBreakPlanner.forcedPlan([], playable: ["a", "b"]))
        XCTAssertNil(TeaBreakPlanner.forcedPlan(["a", "a"], playable: ["a", "b"]))
        XCTAssertNil(TeaBreakPlanner.forcedPlan(["a", "z"], playable: ["a", "b"]))
    }
    #endif
}
