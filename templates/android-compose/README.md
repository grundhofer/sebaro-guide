# Musterapp: Android-Vorlage mit sebaro (Kotlin, Jetpack Compose)

Ein kleines, vollständiges Android-Projekt als Startpunkt für eine App im sebaro-Design. „Musterapp“ ist ein
erfundener Name, `de.example.musterapp` ein Platzhalter; beides ersetzt du in deinem Produkt. Erfunden sind die fünf
Beispieleinträge und alle Werte auf dem Daten-Bildschirm; beide tragen „Beispieldaten“, ein Beispieleintrag in der
Liste, im Detail und im Formular. Was du selbst anlegst, trägt die Marke nie (BEL-09).

sebaro kommt nur aus dem privaten Maven-Paket `de.sebaro_ventures.design:sebaro-compose:1.10.3` (GitHub Packages,
Repository `grundhofer/sebaroDesign`). Die App baut keine sebaro-Bauteile nach und schreibt keine Farbe selbst: Alles,
was nach sebaro aussieht, kommt aus den Compose-Wrappern des Pakets (`SebaroAppTheme`, `SbScreen`, `SbTopBar`,
`SbNavigationBar`, `SbListRow`, `SbTextField`, `SbConfirmDialog` …); eigene Teile nehmen nur Tokens aus
`SebaroTheme`.

| | |
|---|---|
| Sprache, UI | Kotlin, Jetpack Compose, ohne Navigation-Bibliothek |
| minSdk / targetSdk / compileSdk | 24 / 36 / 37 (minSdk 24 wie das Paket, targetSdk ab 35 für Edge-to-Edge, 36 weil Google Play es verlangt; compileSdk 37, weil das Paket damit gebaut ist) |
| Gradle | Wrapper 9.7.1, alle Versionen in `gradle/libs.versions.toml` (AGP 9.3.1, Kotlin-Compose-Plugin 2.4.10) |
| Compose | BOM 2026.08.00, `activity-compose` 1.13.0; das Paket läuft auch auf BOM 2024.12.01 (siehe „Bekannte Grenzen“) |
| Sprachen | Deutsch (`res/values`), Englisch (`res/values-en`); die Wörter der Wrapper kommen aus `SbMessages` |

## Was die Vorlage zeigt

Drei Ziele in der unteren Navigation (NAV-02, NAV-03: Icon und Wort, nur oberste Ebene), dazu zwei Unterseiten mit
Zurück oder Schließen (NAV-05). Jeder Bildschirm hat `SbScreen` als Wurzel unter `SebaroAppTheme` (MOB-01) und
höchstens eine Hauptaktion, unten (AKT-01, AKT-02).

