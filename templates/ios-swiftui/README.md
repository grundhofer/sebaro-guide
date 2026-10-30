# Musterapp: iOS-Vorlage mit sebaro (Swift, SwiftUI)

Ein kleines, vollständiges iOS-Projekt als Startpunkt für eine App im sebaro-Design. „Musterapp“ ist ein erfundener
Name, `de.example.musterapp` ein Platzhalter; beides ersetzt du in deinem Produkt. Erfunden sind die fünf
Beispieleinträge und alle Werte auf dem Daten-Bildschirm; beide tragen „Beispieldaten“, ein Beispieleintrag in der
Liste, im Detail und im Formular. Was du selbst anlegst, trägt die Marke nie (BEL-09).

sebaro kommt nur aus dem lokalen Swift-Paket `SebaroDesign/` in diesem Ordner: dem gefilterten iOS-Export der
Werkstatt sebaroDesign (D112), so wie die Web-Vorlagen den Web-Export in `public/sebaro/` tragen. Die App baut keine
sebaro-Bauteile nach und schreibt keine Farbe und keine Größe selbst: Alles, was nach sebaro aussieht, kommt aus den
SwiftUI-Teilen des Pakets (`SebaroAppRoot`, `SbScreen`, `SbTabBar`, `SbListRow`, `SbTextField`, `sbFormSheet`,
`sbConfirmDialog` …); eigene Abstände nehmen nur Tokens (`SebaroSpace`, `SebaroSpacing`), eigene Farben nur die
Rollen des Farbtons (`tone.textMuted`).

| | |
|---|---|
| Sprache, UI | Swift 6 (Sprachmodus 6), SwiftUI, ohne weitere Bibliothek |
| iOS | ab 17.0, wie das Paket (sebaroDesign spec/12 §1); iPhone und iPad |
| Xcode | 16 oder neuer (das Paket braucht `swift-tools-version:6.0`, das Projekt das Format 77); gebaut und getestet mit Xcode 27.1 (Simulatoren iOS 27.0 und 18.5) |
| Paket | `SebaroDesign/`, der iOS-Export ohne Produkt-ID, als Schnappschuss; welches Werkzeug ihn aus welchem Werkstatt-Commit mit welchem Token-Vertrag gemacht hat, steht nur in `SebaroDesign/sebaro-export.json` (`tool`, `sebaroDesign.commit`, `contracts.tokens`), und `python3 tools/sebaro-verify.py` zeigt es an |
| Sprachen | Deutsch (Rückfallsprache, `CFBundleDevelopmentRegion` = `de`, D111) und Englisch in `Musterapp/Localizable.xcstrings`; die Wörter der Teile kommen aus `SbMessages` |

## Was die Vorlage zeigt

Drei Ziele in sebaros eigener unterer Leiste `SbTabBar` (NAV-02, NAV-03, MOB-05: Icon und Wort, nur oberste Ebene,
nicht die `TabView` des Systems), dazu das Detail als Unterseite mit dem Zurück der Systemleiste und das Formular als
Sheet (NAV-05, MOB-07). Jeder Bildschirm hat `SbScreen` unter `SebaroAppRoot` (MOB-01) und höchstens eine
Hauptaktion, unten (AKT-01, AKT-02).

