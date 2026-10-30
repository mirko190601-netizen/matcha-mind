# Matcha Mind · Designsystem v2

Stand 29.10.2026. Änderungen zu v1: iPad + Sprachen (de/en/fr) ergänzt, **Illustration v2** (detailliert, gezeichnet) ersetzt die flache Illustration, neue Spielwelt-Tokens für Fuchs, Koi und Linien.

Gehirnjogging im Teegarten. Matcha Mind sieht aus wie ein ruhiger japanischer Teegarten und fordert den Kopf trotzdem spürbar. Dieses Designsystem legt fest, wie jeder Screen aussieht, klingt und sich bedient, damit die App wie aus einem Guss wirkt.

**Gilt für:** iOS-/iPadOS-App (SwiftUI, ab 26), App-Store-Auftritt, Screenshots, Support-Seite.

## Grundsätze

1. **Ruhiger Look, echte Aufgabe.** Die Optik entspannt, die Spiele fordern. Nichts blinkt, nichts drängt, aber die Aufgaben sind ernst gemeint.
2. **Eine Welt.** Alles stammt aus dem Teegarten: Spiele, Belohnungen, Stufennamen (Sencha, Oolong, Matcha), Texte.
3. **Glas bedient, Garten erzählt.** Liquid Glass nur für Bedienelemente. Illustrationen sind warm, detailreich und wirken handgezeichnet.
4. **Fehler sind kein Drama.** Keine roten Markierungen, kein Punktabzug, kein Countdown.

## Name & Schreibweise

- Immer **Matcha Mind**, zwei Wörter, beide groß. Nie „MatchaMind“ oder „matcha mind“.
- Untertitel: de **Gehirnjogging im Teegarten** · en **Brain training in a tea garden** · fr **Entraînement cérébral au jardin de thé**.
- Logo: Name in Zen Maru Gothic 700 in `ink`. App-Icon: Teeschale mit Blatt, Grund `matcha-600`.

## Texte & Tonfall

- **Du-Form** (en: „you“, fr: „tu“), warm, kurz. Ein Gedanke pro Satz, höchstens 2 Sätze pro Hinweis.
- **Neugier statt Druck:** „Im Bambushain ist etwas aufgeblüht.“ statt „Deine Pflanzen vermissen dich.“
- **Fehler-Texte:** „Fast – nochmal?“ statt „Falsch!“. Farbe `feedback-gentle`.
- **Keine Gesundheitsversprechen:** nie „verbessert dein Gedächtnis“ oder „wissenschaftlich bewiesen“. Erlaubt: „inspiriert von Übungen aus der Kognitionsforschung“.
- **Zahlen** als Ziffern („3 Spiele“, „14 Tage“), Einheiten mit Leerzeichen („30 s“).
- **Sprachen:** Deutsch ist Entwicklungssprache, dazu Englisch und Französisch. Alle Texte in `Localizable.xcstrings`; Französisch ist am längsten, Layouts müssen das tragen.

## Farben

Zwei Themen: **Tag** (Standard, hell) und **Abend** (Dunkelmodus, folgt der Systemeinstellung). Jede Farbe gibt es in beiden, die Werte stehen in `designsystem-tokens.json`.

| Rolle | Token | Regel |
| --- | --- | --- |
| Hintergrund | `bg-garden`, `bg-tea`, `bg-band` | Garten- und Spiel-Screens auf `bg-garden`, ruhige Screens (Teepause, Anleitung, Einstellungen) auf `bg-tea`. |
| Text | `ink`, `text`, `text-muted` | Überschriften `ink`, Fließtext `text`, Nebeninfos `text-muted`. Keine anderen Textfarben außer den Ausnahmen unten. |
| Primär | `matcha-600` + `on-primary` | Genau **ein** Haupt-Button pro Screen. Auch für Fortschritt, aktiven Tab, Schalter. |
| Auswahl & Neu | `lavender-500`, `lavender-100`, `lavender-700` | Höchstens ein lavendelfarbenes Element pro Screen. |
| Belohnung | `tau-400`, `tau-700` | Nur für Tautropfen. Mengen-Text in `tau-700`. |
| Stufen | `level-sencha`, `level-oolong`, `level-matcha` | Nur als Punkt oder Akzent neben dem Stufennamen, nie als Fläche. |
| Spielwelt | `wood-500`, `wood-700`, `gold-300`, `blossom-300`, `matcha-300`, `fox-500`, `fox-200`, `koi-500`, `koi-white`, `line-art` | Illustrationen und Spielfiguren. Nie für Text. |
| Rückmeldung | `feedback-good`, `feedback-gentle` | Text nach einer Antwort. **Kein Rot** in der ganzen App. |

Alle Textpaare erfüllen 4.5:1 in beiden Themen. Farben, die unterschieden werden müssen (z. B. Spielfiguren), unterscheiden sich zusätzlich in Form oder Helligkeit, nie nur im Farbton.

