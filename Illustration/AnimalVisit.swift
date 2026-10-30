// AnimalVisit.swift
// Tierbesuche (design/designsystem-README.md, Abschnitt "Illustration v2" ->
// "Tierbesuche": "Fuchs, Kranich, Schmetterlinge besuchen den Garten
// gelegentlich - nur Deko, macht neugierig, nie Druck."), MASTER-PROMPT.md
// B2 P8. `AnimalVisitOverlay` ist eine eigenstaendige, testbare Komponente,
// die optional ueber `GardenScene` gelegt werden kann
// (`ZStack { GardenScene(...); AnimalVisitOverlay() }`) - noch nicht fest in
// `Illustration/GardenScene.swift` verdrahtet (siehe Auftrag).

import SwiftUI

/// Welches Tier gerade zu Besuch ist.
public enum AnimalVisitor: CaseIterable {
    case fox
    case crane
    case butterfly

    /// Deutsche Beschreibung aus `Resources/Localizable.xcstrings`
    /// (Schlüssel `garden.visit.*`). Als Literal-Aufruf geschrieben (nicht
    /// über einen dynamischen Schlüssel), damit sowohl
    /// `scripts/check_localization.py` als auch
    /// `Tests/Unit/LocalizationCoverageTests.swift` den Schlüssel per Regex
    /// finden.
    var accessibilityLabel: String {
        switch self {
        case .fox:
            String(localized: "garden.visit.fox", defaultValue: "Ein Fuchs schaut vorbei")
        case .crane:
            String(localized: "garden.visit.crane", defaultValue: "Ein Kranich schaut vorbei")
        case .butterfly:
            String(localized: "garden.visit.butterfly", defaultValue: "Ein Schmetterling schaut vorbei")
        }
    }

    /// Die vorhandene Illustration, die fuer diesen Besuch gezeigt wird.
    @ViewBuilder
    var illustration: some View {
        switch self {
        case .fox:
            FoxIllustration(pose: .sitting)
        case .crane:
            CraneIllustration(pose: .standing)
        case .butterfly:
            ButterflyIllustration(species: .blossom)
        }
    }
}

/// Reine Entscheidungslogik fuer einen zufaelligen Tierbesuch, getrennt von
/// der View, damit sie ohne UI-Rendering testbar ist.
public enum AnimalVisitModel {
    /// Wuerfelt (mit `chance`-Wahrscheinlichkeit) einen zufaelligen Besucher,
    /// sonst `nil`. Nutzt den systemweiten Zufallsgenerator.
    public static func rollVisitor(chance: Double = 0.2) -> AnimalVisitor? {
        var generator = SystemRandomNumberGenerator()
        return rollVisitor(chance: chance, using: &generator)
    }

    /// Wie `rollVisitor(chance:)`, aber mit einem uebergebenen
    /// `RandomNumberGenerator` - so laesst sich das Verhalten in Unit-Tests
    /// deterministisch nachstellen (ein fester Generator statt Zufall).
    public static func rollVisitor(
        chance: Double,
        using generator: inout some RandomNumberGenerator
    ) -> AnimalVisitor? {
        guard chance > 0, Double.random(in: 0..<1, using: &generator) < chance else { return nil }
        return AnimalVisitor.allCases.randomElement(using: &generator)
    }
}

/// Zeigt rein dekorativ gelegentlich eines der Tiere kurz am Rand der
/// Garten-Szene ein- und nach einigen Sekunden wieder ausgeblendet. Wuerfelt
/// einmalig beim Erscheinen per `AnimalVisitModel.rollVisitor(chance:)`
/// (`@State`, nicht bei jedem Re-Render neu). Optional über `GardenScene`
/// legbar: `ZStack { GardenScene(...); AnimalVisitOverlay() }` - noch nicht
/// fest in `GardenScene.swift` verdrahtet.
public struct AnimalVisitOverlay: View {
    private let chance: Double
    private let visibleDuration: TimeInterval

    @State private var currentVisitor: AnimalVisitor?

    public init(chance: Double = 0.2, visibleDuration: TimeInterval = 4) {
        self.chance = chance
        self.visibleDuration = visibleDuration
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            if let currentVisitor {
                currentVisitor.illustration
                    .frame(width: 64, height: 64)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(currentVisitor.accessibilityLabel)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: rollAndScheduleVisit)
    }

    private func rollAndScheduleVisit() {
        guard let visitor = AnimalVisitModel.rollVisitor(chance: chance) else { return }

        withAnimation {
            currentVisitor = visitor
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + visibleDuration) {
            withAnimation {
                currentVisitor = nil
            }
        }
    }
}

#Preview("Besuch sichtbar · Hell") {
    ZStack(alignment: .bottomTrailing) {
        Color("bg-garden")
        AnimalVisitor.fox.illustration
            .frame(width: 64, height: 64)
    }
    .frame(height: 220)
    .preferredColorScheme(.light)
}

#Preview("Besuch sichtbar · Dunkel") {
    ZStack(alignment: .bottomTrailing) {
        Color("bg-garden")
        AnimalVisitor.crane.illustration
            .frame(width: 64, height: 64)
    }
    .frame(height: 220)
    .preferredColorScheme(.dark)
}