| Bildschirm | Datei | Was er zeigt | Regeln |
|---|---|---|---|
| Einträge (Liste) | `ListScreen.swift` | Suche (`SbSearchField`), Gruppen mit Zahl im Kopf („Offen 3“), erledigte Zeilen treten zurück, Schlusssatz, leerer Zustand „Noch keine Einträge“ und „Kein Eintrag mit „…““, Hauptaktion „Eintrag anlegen“ unten, „Beispieldaten“ in jeder Zeile eines Beispieleintrags; „Ausblenden“ im Kontextmenü der Zeile (langes Drücken, für VoiceOver eine Aktion der Zeile; kein Wischen) mit Kurzmeldung „„…“ ausgeblendet“ · „Rückgängig“ | DAT-01, DAT-02, DAT-07, HAL-05, EIN-05, TXT-05, BEL-09, MOB-06, EBE-05, AKT-04 |
| Eintrag (Detail) | `DetailScreen.swift` | „Beispieldaten“ unter dem Titel eines Beispieleintrags, Zustand als Glyphe und Wort, Notiz in `SbWrapText`, Eigenschaften flach (`SbMetaList`), Hauptaktion „Eintrag bearbeiten“; am Ende des Inhalts „Eintrag abschließen“ (endgültig, löscht nichts: 45°-Kante ohne Papierkorb) und „Eintrag löschen“ (Kante mit Papierkorb), beide fragen zuerst in sebaros Dialog; ein erledigter Eintrag hat keine Hauptaktion mehr | BEL-09, STA-01, STA-02, DAT-03, AKT-01, AKT-02, AKT-07, AKT-08, FOR-04, EBE-03, MOB-06, TXT-04, TXT-15 |
| Neuer Eintrag / Eintrag bearbeiten (Formular) | `FormScreen.swift` | sebaros Formular-Sheet in voller Höhe mit „Abbrechen“ oben und der Hauptaktion unten; „Beispieldaten“, solange Titel und Notiz eines Beispieleintrags unverändert sind; Beschriftung über dem Feld, „Notiz (optional)“ mit Zähler, Pflichtfeld ohne Zeichen; die Hauptaktion bleibt drückbar und sagt „Titel fehlt.“ am leeren Feld, der Fokus geht dorthin; „Priorität“ als Segmente, bei großer Schrift als Auswahl; „Aufwand in Stunden“ mit Minus und Plus (`SbStepper`), „Erinnern um“ als Zeile mit dem Sheet der halben Stunden (`SbTimeRow`); „Bleibt auf diesem Gerät.“ unter der Hauptaktion; „Abbrechen“ mit Änderungen fragt „Abbrechen“ · „Verwerfen“ · „Sichern“, Wischen nach unten schließt dann nicht | MOB-07, EBE-04, BEL-09, EIN-01, EIN-02, STA-03, EIN-04, EIN-06, ZUG-09, BEL-10, AKT-11 |
| Daten | `DataScreen.swift` | die Datenarten von `docs/daten.html` mit den Teilen des Pakets: ganze Zahl, Bruch, Dezimalzahl, große Zahl, Prozent, Geld, Abo, Einheit, „etwa“, Rang, Vorzeichen; Tag, Datum, kurzes Datum, Uhrzeit, Zeitfenster, Zeitspanne, Dauer, Restzeit; die festen Zustandswörter, „Konflikt“, „2 offen“; Fortschrittsbalken, Ring, Schritte; Tags, Kategorien, Markierung; Kennung und Version in sebaro Mono, Dateiname, Codeblock; sortierbare Tabelle mit Summe im Fuß; Kennzahlen mit Sparkline, Balken mit Ziel, Linie mit Lücke, zwei Reihen, Anteile, Histogramm, Abweichung vom Plan, Heatmap mit „heute“, Zielring; Bewertung | TXT-04, TXT-12, TXT-13, FAR-14, STA-02, STA-06, STA-09, STA-04, FAR-12, SCH-01, TXT-08, TXT-15, DAT-14, DAT-04, DAT-10, DAT-11, DAT-12, DAT-09, BEL-09 |
| Einstellungen | `SettingsScreen.swift` | „Hell oder Dunkel“ (Wie das System, Hell, Dunkel), „Farbton“ (Kühl, Warm), „Bewegung immer reduzieren“ aus dem Paket, „Sprache“ (Wie das System, Deutsch, English); alles gilt sofort, keine Hauptaktion | MOB-04, AKT-09, FAR-15, BEW-04, TEC-10, AKT-01 |