## Schrift

| Familie | Einsatz | Lizenz |
| --- | --- | --- |
| **Zen Maru Gothic** 700 | Überschriften: `display`, `title`, `headline` | SIL OFL, als Datei in der App |
| **Nunito** 400/600/700/800 | Alles andere: `body`, `button`, `callout`, `caption`, `label` | SIL OFL, als Datei in der App |

- In SwiftUI immer mit Dynamic Type: `.font(.custom("Nunito-SemiBold", size: 16, relativeTo: .body))`.
- Höchstens 2 Schriftgrößen-Stufen pro Karte.
- Keine Kursiv- oder Großbuchstaben-Texte außer im `label`-Stil für Abzeichen.
- Zen Maru Gothic deckt Französisch (Akzente) ab; vor Release in allen drei Sprachen sichtprüfen.

## Abstände, Radien, Schatten

- **Raster 4 px.** Seitenrand Text 24, Karten 20. Abstand zwischen Karten 12, zwischen Abschnitten 32.
- **Radien:** Felder 12, Kacheln 16, Listenkarten 22, Hauptkarten und Fenster 28, Buttons rund (`radius-pill`).
- **Ein Schatten** (`shadow-card`), nur für Hauptkarten und die Tab-Leiste.
- **Tippflächen** mindestens 44 × 44 pt, Haupt-Buttons 54 pt hoch.

## iPad

- Navigation: `TabView` mit `.sidebarAdaptable` (iPhone Tab-Leiste, iPad Seitenleiste).
- Inhalte nicht einfach strecken: Lesespalten max. ca. 640 pt, Spielbretter mittig mit Maximalbreite, Bibliothek 3–4 Spalten.
- Garten-Szene auf dem iPad breiter komponiert (zusätzliche Szenenteile links/rechts), nicht nur hochskaliert.
- Alle Ausrichtungen und Fenstergrößen; Sheets als Formular-Fenster.

## Liquid Glass

- **Glas für:** Tab-Leiste/Seitenleiste, runde Kopfzeilen-Buttons (Zurück, Pause, ?), Hinweis- und Regel-Karten, Fenster (Sheets), Sekundär-Buttons.
- **Kein Glas für:** Spielbrett, Spielfiguren, Illustrationen, Haupt-Button (der ist voll `matcha-600`).
- In SwiftUI: `.glassEffect(.regular, in: .rect(cornerRadius: 28))`. Nah beieinander liegende Glas-Elemente in `GlassEffectContainer`.
- Höchstens zwei Glas-Ebenen übereinander.

## Illustration v2 (verbindlich)

Ziel: Der Garten und seine Tiere sehen **gezeichnet, detailreich und liebevoll** aus – wie eine hochwertige Bilderbuch-Illustration, nicht wie flache Grundformen. Die Konzept-Screens sind nur Platzhalter-Niveau.

**Technik**
- Vektor: SVG im Asset-Katalog („Preserve Vector Data“) für statische Figuren; SwiftUI-Shapes/Canvas für animierte Teile. Keine Fotos, keine KI-Bilder, keine fremden Grafiken.
- Jede Figur in Tag- und Abend-Variante (Abend: gedämpfter, mit warmem `gold-300`-Licht).

**Gestaltung**
- **Tonstufen:** jede Fläche in 3–5 Abstufungen derselben Farbe (Licht, Grundton, Schatten, Tiefschatten). Weiche, kurze Verläufe innerhalb einer Fläche sind erlaubt, keine grellen Verläufe über ganze Szenen.
- **Linien:** feine Konturen nur in `line-art` oder einer dunkleren Stufe der Füllfarbe, 0,75–1,5 pt, runde Enden, leicht unregelmäßig (handgezeichnet). Nie reines Schwarz.
- **Details:** Fuchs mit Fellstrichen, hellem Brustlatz, Schwanzspitze, Augenglanz · Schmetterlinge mit Flügeladern, Musterflecken, Fühlern · Koi mit Schuppenandeutung und halbtransparenten Flossen · Kranich mit Federstruktur · Holz mit Maserung · Bambus mit Knoten · Blätter mit Mittelader · Wasser mit Reflexen und Ringen · Steine mit Moos.
- **Textur:** sehr dezente Papier-/Aquarellkörnung als Overlay (3–5 % Deckkraft) auf Szenen, nicht auf Bedienelementen.
- **Licht:** eine Lichtrichtung (oben links) für die ganze App; weiche Bodenschatten unter Figuren.
- **Farben** nur aus der Spielwelt-Palette und ihren Tonstufen.

**Spielfiguren**
- Lesbarkeit vor Detail: bei 44 pt eindeutig erkennbar, klare Silhouette, Unterscheidung über Form + Helligkeit.
- Weniger Feindetails als in der Garten-Szene, gleicher Zeichenstil.