| Bildschirm | Datei | Was er zeigt | Regeln |
|---|---|---|---|
| Einträge (Liste) | `ListScreen.kt` | Suche mit „Suche leeren“, Gruppen mit Zahl im Kopf („Offen 3“), erledigte Zeilen treten zurück, Schlusssatz, leerer Zustand „Noch keine Einträge“ und „Kein Eintrag mit …“, Hauptaktion „Eintrag anlegen“ unten, „Beispieldaten“ in jeder Zeile eines Beispieleintrags; im Zeilenmenü „Ausblenden“ mit Kurzmeldung „„…“ ausgeblendet“ · „Rückgängig“ | DAT-01, DAT-02, DAT-07, HAL-05, EIN-05, TXT-05, BEL-09, EBE-05, AKT-04 |
| Eintrag (Detail) | `DetailScreen.kt` | „Beispieldaten“ unter dem Titel eines Beispieleintrags, Zustand als Glyphe und Wort, Notiz, Eigenschaften flach, Hauptaktion „Eintrag bearbeiten“ in der Aktionszone; am Ende des Inhalts „Eintrag abschließen“ (endgültig, löscht nichts: 45°-Kante ohne Papierkorb) und „Eintrag löschen“ (Kante mit Papierkorb), beide fragen zuerst; ein erledigter Eintrag hat keine Hauptaktion mehr | BEL-09, STA-01, STA-02, DAT-03, AKT-01, AKT-02, AKT-07, AKT-08, FOR-04, EBE-03, TXT-04 |
| Neuer Eintrag / Eintrag bearbeiten (Formular) | `FormScreen.kt` | „Beispieldaten“, solange Titel und Notiz eines Beispieleintrags unverändert sind, Beschriftung über dem Feld, „Notiz (optional)“ mit Zähler, Pflichtfeld ohne Zeichen; die Hauptaktion bleibt drückbar und sagt „Titel fehlt.“ am leeren Feld, der Fokus geht dorthin; „Priorität“ als Segmente, bei großer Schrift als Auswahlfeld; „Bleibt auf diesem Gerät.“ unter der Hauptaktion; Schließen mit Änderungen fragt „Abbrechen“ · „Verwerfen“ · „Sichern“ | BEL-09, EIN-01, EIN-02, STA-03, EIN-04, ZUG-09, BEL-10, AKT-11, NAV-05 |
| Daten | `DataScreen.kt` | die Datenarten von `docs/daten.html` mit den Wrappern: ganze Zahl, Bruch, Dezimalzahl, große Zahl, Prozent, Geld, Einheit, „etwa“, Rang, Vorzeichen; Tag, Datum, kurzes Datum, Uhrzeit, Zeitfenster, Zeitspanne, Dauer, Restzeit; die festen Zustandswörter, „Konflikt“, „2 offen“; Fortschrittsbalken, Ring, Schritte; Tags, Kategorien, Markierung; Kennung und Version in sebaro Mono, Dateiname, Codeblock; sortierbare Tabelle mit Summe im Fuß; Kennzahlen mit Sparkline, Balken mit Ziel, Linie über die Zeit mit Lücke, Anteile, Zielring; Bewertung | TXT-04, TXT-12, TXT-13, FAR-14, STA-02, STA-06, STA-09, STA-04, FAR-12, SCH-01, TXT-08, TXT-15, DAT-14, DAT-04, DAT-10, DAT-12, DAT-09, BEL-09 |
| Einstellungen | `SettingsScreen.kt` | „Hell oder Dunkel“ (Wie das System, Hell, Dunkel), „Farbton“ (Kühl, Warm), „Bewegung immer reduzieren“, „Sprache“ (Wie das System, Deutsch, English); alles gilt sofort, keine Hauptaktion | MOB-04, AKT-09, FAR-15, BEW-04, TEC-10, AKT-01 |

Die Einträge speichert `EntryStore` auf dem Gerät, in einer kleinen JSON-Datei `entries.json` in `filesDir`
(`org.json` aus Android, keine zusätzliche Bibliothek; jede Änderung schreibt die Datei atomar im Hintergrund). Sie
bleiben über einen Neustart der App erhalten. Beim ersten Start legt die App die Beispieleinträge an und schreibt sie
sofort, so bleibt ein gelöschter Beispieleintrag gelöscht. Ein Beispieleintrag merkt sich nur, welcher er ist; Titel
und Notiz holt die App erst beim Zeigen aus `strings.xml`, darum wechseln sie mit der Sprache. Ändert jemand Titel oder
Notiz eines Beispieleintrags, gehört er ab dann dem Menschen: Die Texte bleiben, wie sie dastehen, die Marke geht. Für
viele Einträge oder Abfragen nimmt ein Produkt Room oder DataStore.

Dazu: die drei Einstellungen speichert `SettingsStore` und gibt sie an `SebaroAppTheme(mode, reduceMotion, tone)`
(MOB-01); die Sprache setzt ab Android 13 das System für die App (`LocaleManager`, Liste in
`res/xml/locales_config.xml`), darunter speichert die App sie selbst und `MainActivity` setzt sie beim Start. Die
Statusleiste folgt der Wahl „Hell oder Dunkel“ der App, nicht nur dem System. Das Manifest fragt kein INTERNET-Recht
an, Sicherung und Geräteumzug sind aus.

Was die Vorlage bewusst **nicht** zeigt: den Start mit der Kachel (STR-01; die Musterapp lädt nichts, und ohne
Produkt gibt es keine Kachel), das App-Zeichen in der Kopfleiste (ZEI-06, nur mit Produkt-ID), Über-Seite und
Fakten (BEL-03, ZEI-13), Mitteilungen, Widget und Kamera (MOB-09, MOB-11, MOB-12).

## Lesezugriff auf das Paket