Die Einträge speichert `EntryStore` auf dem Gerät, in einer kleinen JSON-Datei `entries.json` in Application Support
(`JSONEncoder` aus Foundation, keine zusätzliche Bibliothek). Jede Änderung schreibt die ganze Datei atomar; die Datei
ist von der Gerätesicherung ausgenommen (`isExcludedFromBackup`), damit „Bleibt auf diesem Gerät.“ stimmt (BEL-10).
Beim ersten Start legt die App die Beispieleinträge an und schreibt sie sofort, so bleibt ein gelöschter
Beispieleintrag gelöscht. Die Datei trägt ihre Formatversion (`version`, jetzt 2, `EntryStore.version`): Eine ältere
Version überführt die App beim Öffnen in die jetzige und schreibt sie atomar zurück (Version 1 ist das Beispiel eines
älteren Formats, Einträge ohne Aufwand und Erinnerung; sie bekommen die Startwerte des Formulars, 1 Stunde und 18:00).
Eine neuere Version, eine Datei ohne Version und eine, die die App nicht lesen kann, öffnet sie nicht und ändert sie
nicht, kein Byte; statt ihrer Orte zeigt sie dann einen ruhigen Hinweis (`StartErrorScreen`: die Einträge bleiben
unverändert auf diesem Gerät, und was hilft: die App aktualisieren oder neu starten), nie die Beispiele an ihrer
Stelle. Für jedes Format, das ein Produkt hinter sich lässt, kommt in `Entries.swift` eine Struktur und ein Schritt
dazu; ein altes Format ändert es nie. Ein Beispieleintrag merkt sich nur, welcher er ist; Titel und Notiz holt die App erst beim Zeigen aus
`Localizable.xcstrings`, darum wechseln sie mit der Sprache. Ändert jemand Titel oder Notiz eines Beispieleintrags,
gehört er ab dann dem Menschen: Die Texte bleiben, wie sie dastehen, die Marke geht. Für viele Einträge oder Abfragen
nimmt ein Produkt SwiftData.

Dazu: „Hell oder Dunkel“, „Farbton“ und „Bewegung immer reduzieren“ speichert das Paket selbst (`@AppStorage` mit den
Schlüsseln `sb-theme`, `sb-tone`, `sb-motion`), `SebaroAppRoot` wendet sie an. Die Sprache speichert die App unter
`app-language` und schlägt jedes Wort im Bündel der gewählten Sprache nach (`Words.swift`), so wechselt sie sofort,
ohne Neustart; „Wie das System“ nimmt die erste Sprache des Geräts, die die App hat, sonst Deutsch. In den
iOS-Einstellungen unter „Musterapp › Sprache“ wählt man sie zusätzlich wie bei jeder App. Die App fragt keine Rechte
an und spricht mit keinem Server.

Was die Vorlage bewusst **nicht** zeigt: den Start mit der Kachel (STR-01) und die Kachel in der Kopfleiste (ZEI-06),
beides nur mit Produkt-ID (siehe „Lücken der Vorlage“), Über-Seite und Fakten (BEL-03, ZEI-13), Mitteilungen (MOB-09).

## Das Paket in `SebaroDesign/`

`SebaroDesign/` ist eine unveränderte Kopie des iOS-Exports, **ein Schnappschuss**: Kein Abgleich des Guides fasst sie
an, nur `tools/sebaro-sync.sh`. Sie ist der Swift-Quelltext der Teile, die erzeugten Tokens, die sieben
Schnittdateien von sebaro Sans und sebaro Mono, das Icon-Sprite und die Zeichen der Dachmarke; `sebaro-export.json`
nennt jede Datei mit sha256 und den Werkstatt-Commit. Nie eine Datei darin ändern; Xcode und SwiftPM schreiben
`.swiftpm/` und `.build/` hinein, die git ignoriert.

Der Export enthält kein Produkt (`--product` fehlt) und nennt keines der nicht veröffentlichten Produkte: Die Werkstatt
lässt sie mit der privaten Liste weg und hält in `sebaro-export.json` nur ihre Zahl fest.

| Befehl | Was er tut | Braucht |
|---|---|---|
| `python3 tools/sebaro-verify.py` | prüft die Kopie gegen ihre eigene Liste: jede Datei mit genau ihrem sha256, keine fremde Datei (wie `verify-export.mjs --strict` der Web-Vorlagen; der iOS-Export trägt dieses Skript nicht) | nur Python 3 |
| `tools/sebaro-sync.sh <sebaroDesign> <Ausschlussliste>` | holt den Export neu (`export_system.py sebaro --target ios`), prüft ihn mit `export_system.py --verify` (Quellen, Gates, jede Datei) und dann mit `sebaro-verify.py`; das Gegenstück zu `npm run sebaro:sync` | einen Checkout der Werkstatt sebaroDesign (privat) und die private Ausschlussliste |

Die Ausschlussliste ist die git-ignorierte `tools/sync.local.json` eines Guide-Checkouts (oder eine Datei mit einer
ID je Zeile, oder IDs mit Kommas). Sie kommt nie in diesen Ordner:

```sh
tools/sebaro-sync.sh <sebaroDesign-Checkout> <Guide-Checkout>/tools/sync.local.json
```

Ohne die Werkstatt bleibt die Kopie, wie sie ist; `sebaro-verify.py` sieht nur, ob sie verändert wurde, nicht, ob
die Werkstatt weiter ist. Nach dem Abgleich: bauen, testen, die Bildschirmfotos ansehen, dann den Ordner committen.

## Das Xcode-Projekt

`Musterapp.xcodeproj` liegt im Repository und ist von Hand geschrieben: Die Ordner `Musterapp/` und
`MusterappTests/` sind **synchronisierte Ordner** (Projektformat 77, Xcode 16), jede Datei darin gehört ohne Eintrag
im Projekt zu ihrem Ziel. Die `project.pbxproj` bleibt darum klein (zwei Ziele, das lokale Paket, die Einstellungen)
und ändert sich nur, wenn sich eine Einstellung ändert; im Review liest man sie wie eine Konfigurationsdatei. XcodeGen
mit einer `project.yml` war auf der Bau-Maschine nicht installiert und bräuchte in jedem Checkout und in CI ein
zusätzliches Werkzeug; mit synchronisierten Ordnern gibt es nichts zu erzeugen, was aus dem Takt geraten kann. Das
geteilte Schema `Musterapp` (in `xcshareddata`) baut die App und führt die Tests aus.

`DEVELOPMENT_TEAM` ist leer, `CODE_SIGN_IDENTITY` auch: Für den Simulator braucht es keine Signatur. Für ein Gerät
trägst du dein Team in Xcode ein, nie in dieser Vorlage. `Config/Info.plist` nennt `de` als Entwicklungsregion und
`de`, `en` als Sprachen (D111, DSK-08 für Bündel, TEC-10).

Das App-Icon (drei Listenlinien in der Textfarbe auf dem hellen Grund) ist ein **neutraler Platzhalter**, kein
App-Zeichen. Der iOS-Export hat noch keine App-Icon-Ausgabe (die Markenwerkzeuge der Werkstatt erzeugen kein
randloses iOS-Quadrat); ein Produkt bekommt sein Icon aus der Werkstatt (ZEI-11), ein Platzhalter bleibt nie in einer
veröffentlichten App.

## Starten

Voraussetzungen: macOS mit Xcode 16 oder neuer und einem iOS-Simulator ab iOS 17. Kopier den Ordner
`templates/ios-swiftui/` in dein neues Repository, dann:

```sh
open Musterapp.xcodeproj                 # in Xcode: Ziel „Musterapp“, ein iPhone-Simulator, ⌘R
xcodebuild build -project Musterapp.xcodeproj -scheme Musterapp \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
tools/run-tests.sh [Simulator-ID]        # alle Tests, Bilder nach build/test/shots/
tools/lint-sebaro-ios.sh                 # sebaros Textprüfungen für SwiftUI
python3 tools/sebaro-verify.py           # die Kopie des Exports unverändert?
swift build --package-path SebaroDesign  # das Paket allein (macOS-Host)
```

Für ein eigenes Produkt: `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj` (zweimal, und das Testziel), den Namen
„Musterapp“ in `Config/Info.plist` und das Icon ersetzen, den Export mit deiner Produkt-ID holen (siehe unten).

## Prüfen: Tests und Bildschirmfotos