**Bewegung der Illustrationen**
- Ruhige Dauer-Animationen (Flügelschlag, Schwanz, Koi, Bambus, Glimmen, Wasserringe), 2–6 s pro Zyklus, leicht zufällig versetzt.
- Bei „Bewegung reduzieren“: Standbild.

**Prüf-Checkliste je Figur**
1. Silhouette auf 44 pt erkennbar? 2. Mind. 3 Tonstufen? 3. Typische Details vorhanden (Liste oben)? 4. Nur Palette-Farben? 5. Tag + Abend stimmig? 6. VoiceOver-Name gesetzt? 7. Wirkt gezeichnet, nicht geometrisch?

**Gartenbereiche:** Teehaus, Koi-Teich (Sencha) · Bambushain (Oolong) · Mondbrücke (Matcha) · Kirschbaum-Hügel (Deko). Gesperrte Bereiche: 45 % Deckkraft + Schloss-Chip aus Glas mit „ab Oolong“.

**Tierbesuche:** Fuchs, Kranich, Schmetterlinge besuchen den Garten gelegentlich – nur Deko, macht neugierig, nie Druck.

## Icons

- **SF Symbols**, Stil „rounded“ wo verfügbar, Strichstärke `.medium`, Farbe = Textfarbe des Umfelds.
- Eigene Icons (Tautropfen, Teeschale, Blatt) als SVG mit 1,8-px-Linie und runden Enden.
- Keine Emojis.

## Klang

- Leise Naturklänge (Wasser, Wind, Windspiel) und weiche Spielklänge. Nur lizenzfreie (CC0) oder in der App erzeugte Klänge. Standardmäßig an, abschaltbar.

## Bewegung (Bedienung)

- Sanft: 250–350 ms, `easeOut` oder `.spring(duration: 0.35, bounce: 0.15)`.
- Belohnungen (Tautropfen fliegen ins Glas, Pflanze wächst) dürfen 600–900 ms dauern.
- **Bewegung reduzieren** respektieren: dann nur Überblendungen.
- Haptik: `.sensoryFeedback(.success)` bei Treffern, nie bei Fehlern.

## Komponenten

| Komponente | Wann | Regeln |
| --- | --- | --- |
| **Primär-Button** | Die eine Hauptaktion pro Screen | `matcha-600`, Text `on-primary` im Stil `button`, 54 pt hoch, rund. |
| **Glas-Button** | Nebenaktionen | Glas, Text `text` im Stil `button`, 50 pt hoch, rund. |
| **Glas-Karte** | Teepause, Hinweise, Regeln, Einstellungen | Glas, Radius 22 oder 28, Innenabstand 16–20. |
| **Kopfzeilen-Button** | Zurück, Pause, ? | Runder Glas-Kreis 44 pt, Icon 18–20 pt. |
| **Regel-Button (?)** | In **jedem** Spiel oben rechts | Glas-Kreis 36 pt sichtbar, Tippfläche 44 pt, Icon `questionmark` in `text-muted`. Öffnet Regel-Fenster, pausiert. |
| **Spielanleitung** | Erster Start eines Spiels | Sheet `.large`, bis 3 Seiten, Seitenpunkte, „Überspringen“, „Weiter“ / „Los geht’s“ / „Proberunde starten“. |
| **Regel-Fenster** | Tipp auf ? | Sheet `.medium`, 3–4 Kurzregeln, „Ganze Anleitung ansehen“, „Weiterspielen“. |
| **Stufen-Abzeichen** | Überall, wo die Stufe steht | Punkt in `level-…` + Stufenname im Stil `callout`. |
| **Neu-Abzeichen** | Neue Spiele, neue Bereiche | `lavender-100` + `lavender-700`, Stil `label`. |
| **Werbe-Hinweis** | Vor einer Werbung | Glas-Karte „Kurze Pause – gleich geht’s weiter“ + Glas-Button „Werbefrei für 4,99 €“. Nie während eines Spiels. |

## Barrierefreiheit

- Dynamic Type bis XXL ohne abgeschnittenen Text (in allen drei Sprachen); Listen werden dann einspaltig.
- VoiceOver-Beschriftung für jedes Icon, jede Figur und jede Spielfigur.
- Spiele, die Farben nutzen, unterscheiden zusätzlich über Form.
- Kontraste wie oben, in beiden Themen.

## Für Entwickler (SwiftUI)

- Jede Farbe als Color Set in `Assets.xcassets` mit Tag- und Abend-Variante, Name = Token-Name, zusätzlich typsicher (`Color.matcha600`). Erzeugt per Skript aus `designsystem-tokens.json`.
- Schriften als Dateien in `Fonts/`, eingetragen in `Info.plist` → `UIAppFonts`.
- Abstände, Radien, Größen als `enum Space` / `enum Radius` / `enum Size`, keine Zahlen direkt im View-Code.