Das Paket ist privat und erbt den Zugriff des Repositorys `grundhofer/sebaroDesign`. Du brauchst Lesezugriff darauf
und ein Token mit `read:packages`:

1. Auf GitHub ein klassisches Personal Access Token mit dem Recht `read:packages` anlegen.
2. Es Gradle geben, **nie** in diesem Ordner. Entweder in `~/.gradle/gradle.properties` (deinem Benutzerordner):

   ```properties
   gpr.user=<dein GitHub-Name>
   gpr.key=<das Token>
   ```

   oder als Umgebungsvariablen `GITHUB_ACTOR` und `GITHUB_TOKEN`. `settings.gradle.kts` liest zuerst die beiden
   Gradle-Eigenschaften, sonst die Variablen, und holt nur die Gruppe `de.sebaro_ventures.design` aus GitHub Packages.

In GitHub Actions eines anderen Repositorys reicht dessen `GITHUB_TOKEN`, wenn die Paket-Einstellungen diesem
Repository Zugriff geben („Manage Actions access“).

### Ohne Token: das Paket lokal bauen

Mit einem Checkout der Werkstatt sebaroDesign (privat) baust du dasselbe Paket selbst und legst es in dein lokales
Maven-Verzeichnis. Die Liste der nicht veröffentlichten Produkte kommt aus der git-ignorierten
`tools/sync.local.json` eines Guide-Checkouts; ohne sie verweigert das Werkzeug das Paket.

```sh
cd <sebaroDesign-Checkout>
SEBARO_EXCLUDE_PRODUCTS=$(python3 -c "import json; print(','.join(json.load(open('<Guide-Checkout>/tools/sync.local.json'))['excludeProducts']))") \
  python3 tools/package_export.py maven --out <Arbeitsordner>/maven --tag v1.10.3
gradle -p <Arbeitsordner>/maven publishToMavenLocal     # Gradle 9.x, JDK 17+, Android SDK 37
```

Dann baut die Vorlage mit `-PsebaroLocal=true` aus `mavenLocal()` statt aus GitHub Packages, ohne Token:

```sh
./gradlew -PsebaroLocal=true assembleDebug
```

## Starten

Voraussetzungen: JDK 17 oder neuer (getestet mit 21), Android SDK mit Plattform 37 (`ANDROID_HOME` oder
`local.properties` mit `sdk.dir`). Kopier den Ordner `templates/android-compose/` in dein neues Repository, dann:

```sh
./gradlew assembleDebug                 # mit Token; ohne Token: -PsebaroLocal=true anhängen
./gradlew installDebug                  # auf ein angeschlossenes Gerät oder einen Emulator
./gradlew lint testDebugUnitTest        # Android Lint, Verhaltens- und Bildschirmtests
./tools/lint-sebaro-android.sh          # sebaros Textprüfungen (auch in ./gradlew check, einzeln ./gradlew lintSebaro)
```

Oder öffne den Ordner in Android Studio. Für ein eigenes Produkt: `namespace` und `applicationId` in
`app/build.gradle.kts`, den Paketnamen der Kotlin-Dateien und `app_name` in beiden `strings.xml` ändern.

## Prüfen: Tests und Bildschirmfotos

`./gradlew testDebugUnitTest` läuft auf der JVM (Robolectric mit nativer Grafik, Android 16) und braucht kein Gerät:

- `BehaviourTest`: „Titel fehlt.“ und Fokus beim leeren Pflichtfeld, der Dialog mit drei Tasten beim Schließen mit
  Änderungen und keiner ohne, Suche und „Kein Eintrag mit …“, „Eintrag abschließen“ fragt erst und nimmt danach die
  Hauptaktion weg; Einträge überstehen einen neuen Prozess (ein zweiter `EntryStore` liest nur die Datei des ersten:
  Anlegen, Ändern, Abschließen, Ausblenden, Löschen); Beispieleinträge wechseln Deutsch → Englisch → Deutsch in einem
  Prozess, ein selbst geschriebener Titel bleibt; „Beispieldaten“ nur an Beispieleinträgen, in Liste, Detail und
  Formular.