`tools/run-tests.sh` baut die App und führt alle Tests in einem iOS-Simulator aus (ohne ID das erste iPhone der
neuesten iOS-Version). xcodebuild beendet sich mit Xcode 27 manchmal nicht, nachdem die Tests fertig sind (Werkstatt
TOOLS §2.20): Das Skript liest das Protokoll mit. Erst wenn es das vollständige Ende des Laufs zeigt (die letzte
Zeile „Test Suite 'All tests' passed/failed“ mit ihrem „Executed N tests“), bekommt xcodebuild 120 s
(`SB_TEST_GRACE`) und wird dann angehalten; nur dieser Fall gilt als Lauf. Hängt xcodebuild vor diesem Ende
(`SB_TEST_TIMEOUT`, 3600 s), schlägt das Skript fehl, gleich was das Protokoll bis dahin sagt. Das Urteil spricht
`tools/test-result.py`: Exit 0 nur, wenn das Protokoll den vollständigen Lauf mit „passed“ und 0 Fehlern zeigt,
keinen Absturz, Neustart oder unerwarteten Abgang der Test-App (xcodebuild startet sie nach einem Absturz neu, und
seine letzte Summe lässt den abgestürzten Test dann still weg) und keinen Fehler der Umgebung (Test-Runner startet
nicht, Verbindung verloren, Simulator bootet nicht); wenn das Ergebnisbündel „Passed“ sagt, eine Endzeit hat, so
viele Tests zählt wie das Protokoll und keiner fehlschlug, übersprungen oder als erwarteter Fehler zählt; und wenn
xcodebuild mit 0 endete. Nur wenn das Skript xcodebuild nach dem vollständigen Lauf angehalten hat, darf das Bündel
fehlen; dann entscheidet das Protokoll allein.

Den Richter prüfen Fälle in `tools/test-result-fixtures/` (`cases.txt`: je ein Protokoll und, wo der Lauf eines
schrieb, die Zusammenfassung des Bündels; jeder Fall nennt seinen Exit und die Zeile, die er ausgeben muss): ein
bestandener Lauf, das bekannte Hängen nach dem Lauf, ein Bündel „Failed“ ohne Fehler, eines ohne Endzeit, ein
abgebrochenes Protokoll, ein unerwarteter Abgang mit Neustart, ein Test-Runner, der nie startet, ein übersprungener
Test, abweichende Zahlen, ein Exit ungleich 0, ein fehlgeschlagener Test. Dazu vier Fälle für `run-tests.sh` selbst
mit einem xcodebuild-Ersatz, der hängt (`SB_XCODEBUILD`): Hängen nach dem vollständigen Lauf besteht, Hängen davor
schlägt als Zeitüberschreitung fehl, ebenso Hängen nach einem fehlgeschlagenen Lauf und ein Exit ungleich 0.
`tools/test-result-fixtures/check.sh` läuft vor jedem `run-tests.sh` (nur die Fälle des Richters) und in CI (alle).

- `ScreenshotTests`: jeder Bildschirm und jeder Dialog (16 Fälle: Liste, leer, ohne Treffer, mit Kurzmeldung, Detail,
  erledigtes Detail, die drei Dialoge, Formular neu, „Titel fehlt.“, Beispieleintrag bearbeiten, das Sheet der
  Uhrzeit, Daten, Einstellungen, der Hinweis beim Start, wenn die Datei nicht aufgeht), so zusammengesetzt wie in der App (`AppView` mit Startzustand), hell und dunkel,
  bei der Standardgröße und bei AX5 (`accessibilityExtraExtraExtraLarge`), in einem Fenster von 393 × 852 pt (iPhone
  16/17) und 320 × 568 pt (iPhone SE der ersten Generation, die schmalste Breite von spec/12); dazu die Liste im warmen
  Farbton und die Liste und die Daten auf Englisch. Ein Dialog oder Sheet wird geöffnet, wie VoiceOver es täte (die
  Taste aktivieren), und jeder Fall sucht zuerst ein Wort, das zeigt, dass sein Bildschirm da ist. Lange Bildschirme
  schreiben jede weitere Seite beim Durchscrollen als eigenes Bild, höchstens 40 (der Daten-Bildschirm bei AX5 auf
  320 pt ist länger; seine letzten Seiten stehen in keinem Bild, die Textprüfung misst ihn trotzdem ganz).
- Die **Textprüfung** (`TextCheck.swift`) läuft in jedem Fall über den Bedienungshilfen-Baum, den SwiftUI aus seinem
  Layout baut (ZUG-09, MOB-08), im obersten offenen Sheet oder Dialog, sonst im Bildschirm (was VoiceOver erreicht;
  der Bildschirm darunter ist verdeckt und unter iOS 17 und 18 verkleinert): Ein Text, der in der kleinsten Schriftrolle von sebaro bei der Größe des Falls mehr
  Höhe bräuchte, als er hat, ist abgeschnitten; ein Text, der seitlich aus dem Fenster ragt, ohne in einem seitlich
  scrollenden Bereich zu stehen, oder unten, ohne in einem scrollenden Bereich zu stehen, ist unerreichbar. Ein Fall
  ohne gemessenen Text schlägt fehl. Bekannte Ausnahmen stehen mit Grund und genauer Trefferzahl je Fall im Test; eine
  veraltete Ausnahme schlägt fehl.
