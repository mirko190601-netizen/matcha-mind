// GameCatalog.swift
// Katalog-Metadaten aller 14 Spiele (MASTER-PROMPT.md, Abschnitt 6) fuer die
// Spiele-Bibliothek (Block B3 Aufgabe 4, `App/GamesLibraryView.swift`):
// die 5 bereits gebauten Sencha-Spiele (`isImplemented == true`) plus 9
// Platzhalter-Eintraege fuer die Oolong-/Matcha-Spiele, deren echte
// `GameDefinition`-Typen erst in B5/B6 entstehen.
//
// Fuer die 5 echten Spiele liest dieser Katalog `id`/`nameKey`/`area`/
// `minLevel`/`shortRuleKeys`/`hasTrialRound` direkt von der jeweiligen
// `GameDefinition`-Instanz (keine Dopplung dieser Werte). Einzige
// Ausnahme: die Anleitungsseiten der 4 vor diesem Auftrag gebauten Spiele
// (Teekannen-Reihe, Glühwürmchen, Mosaik-Beet, Teeblätter) liegen bisher
// nur lokal in deren `*GameView.swift` - deren Schluessel werden hier
// bewusst als Literal wiederholt, statt die 4 bestehenden Spieldateien fuer
// diesen Auftrag anzufassen (siehe `BambooMathGame.instructionPages` fuer
// die saubere Variante ohne Dopplung, dort direkt moeglich, weil diese
// Datei neu in diesem Auftrag entsteht).

import Foundation

/// Text des Schloss-Chips je Ziel-Stufe, analog zu
/// `Illustration/GardenScene.swift`'s `GardenLockLabel` (eigener Typ statt
/// Wiederverwendung, da Garten und Spiele-Bibliothek unterschiedliche
/// String-Catalog-Namensräume haben: `garden.locked.*` vs. `game.locked.*`).
public enum GameLockLabel: Equatable {
    case oolong
    case matcha

    var text: String {
        switch self {
        case .oolong:
            String(localized: "game.locked.oolong", defaultValue: "ab Oolong")
        case .matcha:
            String(localized: "game.locked.matcha", defaultValue: "ab Matcha")
        }
    }
}

public extension GameArea {
    /// SF-Symbol je Bereich fuer die Spiel-Kachel in der Bibliothek. Rein
    /// dekorativ (Name steht zusaetzlich als Text daneben/darunter).
    var symbolName: String {
        switch self {
        case .spatialMemory: "circle.grid.3x3.fill"
        case .focus: "eye.fill"
        case .logic: "puzzlepiece.fill"
        case .flexibility: "arrow.triangle.2.circlepath"
        case .mentalMath: "plusminus.circle.fill"
        case .workingMemory: "brain.head.profile"
        case .impulseControl: "hand.raised.fill"
        case .spatialReasoning: "cube.fill"
        case .planning: "map.fill"
        case .language: "textformat.abc"
        case .dualWorkingMemory: "arrow.triangle.branch"
        case .reasoning: "lightbulb.fill"
        case .dividedAttention: "scope"
        case .patternRecognition: "square.grid.2x2.fill"
        }
    }
}

/// Ein Eintrag der Spiele-Bibliothek: Katalog-Metadaten plus Angabe, ob das
/// Spiel schon gebaut ist (`isImplemented`). Die Freischaltung haengt von der
/// Spielerstufe ab, siehe `GameCatalog.isUnlocked(_:playerLevel:)`.
public struct GameCatalogEntry: Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let area: GameArea
    public let minLevel: TeaLevel
    public let isImplemented: Bool
    public let hasTrialRound: Bool
    public let shortRuleKeys: [String]
    public let instructionPages: [GameInstructionPage]

    public init(
        id: String,
        nameKey: String,
        area: GameArea,
        minLevel: TeaLevel,
        isImplemented: Bool,
        hasTrialRound: Bool = false,
        shortRuleKeys: [String] = [],
        instructionPages: [GameInstructionPage] = []
    ) {
        self.id = id
        self.nameKey = nameKey
        self.area = area
        self.minLevel = minLevel
        self.isImplemented = isImplemented
        self.hasTrialRound = hasTrialRound
        self.shortRuleKeys = shortRuleKeys
        self.instructionPages = instructionPages
    }

    public var lockLabel: GameLockLabel? {
        switch minLevel {
        case .sencha: nil
        case .oolong: .oolong
        case .matcha: .matcha
        }
    }
}