- `ScreenshotTest`: jeder Bildschirm (15 Zustände, auch die drei Dialoge, die Kurzmeldung, ein überlanges Wort und
  das Bearbeiten eines Beispieleintrags) hell und dunkel, bei Schriftgröße 1,0 und 2,0 auf 360 × 800 dp, dazu der
  Daten-Bildschirm in voller Länge. Jeder Fall sucht zuerst einen Text, der zeigt, dass sein Bildschirm oder Dialog
  da ist. Dann prüft er jeden Text im nicht zusammengefassten Semantikbaum aller Fenster (ZUG-09): keine Zeile breiter als ihr
  Kasten, kein Text höher, kein „…“, und nichts davon von einem umgebenden Teil abgeschnitten. Ein Text, den nur der
  Rand eines scrollenden Bereichs schneidet, muss beim Durchscrollen jedes Bereichs (auch einer seitlich scrollenden
  Tabelle darin) einmal ganz zu sehen sein. Ein Fall ohne gemessenen Text schlägt fehl. Das überlange Wort muss bei
  2,0 umbrechen, und zwar nur in sich selbst oder an Leerzeichen.
- `TextCheckTest`: prüft die Textprüfung selbst. Ein Text, den ein kleinerer Rahmen abschneidet, schlägt fehl, auch
  in einem scrollenden Bereich nach dem Durchscrollen. Ein Text, der nie ganz in seinen Scrollbereich passt, schlägt
  fehl. „…“ schlägt fehl, ein Fall ohne Text schlägt fehl, eine Ausnahme mit falscher Trefferzahl schlägt fehl.
  Dreißig Zeilen in einem scrollenden Bereich bestehen.

Die PNGs (Roborazzi) liegen nicht im Repository:

| Befehl | Wohin |
|---|---|
| `./gradlew testDebugUnitTest` | jedes Mal neu nach `app/build/screenshots/` zum Ansehen |
| `./gradlew testDebugUnitTest -Pshots=record` | Referenzen nach `app/screenshots/` (git-ignoriert) |
| `./gradlew testDebugUnitTest -Pshots=verify` | vergleicht mit diesen Referenzen, schlägt bei Abweichung fehl |

Schau die Bilder an, bevor du einen Bildschirm fertig nennst, in beiden Modi und bei 2,0
([`screen-checklist.md`](../screen-checklist.md)).

**Kein CI in dieser Vorlage.** Ein Workflow bräuchte Lesezugriff auf das private Paket. In deinem Produkt-Repository
richtest du ihn mit dessen `GITHUB_TOKEN` ein (siehe oben).

## Was ein Agent einhalten muss

Kopier [`../AGENTS-snippet.md`](../AGENTS-snippet.md) in die `AGENTS.md` deines Repositorys. Für diese Vorlage
zusätzlich:

1. sebaro nur aus dem Paket; nie eine Datei daraus kopieren, ändern oder nachbauen. Fehlt ein Bauteil, frag nach
   (Regel-ID nennen, [`design-exception.md`](../design-exception.md)), statt es selbst zu zeichnen.
2. Jeder Bildschirm: `SbScreen` unter `SebaroAppTheme`, höchstens eine Hauptaktion, nur über
   `SbPrimaryActionModel`; keine Material-3-Buttons, keine FAB, kein `AlertDialog`, keine `Color(0x…)` (MOB-01,
   MOB-02).
3. Jedes Wort in `res/values/strings.xml` und `res/values-en/strings.xml`; Zahlen, Beträge und Daten über die
   Locale (`Formats.kt`, `sbFormatCount`, `sbMessages()`), U+00A0 zwischen Zahl und Einheit (TEC-10, TXT-04).
4. Die Compose-BOM steht in `gradle/libs.versions.toml`; das Paket 1.10.3 läuft auf 2024.12.01 und auf 2026.08.00.
5. Vor „fertig“: `lint`, `testDebugUnitTest`, `tools/lint-sebaro-android.sh`, die Bildschirmfotos ansehen.