- `TextCheckTests`: prüft die Textprüfung selbst mit Fällen, die fehlschlagen **müssen**: ein Satz in einem zu
  niedrigen Rahmen, ein Satz mit einer Zeile Grenze, ein Satz, der erst bei AX5 nicht mehr passt, ein Text rechts
  außerhalb des Fensters, ein Text unter dem Fenster ohne Scrollen, ein leerer Fall, eine Ausnahme mit falscher Zahl;
  und dreißig Zeilen in einem scrollenden Bereich, die bestehen müssen.
- `BehaviourTests`: Einträge überstehen einen zweiten Speicher auf derselben Datei (Anlegen, Ändern, Abschließen,
  Ausblenden, Löschen; die Datei ist von der Sicherung ausgenommen), eine kaputte Datei, eine ohne Version und eine
  der Version 0 werden nie überschrieben; Version 1 wird überführt und als Version 2 zurückgeschrieben; eine Datei
  der Version 3 wird abgelehnt und bleibt Byte für Byte und mit ihrem Änderungsdatum, wie sie war; der ruhige
  Hinweis sagt, dass die Einträge bleiben; U+00A0 zwischen jeder Zahl und ihrer Einheit in `Localizable.xcstrings`
  (aus dem Quellordner gelesen, jede Sprache und jede Mehrzahlform, kein U+202F oder U+2009) und in der Ausgabe von
  `Formats.swift` und den Einheitenwörtern („60 %“ auch englisch, Tag und Monat verbunden: „10. Okt.“, „10 Oct“); die
  Beispieleinträge wechseln Deutsch → Englisch → Deutsch, ein eigener Titel bleibt; der Sprachwechsel in der laufenden
  App (Liste, „Sample data“, Hauptaktion); „Wie das System“ fällt auf Deutsch zurück, `Info.plist` nennt `de` und
  `de`, `en`; jedes Wort in beiden Sprachen, Mehrzahl und Tausender; „Titel fehlt.“ hält das Formular offen; „Abbrechen“
  mit Änderungen fragt mit „Abbrechen“ · „Verwerfen“ · „Sichern“, „Verwerfen“ schließt ohne zu sichern, „Sichern“
  sichert, ohne Änderungen schließt „Abbrechen“ sofort; „Ausblenden“ bietet „Rückgängig“; Abschließen und Löschen
  fragen zuerst, danach fehlt die Hauptaktion oder die Liste steht wieder da; die Suche ohne Treffer sagt es.

Schau die Bilder in `build/test/shots/` an, bevor du einen Bildschirm fertig nennst, in beiden Modi und bei AX5
([`screen-checklist.md`](../screen-checklist.md)), und schreib, was lief, in die `CHECKS.md` deines Produkts (TEC-06).

**CI:** Der Job `ios-swiftui` in `.github/workflows/templates.yml` läuft auf einem macOS-Runner von GitHub
(`macos-latest`): `sebaro-verify.py`, `lint-sebaro-ios.sh`, die Fälle des Richters und des Skripts
(`tools/test-result-fixtures/check.sh`), `swift build` des Pakets, der Bau für den Simulator und `run-tests.sh`; die Bilder und das Protokoll lädt er als Artefakt hoch.

## Was ein Agent einhalten muss

Kopier [`../AGENTS-snippet.md`](../AGENTS-snippet.md) in die `AGENTS.md` deines Repositorys. Für diese Vorlage
zusätzlich:

1. sebaro nur aus `SebaroDesign/`; nie eine Datei darin ändern oder einen Teil nachbauen. Fehlt ein Teil, frag nach
   (Regel-ID nennen, [`design-exception.md`](../design-exception.md)), statt ihn selbst zu zeichnen.
2. Jeder Bildschirm: `SbScreen` unter `SebaroAppRoot`, höchstens eine Hauptaktion, nur über `SbPrimaryActionModel`;
   keine `TabView`, kein `.alert`, keine `.swipeActions`, keine SF Symbols, keine Systemschrift, keine rohe Farbe,
   kein Schatten, keine Kapsel (MOB-01, MOB-05, MOB-06, ICO-01, SCH-01, FAR-01, EBE-01, FOR-01).
