// PlayerStore+Preview.swift
// Fluechtiger Speicher fuer SwiftUI-Vorschauen (nur Arbeitsspeicher, keine
// Datei). Wird ausschliesslich von `#Preview`-Bloecken benutzt.

import Foundation
import SwiftData

extension PlayerStore {
    /// Speicher nur im Arbeitsspeicher, optional mit gesetzter Stufe.
    static func preview(level: TeaLevel = .sencha) -> PlayerStore {
        guard let container = try? makeContainer(inMemory: true) else {
            fatalError("Vorschau: Spielerdaten-Container konnte nicht angelegt werden")
        }
        let store = PlayerStore(container: container, clock: SystemClock())
        if level != .sencha {
            store.setLevel(level)
        }
        return store
    }
}