`tools/lint-sebaro-android.sh` sucht im Kotlin-Code nach dem, was Android Lint nicht kennt: ein eigener
`SebaroTheme(…)`-Aufruf, `SebaroProduct` außerhalb der Kachel, die Lindgrün-Rollen außerhalb der Wrapper,
Material-3-Buttons, FAB, `NavigationBar` oder `AlertDialog`, getönte Flächen (`…Subtle`), Zahlenplaketten, rohe Farben,
`SbPrimaryAction(…)` statt `SbPrimaryActionModel`, ein Bildschirm ohne `SbScreen`, ein `SbNavItem` ohne Wort. Jede
Fundstelle steht mit ihrer Regel da, Exit 1; die Liste mit den Regel-IDs steht im Kopf des Skripts. Es braucht eine
POSIX-Shell (unter Windows Git Bash).

## Bekannte Grenzen

- **Compose-BOM.** Das Paket 1.10.3 läuft auf beiden Compose-BOMs, 2024.12.01 und 2026.08.00 (Werkstatt, CHECKS §37, §38).
  Diese Vorlage ist nur mit 2026.08.00 gebaut und getestet, nicht mit 2024.12.01.
- **Platzhalter-Icon.** Das Launcher-Icon (drei Listenlinien in `sebaro_text` auf `sebaro_bg`) ist kein App-Zeichen.
  Ein Produkt ersetzt es durch sein erzeugtes Icon (`export_system.py --target android --product <id>
  --launcher-only` in der Werkstatt, ZEI-11); ein Platzhalter bleibt nie in einer veröffentlichten App.
- **Überlange Wörter.** Die Notiz im Detail steht in `SbWrapText` aus dem Paket (öffentlich seit 1.10.3): Sie bricht
  an Leerzeichen um, und nur ein Wort, das allein nicht in seine Zeile passt, wird getrennt (ZUG-09, TXT-15); nichts
  wird abgeschnitten (im Test geprüft). Den Trennstrich zeichnet die Silbentrennung des Systems; Robolectric hat keine,
  in den Testbildern bricht das Wort darum ohne Strich (bei 2,0 angesehen). Auf einem Gerät ist der Strich nicht
  gesehen.
- **Drei Ausnahmen der Textprüfung**, jede mit genauer Trefferzahl je Lauf, sonst schlägt der Test fehl:
  `SbSearchField` gibt sein Feld nur als Namen für TalkBack an, ohne ihn zu zeichnen (ein 0 × 0-Knoten ohne Layout);
  `SbTextField` gibt TalkBack „Notiz, optional“ als einen Text und nimmt die gezeichneten Wörter aus dem Semantikbaum,
  sie sind also nicht gemessen (in den Bildern stehen sie ganz). `SbBarChart` zeichnet Wochentag und Zahl jeder Säule
  in einer Zeile (`softWrap = false`); für einen solchen Text bricht Compose das Layout im Semantikbaum trotzdem um und
  meldet ihn zu hoch, obwohl er in einer Zeile ganz dasteht (bei 1,0 und 2,0 angesehen). Ausgenommen ist nur „zu
  hoch“, nur für solche Texte ohne Zeilenumbruch und nur auf dem Daten-Bildschirm: bei 1,0 die sieben Zahlen, bei 2,0
  dazu die Wochentage, die nicht mehr in ihre Säule passen (hell 11, dunkel 12). Bei 2,0 lässt `SbBarChart`
  Beschriftungen, die nicht passen, gewollt weg.
- **Was die Textprüfung nicht sieht:** einen Text, den ein anderer Teil verdeckt statt abschneidet (etwa unter der
  Aktionszone; darum scrollt der Test vor dem Tippen ans Ende), Text, den ein Wrapper aus dem Semantikbaum nimmt, und
  einen Wert, der in einem einzeiligen Feld seitlich weiterläuft (das ist gewollt, EIN-01).
- **Ob 1.10.3 schon in GitHub Packages liegt,** ist hier nicht geprüft (ohne Token antwortet GitHub Packages mit
  einem Fehler). Bis es dort liegt, nimm den lokalen Weg oben.
- **Nicht geprüft:** echtes Gerät oder Emulator, TalkBack selbst (nur der Semantikbaum in den Tests), Android unter
  13 mit der eigenen Sprachwahl, der Sprachwechsel über die echte Activity (der Test tauscht die Locale der
  Zusammensetzung in einem Prozess), ein echter Prozessabbruch (der Test öffnet die Datei mit einem zweiten Speicher),
  die Paketauflösung aus GitHub Packages mit einem echten Token, Release-Build.