3. Jedes Wort in `Localizable.xcstrings`, deutsch und englisch, nachgeschlagen über `Words` (`words("list.title")`);
   die Wörter der Teile kommen aus `SbMessages`. Zahlen, Beträge und Daten über die Locale (`Formats.swift`,
   `words.count`), U+00A0 zwischen Zahl und Einheit (TEC-10, TXT-04).
4. Dynamic Type ohne Obergrenze: nie `.dynamicTypeSize(...)` auf Inhalt, Ziele mindestens 48 pt (die Teile halten
   das), Icons in ihrer Punktgröße (MOB-08, ZUG-09, ICO-04).
5. Vor „fertig“: `tools/run-tests.sh`, `tools/lint-sebaro-ios.sh`, `python3 tools/sebaro-verify.py`, die
   Bildschirmfotos ansehen.

`tools/lint-sebaro-ios.sh` sucht im Swift-Code der App nach dem, was der Compiler nicht kennt: die Regeln I1–I8 aus
sebaroDesign spec/12 §14 (`TabView`, `.alert`/`.confirmationDialog`, `.swipeActions`, `Image(systemName:)`, rohe und
benannte Systemfarben, `.shadow`, die Lindgrün-Rollen, eine Obergrenze für Dynamic Type, Systemschriften) und S9–S13
dieser Vorlage (Kapseln, Standard-Knopfstile, Materialien und getönte Flächen, Zahlen in `.padding`, `.frame` und
`spacing:`, ein Bildschirm ohne `SbScreen`). Jede Fundstelle steht mit ihrer Regel da, Exit 1; die Liste mit den
Regel-IDs steht im Kopf des Skripts.

## Lücken der Vorlage

Was die Vorlage nicht kann oder anders macht als die Spezifikation, damit es nie als Muster kopiert wird:

- **Kopfleiste ohne Kachel.** spec/12 §3 gibt Bildschirmen der obersten Ebene `sbTopLevelNavigation(title:product:)`
  mit dem großen Titel und der 32-pt-Kachel. Ohne Produkt-ID hat der Export keine Kachel (auch die der Dachmarke
  nicht: `SbSignTile` hält dann an), und das Paket hat keinen großen Titel ohne Kachel. Die drei Bildschirme der
  obersten Ebene tragen darum den eingebetteten Titel der Unterseiten (`sbNavigationTitle`). Ein Produkt holt den
  Export mit `--product <id>` (Kachel, Startbild `Launch.xcassets`, `UILaunchScreen.plist`), stellt auf
  `sbTopLevelNavigation(title:product:)` und `SbStart` um (STR-01, ZEI-06) und mischt die Startdateien in Ziel und
  `Info.plist` (spec/12 §10). Bitte an die Werkstatt: ein großer Titel ohne Kachel für Vorlagen.
- **Kein Druckzustand der Listenzeile.** `SbListRow` hat keine eigene Tippfläche, und der Zeilenstil des Pakets
  (`SbRowButtonStyle`) ist nicht öffentlich. Die Zeile steht darum in einem `NavigationLink` mit `.buttonStyle(.plain)`:
  Beim Drücken blendet sie ab, statt die graue Druckfläche zu zeigen. Bitte an die Werkstatt: der Zeilenstil oder ein
  `onTap` an `SbListRow`.
- **Abgeschnittener Titel in der Systemleiste.** Bei AX5 kürzt die Navigationsleiste von iOS einen langen Titel
  einer Unterseite mit „…“ („Fahrrad zur Inspe…“); das Paket nimmt die Leiste des Systems (MOB-05), die App kommt an
  diesen Text nicht heran. Die Leiste behält ihre Schriftgröße bei jeder Textgröße; die Textprüfung nimmt ihre Titel
  darum nur bei AX5 aus (höchstens drei je Fenster), bei der Standardgröße schlägt ein gekürzter Titel weiter fehl.
  VoiceOver liest den Titel ganz.
- **Ausgelassene Beschriftungen im Balkendiagramm.** Bei AX5 lässt `SbBarChart` Wochentage weg, die sich berühren
  würden (D99 (2)), behält sie aber im Bedienungshilfen-Baum bei x = −100000; die Textprüfung führt sie als gezählte
  Ausnahme (393 pt: drei, 320 pt: vier). Ob VoiceOver sie anspricht, ist nicht geprüft.

