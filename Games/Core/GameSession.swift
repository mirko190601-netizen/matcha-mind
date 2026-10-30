// GameSession.swift
// Gemeinsamer Spiel-Baukasten (MASTER-PROMPT.md, Block B3 Aufgabe 1):
// Zustandsmaschine fuer eine einzelne Spielrunde. Erzwingt nur die
// Zustandsuebergaenge - die genaue Rundendauer (60-90 s laut Katalog)
// gibt jedes Spiel selbst vor.

import Foundation
import Observation

/// Ergebnis einer beendeten Spielrunde.
public struct GameResult: Equatable, Sendable {
    public let hits: Int
    public let misses: Int
    public let duration: TimeInterval

    /// Trefferquote 0.0-1.0. Ohne Versuche (0 Treffer, 0 Fehler) 0, statt
    /// durch 0 zu teilen.
    public var accuracy: Double {
        let attempts = hits + misses
        guard attempts > 0 else { return 0 }
        return Double(hits) / Double(attempts)
    }

    public init(hits: Int, misses: Int, duration: TimeInterval) {
        self.hits = hits
        self.misses = misses
        self.duration = duration
    }
}

/// Zustaende einer Spielrunde.
public enum GameSessionState: Equatable, Sendable {
    case notStarted
    case running
    case paused
    case finished(GameResult)
}

/// Zustandsmaschine einer Spielrunde. Erlaubte Uebergaenge:
/// `notStarted -> running` (`start`), `running <-> paused`
/// (`pause`/`resume`), `running/paused -> finished` (`finish`). Jeder
/// Aufruf ausserhalb seines gueltigen Ausgangszustands wird ignoriert
/// (kein Absturz, kein unerwarteter Zustandswechsel).
///
/// Nutzt `AppClock` injizierbar fuer Zeitmessung, damit Tests ein festes
/// Datum vorgeben koennen (siehe `App/AppClock.swift`). `elapsedPlayTime()`
/// liefert die bisher *ohne Pausen* verstrichene Spielzeit; einzelne
/// Spiele koennen diesen Wert als `duration` an `finish` uebergeben.
@Observable
public final class GameSession {
    public private(set) var state: GameSessionState = .notStarted

    private let clock: AppClock
    private var startedAt: Date?
    private var pausedAt: Date?
    private var pausedAccumulated: TimeInterval = 0

    public init(clock: AppClock = SystemClock()) {
        self.clock = clock
    }

    @discardableResult
    public func start() -> Bool {
        guard state == .notStarted else { return false }
        startedAt = clock.now()
        pausedAt = nil
        pausedAccumulated = 0
        state = .running
        return true
    }

    @discardableResult
    public func pause() -> Bool {
        guard state == .running else { return false }
        pausedAt = clock.now()
        state = .paused
        return true
    }

    @discardableResult
    public func resume() -> Bool {
        guard state == .paused, let pausedAt else { return false }
        pausedAccumulated += clock.now().timeIntervalSince(pausedAt)
        self.pausedAt = nil
        state = .running
        return true
    }

    /// Seit `start()` verstrichene Spielzeit ohne Pausenzeit.
    /// `0`, solange die Runde noch nicht gestartet wurde.
    public func elapsedPlayTime() -> TimeInterval {
        guard let startedAt else { return 0 }
        let pausedSoFar = pausedAccumulated + (pausedAt.map { clock.now().timeIntervalSince($0) } ?? 0)
        return clock.now().timeIntervalSince(startedAt) - pausedSoFar
    }

    @discardableResult
    public func finish(hits: Int, misses: Int, duration: TimeInterval) -> Bool {
        guard state == .running || state == .paused else { return false }
        state = .finished(GameResult(hits: hits, misses: misses, duration: duration))
        return true
    }
}