/// Katalog aller 14 Spiele, gruppiert nach Stufe fuer die Bibliothek.
public enum GameCatalog {
    // `nonisolated(unsafe)`: jedes Spiel ist eine reine, nach der Erzeugung
    // unveraenderliche Definition (keine Mutation nach `init`); die
    // konkreten Spiel-Typen selbst Sendable zu machen wuerde kaskadierend
    // jede ihrer Eigenschaften erfassen muessen - diese fuenf Konstanten
    // sind nachweislich sicher gemeinsam lesbar.
    private nonisolated(unsafe) static let teapotRow = TeapotRowGame()
    private nonisolated(unsafe) static let fireflyPond = FireflyPondGame()
    private nonisolated(unsafe) static let mosaicBed = MosaicBedGame()
    private nonisolated(unsafe) static let teaLeafSort = TeaLeafSortGame()
    private nonisolated(unsafe) static let bambooMath = BambooMathGame()

    /// Alle 14 Spiele in Katalog-Reihenfolge (MASTER-PROMPT.md, Abschnitt 6).
    public static let allGames: [GameCatalogEntry] = [
        // 1-5: Sencha, bereits gebaut und spielbar.
        GameCatalogEntry(
            id: teapotRow.id,
            nameKey: teapotRow.nameKey,
            area: teapotRow.area,
            minLevel: teapotRow.minLevel,
            isImplemented: true,
            hasTrialRound: teapotRow.hasTrialRound,
            shortRuleKeys: teapotRow.shortRuleKeys,
            instructionPages: [
                GameInstructionPage(
                    id: 0,
                    titleKey: "game.teapotRow.instruction.page1.title",
                    bodyKey: "game.teapotRow.instruction.page1.body"
                ),
                GameInstructionPage(
                    id: 1,
                    titleKey: "game.teapotRow.instruction.page2.title",
                    bodyKey: "game.teapotRow.instruction.page2.body"
                ),
                GameInstructionPage(
                    id: 2,
                    titleKey: "game.teapotRow.instruction.page3.title",
                    bodyKey: "game.teapotRow.instruction.page3.body"
                ),
            ]
        ),
        GameCatalogEntry(
            id: fireflyPond.id,
            nameKey: fireflyPond.nameKey,
            area: fireflyPond.area,
            minLevel: fireflyPond.minLevel,
            isImplemented: true,
            hasTrialRound: fireflyPond.hasTrialRound,
            shortRuleKeys: fireflyPond.shortRuleKeys,
            instructionPages: [
                GameInstructionPage(
                    id: 0,
                    titleKey: "game.fireflyPond.instruction.page1.title",
                    bodyKey: "game.fireflyPond.instruction.page1.body"
                ),
                GameInstructionPage(
                    id: 1,
                    titleKey: "game.fireflyPond.instruction.page2.title",
                    bodyKey: "game.fireflyPond.instruction.page2.body"
                ),
                GameInstructionPage(
                    id: 2,
                    titleKey: "game.fireflyPond.instruction.page3.title",
                    bodyKey: "game.fireflyPond.instruction.page3.body"
                ),
            ]
        ),
        GameCatalogEntry(
            id: mosaicBed.id,
            nameKey: mosaicBed.nameKey,
            area: mosaicBed.area,
            minLevel: mosaicBed.minLevel,
            isImplemented: true,
            hasTrialRound: mosaicBed.hasTrialRound,
            shortRuleKeys: mosaicBed.shortRuleKeys,
            instructionPages: [
                GameInstructionPage(
                    id: 0,
                    titleKey: "game.mosaicBed.instruction.page1.title",
                    bodyKey: "game.mosaicBed.instruction.page1.body"
                ),
                GameInstructionPage(
                    id: 1,
                    titleKey: "game.mosaicBed.instruction.page2.title",
                    bodyKey: "game.mosaicBed.instruction.page2.body"
                ),
                GameInstructionPage(
                    id: 2,
                    titleKey: "game.mosaicBed.instruction.page3.title",
                    bodyKey: "game.mosaicBed.instruction.page3.body"
                ),
            ]
        ),
        GameCatalogEntry(
            id: teaLeafSort.id,
            nameKey: teaLeafSort.nameKey,
            area: teaLeafSort.area,
            minLevel: teaLeafSort.minLevel,
            isImplemented: true,
            hasTrialRound: teaLeafSort.hasTrialRound,
            shortRuleKeys: teaLeafSort.shortRuleKeys,
            instructionPages: [
                GameInstructionPage(
                    id: 0,
                    titleKey: "game.teaLeafSort.instruction.page1.title",
                    bodyKey: "game.teaLeafSort.instruction.page1.body"
                ),
                GameInstructionPage(
                    id: 1,
                    titleKey: "game.teaLeafSort.instruction.page2.title",
                    bodyKey: "game.teaLeafSort.instruction.page2.body"
                ),
                GameInstructionPage(
                    id: 2,
                    titleKey: "game.teaLeafSort.instruction.page3.title",
                    bodyKey: "game.teaLeafSort.instruction.page3.body"
                ),
            ]
        ),
        GameCatalogEntry(
            id: bambooMath.id,
            nameKey: bambooMath.nameKey,
            area: bambooMath.area,
            minLevel: bambooMath.minLevel,
            isImplemented: true,
            hasTrialRound: bambooMath.hasTrialRound,
            shortRuleKeys: bambooMath.shortRuleKeys,
            instructionPages: bambooMath.instructionPages
        ),

        // 6-10: Oolong, Platzhalter - Logik folgt in Block B5.
        GameCatalogEntry(
            id: "tea-ceremony-echo",
            nameKey: "game.teaCeremonyEcho.name",
            area: .workingMemory,
            minLevel: .oolong,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "lantern-colorword",
            nameKey: "game.lanternColorWord.name",
            area: .impulseControl,
            minLevel: .oolong,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "stone-lantern",
            nameKey: "game.stoneLantern.name",
            area: .spatialReasoning,
            minLevel: .oolong,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "garden-path-planner",
            nameKey: "game.gardenPathPlanner.name",
            area: .planning,
            minLevel: .oolong,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "word-garden",
            nameKey: "game.wordGarden.name",
            area: .language,
            minLevel: .oolong,
            isImplemented: false
        ),

        // 11-14: Matcha, Platzhalter - Logik folgt in Block B6.
        GameCatalogEntry(
            id: "moon-bridge",
            nameKey: "game.moonBridge.name",
            area: .dualWorkingMemory,
            minLevel: .matcha,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "master-mosaic",
            nameKey: "game.masterMosaic.name",
            area: .reasoning,
            minLevel: .matcha,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "koi-swarm",
            nameKey: "game.koiSwarm.name",
            area: .dividedAttention,
            minLevel: .matcha,
            isImplemented: false
        ),
        GameCatalogEntry(
            id: "gardener-pattern",
            nameKey: "game.gardenerPattern.name",
            area: .patternRecognition,
            minLevel: .matcha,
            isImplemented: false
        ),
    ]

    /// Kennungen der bereits gebauten (spielbaren) Spiele.
    public static let playableGameIDs: Set<String> = Set(allGames.filter { $0.isImplemented }.map { $0.id })

    /// Ein Spiel ist spielbar, wenn es gebaut ist und die Spielerstufe
    /// mindestens seiner Mindeststufe entspricht.
    public static func isUnlocked(_ entry: GameCatalogEntry, playerLevel: TeaLevel) -> Bool {
        entry.isImplemented && entry.minLevel <= playerLevel
    }

    /// Alle spielbaren Spiele fuer eine Spielerstufe, in Katalog-Reihenfolge
    /// (Grundlage fuer die Teepause).
    public static func playableGames(for playerLevel: TeaLevel) -> [GameCatalogEntry] {
        allGames.filter { isUnlocked($0, playerLevel: playerLevel) }
    }

    /// Die Eintraege einer Stufe, in Katalog-Reihenfolge - fuer die
    /// nach Stufe gruppierten Abschnitte der Bibliothek.
    public static func games(for level: TeaLevel) -> [GameCatalogEntry] {
        allGames.filter { $0.minLevel == level }
    }
}