- **Kurzmeldung bei AX5 auf 320 pt.** Mit „Rückgängig“ ist die Kurzmeldung (`sbToastHost`) dort höher als der
  Platz über der Aktionszone: „Rückgängig“ steht teils unter der Hauptaktion (in den Bildern
  `list-toast-*-ax5-320.png` gesehen). Die Textprüfung sieht das nicht (Tasten misst sie nicht, und verdeckt ist nicht
  abgeschnitten). Im Bedienungshilfen-Baum ist die Taste ein eigenes Element; mit VoiceOver nicht geprüft. Bitte an die Werkstatt.
- **Weitere Bilder bei AX5 auf 320 pt**, wie das Paket sie zeichnet, gesehen und nicht geändert: Die Schritte trennen
  alle drei Wörter („Na-me“, „Da-ten“, „Fer-tig“), statt nur das aktuelle zu zeigen (vgl. STA-06, D100); im
  Abweichungsdiagramm bricht „Mobilität“ ohne Strich und „−15 %“ vor dem Prozentzeichen; Titel von Dialogen werden
  getrennt („abschlie-ßen?“), wie D99 es für ein Wort erlaubt, das allein nicht in seine Zeile passt.

- **Formular bei AX5 auf 320 pt.** Die Hauptaktion mit dem Satz „Bleibt auf diesem Gerät.“ wächst mit der Schrift
  und steht fest unten im Sheet; über ihr bleibt etwa eine Zeile für die Felder, der Rest scrollt (in den Bildern
  `form-*-ax5-320.png` gesehen, unter iOS 18.5 und 27.0). So baut das Paket das Formular-Sheet (MOB-07); Bitte an die
  Werkstatt, ob der Block bei großer Schrift mitscrollen darf.

## Bekannte Grenzen

- **Was die Textprüfung nicht sieht:** eine einzelne Zeile, die ein umgebender Teil abschneidet (SwiftUI hält einen
  Text mindestens eine Zeile hoch, sein Rahmen bleibt ganz); ein Text, dem nur wenige Buchstaben fehlen (sie misst in
  der kleinsten Rolle); Wörter in Tasten und Zeilen (VoiceOver liest sie als ein Etikett, ihre Teile haben keinen
  eigenen Rahmen); einen Text, den ein anderer Teil verdeckt; ein „…“, das ins Bild gezeichnet ist (das Etikett ist
  immer ganz); einen Wert, der in einem einzeiligen Feld seitlich weiterläuft (das ist gewollt, EIN-01). Darum die
  Bilder ansehen.
- **Simulatorgrößen.** Die Fenster haben 393 × 852 und 320 × 568 pt, gerendert im Simulator eines iPhone 17
  (iOS 27.0) und eines iPhone 16 (iOS 18.5); einen Simulator mit 320 × 568 pt gibt es für iOS 17 und neuer nicht.
  Das Fenster gehört zur Szene der Test-App (Statusleiste, Sicherheitsabstände oben), unten fehlt ihm der Abstand
  des Home-Indikators.
- **iOS-Versionen.** Alle Tests liefen auf iOS 27.0 (Simulator iPhone 17) und iOS 18.5 (Simulator iPhone 16), nicht
  auf iOS 17. Unter iOS 18 verkleinert ein Sheet den Bildschirm darunter; die Textprüfung misst darum nur das oberste
  Sheet oder den obersten Dialog.
- **Nicht geprüft:** ein echtes Gerät (Haptik, Tastatur, Dynamic Type der Systemleiste), VoiceOver selbst (nur der
  Baum, den VoiceOver liest; die Aktionen der Kontextmenüs, der Fokus auf „Abbrechen“ im Dialog, das Halten der
  Kurzmeldung), Full Keyboard Access, das Kontextmenü selbst (der Simulator lässt sich nicht per Skript lange drücken;
  geprüft ist die Funktion dahinter), die iPad-Breite des Formular-Sheets, Rechts-nach-links, ein Release-Build, der
  CI-Lauf auf dem GitHub-Runner (die Xcode-Version dort ist eine andere als hier).
