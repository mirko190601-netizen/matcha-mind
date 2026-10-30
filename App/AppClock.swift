import Foundation

/// Liefert die aktuelle Zeit - austauschbar, damit Unit-Tests und spätere
/// UI-Test-Personas (siehe `MASTER-PROMPT.md`, Block B1 Aufgabe 7 und B9
/// Aufgabe 2) ein festes bzw. verschiebbares Datum einspeisen können, statt
/// auf die echte Systemuhr angewiesen zu sein.
/// `public`, weil `Games/Core/GameSession.swift` den Typ als Parameter
/// ihres `public`-Initialisierers nutzt (Swift verlangt dafuer oeffentliche
/// Sichtbarkeit fuer Protokoll und Produktions-Implementierung gleichermassen).
public protocol AppClock: Sendable {
    func now() -> Date
}

/// Produktions-Implementierung: liefert die echte Systemzeit.
public struct SystemClock: AppClock {
    public init() {}
    public func now() -> Date { Date() }
}

/// Test- und UI-Test-Implementierung mit einem injizierbaren, zur Laufzeit
/// verschiebbaren Datum.
///
/// Entscheidung Klasse statt `struct`: B9 Aufgabe 2 braucht ein Datum, das
/// *während* eines laufenden Persona-Tests verschoben werden kann (z. B.
/// "14 aktive Tage simulieren" bei Persona Tom). Ein `struct`-Wert würde bei
/// jeder Weitergabe (z. B. in `AppEnvironment`) kopiert; ein `set`/`advance`
/// auf einer Kopie würde die an anderer Stelle gehaltene Kopie nicht
/// erreichen. Als Referenztyp mit genau einer Instanz sehen alle Verwender
/// denselben, konsistenten Zeitstand.
///
/// `@unchecked Sendable` + `NSLock` statt `actor`: der Zustand
/// (`currentDate`) ist absichtlich veränderlich und muss synchron gelesen
/// werden können (`now()` wird von SwiftUI-Code aufgerufen, der nicht
/// `async` ist). Ein `actor` würde das erzwingen; für dieses einfache
/// Wert-Objekt ist ein kurzer Lock um eine einzelne `Date`-Variable die
/// einfachere, ebenso sichere Wahl.
final class FixedClock: AppClock, @unchecked Sendable {
    private let lock = NSLock()
    private var currentDate: Date

    init(date: Date) {
        self.currentDate = date
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return currentDate
    }

    /// Setzt das simulierte Datum auf einen neuen, festen Wert.
    func set(_ date: Date) {
        lock.lock()
        defer { lock.unlock() }
        currentDate = date
    }

    /// Verschiebt das simulierte Datum um das gegebene Zeitintervall
    /// (negative Werte verschieben nach hinten).
    func advance(by interval: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        currentDate = currentDate.addingTimeInterval(interval)
    }
}
