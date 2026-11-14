# Vorlage: Web-App mit React, Vite und TypeScript

Eine kleine, lauffähige Web-App ohne Fenster („Musterapp“, ein erfundener Name), gebaut nach ihrem Bauplan
[`BLUEPRINT.md`](BLUEPRINT.md): React 19, TypeScript 6 (strict), Vite 8, pnpm 11, zustand, react-router, i18next. Die
Oberfläche besteht aus dem Markup der Bauteile der sebaro-Kopie in `src/sebaro/`; ihr Verhalten ist in React
geschrieben (`src/components/parts/`). Alle Einträge und Werte sind Beispieldaten.

Die Ansichten stehen im App-Rahmen der Kopie (Kernregeln 18 und 28). Auf dem Handy: eine Ansicht, darunter die
Navigation mit den drei Orten „Einträge“, „Datenarten“ und „Einstellungen“; eine Unteransicht steht allein und hat
„Zurück“. Ab 840&nbsp;px Breite: dieselbe Navigation als Leiste am Rand, und die Liste bleibt am Anfang stehen, während
ihr Eintrag oder das Formular am Ende daneben steht. „Hell oder Dunkel“, „Farbton: Kühl · Warm“ und die Sprache stehen
im Menü „Mehr“ in der oberen Leiste jedes Orts.

| Ansicht | Adresse | Was sie zeigt |
|---|---|---|
| Start | | beim ersten Aufruf je Browser-Tab der ganze Bildschirm in der Produktfarbe mit dem weißen Zeichen, dann die App |
| Einträge | `/` | Suche, Filterchips, Liste mit Erledigtem, leerer Zustand, Stand-Satz und „Neuer Eintrag“ unten |
| Eintrag | `/eintrag/2` | Eigenschaften, Zustand als Zeichen und Wort, „Bearbeiten“ als die eine umrandete Aktion in der Aktionszone, „Als erledigt markieren“ als Textaktion mit Kurzmeldung und „Rückgängig“; am Ende des Inhalts „Eintrag abschließen“ als Textaktion und „Eintrag löschen“ als die eine Gefahrtaste dort, beide mit Dialog, dessen Bestätigung die 45°-Kante trägt |
| Neuer Eintrag, Bearbeiten | `/neu`, `/bearbeiten/2` | Formular mit „(optional)“, Fehlern je Feld, Teilschritten mit „Rückgängig“, Dialog „Abbrechen“ · „Verwerfen“ · „Sichern“ |
| Datenarten | `/daten` | jede Datenart von `docs/daten.html`: Text, Zahlen, Geld, Zeit, Kalender, Zustände, Tabellen mit Sortierung und Summe, Baum, Mehrfachauswahl, alle Diagramme, Orte, Belege |
| Einstellungen | `/einstellungen` | „Bewegung immer reduzieren“, „Über“ mit Kachel, Name, Version und dem Absender „von sebaro“, der Weg zu den Pflichtseiten und zum Quelltext |
| Impressum, Datenschutz, Barrierefreiheit | `/impressum` … | Platzhalter für die Pflichtseiten, Unteransichten von „Einstellungen“ |
| jede andere Adresse | | „Diese Ansicht gibt es nicht“ |
| eine Ansicht, die scheitert | | „Fehler“: was los ist und was du tun kannst; der Rahmen bleibt stehen |

## Starten

Node 22.22 oder neuer, pnpm 11.

```sh
pnpm install
pnpm exec playwright install chromium   # einmal, für die End-to-End-Tests
pnpm dev                 # http://localhost:5173
pnpm lint && pnpm check  # ESLint, tsc --noEmit
pnpm format:check        # Prettier (pnpm format schreibt)
pnpm test                # Vitest: Logik und Bauteile, die Tests liegen neben den Dateien
pnpm build               # vite build nach dist/, danach die Größenbudgets (scripts/budget.ts): darüber scheitert der Build
pnpm test:e2e            # Playwright (Chromium) gegen dist/, serviert von vite preview
pnpm sebaro:verify       # die Kopie ist unverändert (verify-export.mjs --strict)
pnpm sebaro:product      # sebaro-product/ ist, was sebaro.product.json ergibt (braucht Python 3.10)
pnpm sebaro:lint         # lint-web.sh der Kopie über src/app.css und die gebaute Seite
```

`.github/workflows/ci.yml` läuft bei jedem Push und Pull Request und ruft genau diese Befehle, davor
`pnpm audit --prod --audit-level=high`. `.github/dependabot.yml` meldet einmal in der Woche neue Versionen.

## Aufbau

```
index.html          lädt theme-init.js und sb-start.js zuerst, dann src/app.css; der Start und das Icon-Sprite
                    stehen inline oben im body
vite.config.ts      Vite, Vitest und das kleine Plugin für die Kopie
src/main.tsx        Einstieg: die Routen (mit ihrem Ort im Rahmen), ihre Fehlergrenze, der Start
src/pages/          eine Datei je Route
src/components/     Teile der App: Shell (der App-Rahmen mit den Orten), View (eine Ansicht als Spalte des Rahmens:
                    obere Leiste, Kurzmeldung), More (das Menü „Mehr“), ErrorView …
  parts/            die React-Hüllen der sebaro-Bauteile
  data/             die Abschnitte von „Datenarten“
src/store/          zustand: Einträge, Darstellung, Kurzmeldung, Suche und Filter der Liste
src/lib/            Regeln als einfache Funktionen: Einträge und ihre Prüfung, Formate, Kalender, Sortierung
src/i18n.ts         die Sprachen; die Wörter stehen in src/i18n/de.json und en.json
src/app.css         importiert die Stylesheets der Kopie in ihrer Reihenfolge, dann die eigenen Regeln (app-*)
src/sebaro/         die sebaro-Kopie, nie ändern
sebaro-product/     Zeichen, Favicons, Manifest: schreibt das Kit der Kopie aus sebaro.product.json
scripts/budget.ts   die Größenbudgets
tests/              End-to-End-Tests (Playwright)
```

`src/components/parts/` kennt nur React, react-i18next mit `src/i18n.ts` (die Sprache und allein die Wörter unter
`common` in den Sprachdateien) und `src/lib/`: keinen Router, keinen Store. So kann eine andere App den Ordner als
Ganzes übernehmen. Was eine Regel des Produkts ist (was ein Eintrag sein darf, was ein Wert bedeutet), steht in
`src/lib/`, nie in einem Bauteil oder Store.

## Die sebaro-Kopie

`src/sebaro/` ist die Kopie des Profils `webapp` aus dem öffentlichen Release, mit den Packs `window`, `menu`,
`charts`, `table`, `calendar`, `diff`, `notes` und `facts` (ihre Bauteile zeigt „Datenarten“; `menu` verlangt
`window`). Die README der Kopie sagt, wie sie eingebunden wird; nie darin ändern, auch nicht mit ESLint oder Prettier.

```sh
node src/sebaro/checks/update-copy.mjs --check                 # gibt es ein neueres Release? (Exit 1: ja)
node src/sebaro/checks/update-copy.mjs                         # das neueste Release, gleiches Profil, gleiche Packs
node src/sebaro/checks/update-copy.mjs --packs window,menu,…   # andere Packs: die Liste ersetzt die alte
python3 src/sebaro/product/product_kit.py build sebaro.product.json --copy src/sebaro --out sebaro-product --render
```

Ein Update der Kopie ist ein eigener Commit; danach alle Befehle von „Starten“ und die Ansichten in beiden Modi ansehen.
Der letzte Befehl schreibt `sebaro-product/` neu, wenn sich `sebaro.product.json` ändert (`--render` zeichnet die PNG-
und ICO-Dateien mit Playwright). Die Erklärung dort ist ein Platzhalter: die Dachmarke. Ein echtes Produkt trägt sein
eigenes Zeichen ein.

Das Plugin in `vite.config.ts` liefert aus, was ein Bundler nicht bündelt: `theme-init.js` und `sb-start.js` unter
`/sebaro/js/` und die Icons und das Manifest aus `sebaro-product/web/` an der Wurzel. Es setzt den Start, das
Icon-Sprite und das Kopf-Schnipsel des Kits in `index.html` ein.

**Der Start** (Kernregel 29). Das Markup der Kopie (`.sb-start`) steht als erstes Element im Body, mit der ID des
Produkts aus `sebaro.product.json` und seinem Zeichen (`sebaro-product/sign/sign.svg`); die Farben gibt
`sign/product.css`, das `src/app.css` nach `tokens.css` einbindet. `sb-start.js` der Kopie zeigt ihn nur beim ersten
Aufruf je Browser-Tab (D144 (3)) und blendet ihn aus, sobald die Seite geladen ist und die App ihn nicht mehr hält:
`src/main.tsx` hält ihn mit `src/lib/start.ts`, bis die App gemalt hat. Das Ausblenden dauert 200&nbsp;ms, auch bei
reduzierter Bewegung (System oder „Bewegung immer reduzieren“, D102 (52)).

### Die klassischen Skripte der Kopie

Die Bauteile der Kopie sind CSS und Markup. Was ihre klassischen Skripte täten, steht hier in React. Geladen werden nur
die zwei, die vor dem ersten Bild laufen müssen:

| Skript | Geladen | Warum, oder wo das Verhalten jetzt steht |
|---|---|---|
| `theme-init.js` | ja | muss vor dem ersten Bild laufen: setzt gespeichertes Hell/Dunkel, Farbton, Bewegung und Sprache an `<html>` und führt die `theme-color`-Angaben nach |
| `theme-button.js` | nein | eine Web-App hat keinen Knopf im Kopf: die Wahl steht im Menü „Mehr“ (`components/More.tsx`, `lib/appearance.ts`, `store/appearance.ts`) |
| `sb-tone.js` | nein | `components/More.tsx`, `store/appearance.ts` |
| `sb-start.js` | ja | muss vor dem ersten Bild laufen: zeigt den Start nur beim ersten Aufruf je Tab und blendet ihn aus; die App hält ihn mit `lib/start.ts`, bis sie gemalt hat |
| `sb-sheet.js` | nein | die Vorlage hat kein Sheet |
| `sb-fit.js` | nein | es schreibt in Textknoten und Bauteile, die React rendert; das hält Reacts Abgleich nicht aus. Übernommen ist eine seiner Formen (siehe Lücken) |
| `sb-calendar.js` | nein | `parts/Calendar.tsx`, `lib/calendar.ts` |
| `sb-chart.js` | nein | `parts/Heatmap.tsx` |
| `sb-table.js` | nein | `parts/SortTable.tsx`, `lib/sort.ts` |
| `sb-notes.js` | nein | `parts/Notes.tsx` |
| `sb-facts.js`, `sb-menu.js` | nein | kommen mit ihren Packs. Die Aussage-Zeilen rendert `parts/ClaimRow.tsx`, das Menü `parts/Menu.tsx` |

Nicht in der Kopie, weil ihr Pack nicht gewählt ist: `sb-controls.js` (jetzt `parts/Dialog.tsx`, `Toast.tsx`,
`Chips.tsx`, `Switch.tsx`, `ClaimRow.tsx`, `CodeBlock.tsx`; die Sprache als gespeicherte Wahl in `components/More.tsx`
und `src/i18n.ts`), `sb-search.js` (`parts/SearchField.tsx`), `sb-tree.js` (`parts/Tree.tsx`), `sb-sticky.js`
(`parts/ActionZone.tsx` misst den unteren Block für den Rollabstand seiner Ansicht; einen haftenden Gruppenkopf hat die
Vorlage nicht).

Den App-Rahmen der Kopie (`sb-app-frame`, `sb-bottom-nav`, `sb-top-bar`) schreiben `parts/AppFrame.tsx`,
`components/Shell.tsx` und `components/View.tsx`. Er misst seine eigene Breite; die Höhe gibt ihm `.app-window` in
`src/app.css`, und jede Spalte rollt für sich.

## Tests

`pnpm test` (Vitest, jsdom) prüft die Logik in `src/lib/`, die Stores, die Bauteile, die Ansichten Liste und
Formular und „Über“ in den Einstellungen, deutsch und englisch; `src/i18n.test.ts` prüft, dass Deutsch und Englisch dieselben Schlüssel haben. jsdom kennt weder CSS noch
`<dialog>` noch Popover: was davon abhängt, prüfen die End-to-End-Tests.

`pnpm test:e2e` lädt jede Ansicht und jeden Zustand (leere Liste, kein Treffer, abgeschlossener und unbekannter Eintrag,
offene Dialoge, das Menü „Mehr“, Kurzmeldungen, Formularfehler, lange Werte, Beleg als Popover, Englisch, Farbton Warm)
hell und dunkel, bei 320, 390 und 1440&nbsp;px, bei 100&nbsp;% und auf 1440&nbsp;px auch bei echten 200&nbsp;% Schrift
(CDP `Page.setFontSizes` vor dem Laden). Unter 840&nbsp;px zeigt der Rahmen eine Spalte und die Navigation unten, auf
1440&nbsp;px die Leiste am Rand und für die Liste zwei Spalten. Er scheitert an seitlichem Scrollen der Seite oder
einer Spalte, abgeschnittenem Text, jedem axe-Fund (WCAG 2.2 AA), Konsolenfehlern und CSP-Verstößen
(`tests/sebaro-checks.ts`).
Jeder Fall nennt, was auf dem Bildschirm stehen muss: den HTTP-Status der Seite, den Text der einen sichtbaren
Überschrift `h1`, die Ansicht (`data-sb-view` oder ein Selektor) und genau die offenen Überlagerungen (Dialoge, Popover,
Kurzmeldungen; keine, wenn der Fall `null` sagt). Er scheitert auch an Text, den ein Bedienelement selbst abschneidet: der
gewählte Eintrag einer Auswahl, ein Platzhalter, der Wert eines schreibgeschützten Felds, oder ein Icon oder Suffix über
dem Text. Ein eingetippter Wert, der länger ist als sein einzeiliges Feld, läuft darin seitlich weiter (D110, D111 (4),
„wie in jedem Textfeld“), und ein Platzhalter, der nicht passt, darf mit dem „…“ enden, das sebaros Feld zeichnet,
solange das Feld eine eigene Beschriftung hat (D111 (3)); beides zählt als Notiz im Test, nicht als Fehler, aber ein Rahmen um das Feld darf
den Text, den es zeigt, nie abschneiden. Der Wert eines Textbereichs (`textarea`) ist kein einzeiliges Feld: Schneidet ihn der
Textbereich selbst oder ein Rahmen ab, scheitert der Test; ein Textbereich, der rollt, hält ihn. `tests/control-cuts.spec.ts`
prüft beides an zwei kleinen Seiten in `tests/fixtures/`. Nicht gemessen: Datums- und Zeitfelder (ihre Teile zeichnet
der Browser), der Platzhalter eines Textbereichs und die offene Liste einer Auswahl (zeichnet das System). Einen Schnitt, den sebaros eigenes CSS verursacht
und den die Vorlage nicht ändern darf, nennt der Fall als `controlWaivers` mit Grund; er steht bei jedem Lauf als Notiz
im Bericht und ist eine Bitte an die Werkstatt.
Heute steht dort keiner.

`tests/keyboard.spec.ts` prüft die vier festen Aufgaben nur mit der Tastatur, die Tasten im Menü „Mehr“ und dass jede
Klasse von sebaro stammt oder mit `app-` beginnt. `tests/data-safety.spec.ts` prüft, dass nichts ungefragt verloren
geht: jeder Weg aus einem Formular mit ungesicherten Änderungen fragt zuerst (Link, Zurück, Vor, Schließen und
Neuladen; die Sprache behält den Entwurf), und „Beispieldaten wiederherstellen“ fügt nur fehlende Beispiele hinzu, die
eigenen Einträge bleiben.
`tests/parts.spec.ts` prüft, was die Bauteile erst im Browser zeigen: Dialog und Popover geben den Fokus zurück, ein
Klick neben den Dialog bricht ab, Aktionen ohne Platz stehen untereinander, „Kopieren“ erreicht die Zwischenablage, und
eine Ansicht, die sich nicht laden lässt, sagt es. `tests/start.spec.ts` prüft den Start, hell und dunkel und bei
jeder Bewegungseinstellung: das erste Bild ist der ganze Bildschirm in der Kachelfarbe mit dem weißen Zeichen, dann
blendet er in 200&nbsp;ms aus, und die App steht auf ihrem eigenen Grund; ein zweiter Aufruf im selben Tab zeigt ihn
nicht, ein neuer Tab wieder. `tests/dimensions.spec.ts` liest `src/app.css`: keine Länge ohne
Token oder Begründung. Dass kein Wort im Markup steht, prüft ESLint (`eslint.config.js`). Die Bildschirmfotos liegen
danach in `test-results/screens/`.

Jeder Fall von `tests/screens.spec.ts` läuft auch durch die Prüfung einer Ansicht aus der Kopie
(`src/sebaro/checks/sb-colour-count.js`, für jedes `data-sb-view`): eine Hauptaktion, wo eine erwartet ist, und
höchstens eine im App-Rahmen; höchstens eine umrandete Aktion je Bereich; kein Knopf „Hell oder Dunkel“ in der oberen
Leiste; keine Farbe ohne Rolle, kein Text auf einer Farbfläche. `tests/views.spec.ts` zählt jede Ansicht dazu im Farbton
Warm und zeigt an drei Gegenproben, dass die Prüfung scheitert: an einer zweiten umrandeten Aktion in einem Bereich, an
einem Knopf „Hell oder Dunkel“ im Kopf, an einer zweiten Hauptaktion im Rahmen. Das Skript wird in die Seite
ausgewertet, nicht als `<script>` eingefügt: die CSP der Seite ließe ein Inline-Skript nicht zu.

Der Test nutzt außerhalb der CI einen Server, der auf Port 4173 schon läuft. Läuft dort die Vorschau eines anderen
Projekts, prüft er dieses. Starte mit `CI=1 pnpm test:e2e`: dann bricht ein belegter Port den Lauf laut ab.

## Was die Vorlage zeigt (Regeln)

Wo die Vorlage eine dieser Regeln noch nicht ganz erfüllt, steht es unter „Lücken der Vorlage“.

- App-Rahmen (Kernregeln 17, 18 und 28): Navigation unten mit drei Orten, jeder mit Icon und Wort, ab 840&nbsp;px als
  Leiste am Rand; die Liste und ihr Eintrag in zwei Spalten; Unteransichten mit „Zurück“; keine Hauptaktion in der
  oberen Leiste: NAV-01, NAV-02, NAV-03, NAV-05
- „Hell oder Dunkel“, „Farbton: Kühl · Warm“ und die Sprache ohne Neuladen im Menü „Mehr“: AKT-09, FAR-15, EBE-07,
  TEC-10; Impressum, Datenschutz, Barrierefreiheit und GitHub unter „Einstellungen“
- Bewegung in den Einstellungen: BEW-04; Laden im Kopf: WEB-01
- Start in der Produktfarbe nur beim ersten Aufruf je Tab, 200&nbsp;ms Ausblenden bei jeder Bewegungseinstellung;
  „Über“ mit Kachel, Name, Version und „von sebaro“: Kernregel 29 (D143 (5), D144 (3), D102 (52))
- eine Hauptaktion unten in der Aktionszone, zuletzt in jeder Gruppe, mit Stand-Satz und Datenweg-Zeile: AKT-01, AKT-02,
  AKT-04, AKT-11, STA-07, EBE-08, BEL-10
- drei Stufen von Aktionen (Kernregel 13): höchstens eine umrandete je Bereich, alles andere eine Textaktion; im
  Inhalt einer Ansicht höchstens eine Gefahrtaste mit Kante, für das Löschen; ein endgültiger Schritt, der nichts
  löscht, ist dort eine Textaktion und fragt im Dialog: AKT-06, AKT-07, AKT-08
- Listen, Leerzustand, Suche, Chips: DAT-01, DAT-02, DAT-07, EIN-04, EIN-05, STA-09
- Formular: EIN-01, EIN-02, STA-03, RAU-07; Dialoge: EBE-03, AKT-07, AKT-08, AKT-11, FOR-04; Kurzmeldung: EBE-05
- Zustände und Daten: STA-01, STA-02, STA-05, STA-06, DAT-03 bis DAT-17 außer DAT-13 (Board), FOR-05, TXT-04, TXT-09, TXT-11 bis TXT-17, FAR-12, FAR-14,
  BEL-02, BEL-03, BEL-09
- Zugang: ZUG-01 bis ZUG-04, ZUG-06, ZUG-08, ZUG-09; strenge CSP ohne Inline-Skripte und -Stile, nichts von fremden
  Servern: HAL-09; nur Tokens: TEC-01, TEC-03 (`data-sb-view` an jeder Ansicht, gezählt in den End-to-End-Tests)

## Was ein Agent behalten muss

Übernimm den Abschnitt aus [`../AGENTS-snippet.md`](../AGENTS-snippet.md) in die `AGENTS.md` deines Projekts. Für diese
Vorlage gilt zusätzlich:

- Jedes Wort steht in `src/i18n/de.json` und `en.json`, auch die Beispieleinträge (`samples`); ESLint verbietet Wörter
  im JSX. U+00A0 zwischen Zahl und Einheit schreibst du dort als ` `, damit es sichtbar bleibt. Was in beiden
  Sprachen gleich ist (Adressen, IDs, Dateinamen, Code), steht in `src/components/data/values.ts`. Zahlen und Daten
  laufen über `src/lib/format.ts`.
- Maße nur aus Tokens (TEC-01). Wo sebaro keins hat, sagt ein Kommentar „no sebaro token“ warum; Umbrüche in rem oder
  em, damit sie der Schriftgröße folgen. Heute ohne Token: die kleinste Breite einer Karte im Raster (`16rem`,
  `.app-card-grid`).
- Eigene Klassen beginnen mit `app-` und nutzen nur `var(--sb-*)`; nie eine eigene `sb-*`-Klasse, nie eine Farbe von Hand.
- Kein `style`, kein Inline-Skript, keine `data:`-Adresse: die CSP in `index.html` bleibt so streng. Größen und Orte
  eines Diagramms kommen aus SVG-Attributen und den Haken der Kopie (`data-sb-y`, `data-sb-span`).
- Ein Dialog, ein Popover oder eine Kurzmeldung ist genau so lange offen, wie sein Zustand in React es sagt. Was der
  Browser von selbst schließt (Escape), meldet das Bauteil sofort; sonst laufen Bild und Zustand auseinander. Das Menü
  öffnet und schließt der Browser selbst (`popovertarget`); das Bauteil führt nur `aria-expanded` nach.
- Eine neue Ansicht ist ein `<View>`: ohne `back` ein Ort der Navigation mit Kachel und „Mehr“, mit `back` eine
  Unteransicht. Ihre Route sagt in `src/main.tsx` mit `handle`, zu welchem Ort sie gehört und ob sie eine Unteransicht
  ist; daraus baut `Shell` den Rahmen. Drei bis fünf Orte, nicht mehr (`PLACES` in `components/Shell.tsx`).
- Höchstens eine umrandete Aktion (`sb-secondary-action`) je Bereich: Ansicht, `section`, Karte, Listenzeile, obere
  Leiste, die Aktionen eines Dialogs. In einer Detailansicht ist es „Bearbeiten“ in der Aktionszone, in einem Formular
  „Abbrechen“ neben der Hauptaktion; alles andere ist eine Textaktion (`sb-text-action`). „Abbrechen“ in einem Dialog
  trägt `data-sb-dialog-cancel` und zählt nicht. Die End-to-End-Tests scheitern an einer zweiten.
- Die Kachel in der oberen Leiste, über der Navigation am Rand und in „Über“ und der Start (Zeichen und Farbe) sind
  Platzhalter (die Dachmarke). Ein echtes Produkt trägt sein eigenes Zeichen in `sebaro.product.json` ein (ZEI-03,
  ZEI-08); `pnpm build` übernimmt es in den Start.
- Alle Befehle von „Starten“ müssen grün sein, bevor eine Ansicht fertig ist; die Prüfliste `../screen-checklist.md`
  gilt dazu.

## Abhängigkeiten über den Bauplan hinaus

Der Bauplan nennt React, TypeScript, Vite, zustand, react-router, i18next mit react-i18next, Vitest, Playwright mit
axe, ESLint mit typescript-eslint und Prettier. Dazu kommen, alle nur für die Entwicklung:

| Paket | Wozu |
|---|---|
| `jsdom` | der Browser-Ersatz, in dem Vitest Bauteile rendert |
| `@testing-library/react`, `@testing-library/dom` | rendern ein Bauteil im Test und finden Elemente nach Rolle und Name |
| `@eslint/js` | die empfohlenen Regeln von ESLint selbst |
| `eslint-plugin-react-hooks` | die empfohlenen Regeln für Reacts Hooks: Abhängigkeiten eines Effekts, nichts Unreines beim Rendern |
| `@types/node`, `@types/react`, `@types/react-dom` | Typen |

Nicht dabei, mit Absicht: `@vitejs/plugin-react` (sein Fast Refresh braucht ein Inline-Skript, das die CSP sperrt; Vite
übersetzt JSX auch ohne es, eine Änderung lädt die Seite neu) und `eslint-plugin-react` (das Verbot von Wörtern im
JSX leistet `no-restricted-syntax`).

## Nicht geprüft

Nur Chromium; kein Firefox, kein WebKit, kein echter Screenreader. Die Fehleransicht hat ihre eigenen Fälle in
`tests/parts.spec.ts` (eine Ansicht lässt sich nicht laden: hell und dunkel, 390 und 1440&nbsp;px, einmal 200&nbsp;%),
ohne die Prüfung der Konsole: der gescheiterte Abruf steht dort mit Absicht. `.github/workflows/ci.yml` ist
in dieser Vorlage nie gelaufen; im Guide läuft dasselbe als Job `webapp-vite`. Das Verbot von Wörtern im JSX sieht Text
zwischen Tags und die Attribute `aria-label`, `aria-description`, `alt`, `placeholder` und `title`, keine Zeichenketten,
die Code an eine Funktion übergibt; Zahlen und Zeichen allein (08:12, ±0) gelten als Werte. Die Frage beim Schließen
ist die des Browsers (`beforeunload`); ihr Text ist nicht änderbar. Das Datumsfeld zeigt das Format der Browsersprache,
nicht der Seitensprache. Audio und Video sind nicht dabei (keine Mediendateien). Die Prüfung einer Ansicht liest keine
Pseudo-Elemente (Haken, Rahmen von Chips) und keine Fokusringe, und sie zählt die Gefahrtaste nicht als umrandete
Aktion: dass die Detailansicht nur eine zeigt, prüft `tests/keyboard.spec.ts`.

## Lücken der Vorlage

Was die Vorlage zeigt, obwohl es keiner Regel folgt, oder nicht zeigt, obwohl eine Regel es verlangt. Fünf
Probeaufgaben ([`../../docs/agenten-test-2026-10.md`](../../docs/agenten-test-2026-10.md)) haben gezeigt, dass Agenten
solche Stellen übernehmen. Übernimm sie nicht, sondern bau es so:

- **Ansichtstypen fehlen.** Keine Ansicht trägt `data-sb-view-type`; die Vorlagen der 21 Typen von
  `design/views.md` kommen erst noch in die Vorlagen. Wähl für jede Ansicht ihren Typ (Kernregel 2) und setz das Attribut
  neben `data-sb-view`: die Prüfung der Kopie (`checks/sb-colour-count.js`) liest es.
- **App-Rahmen: was offen ist.** Die Liste rendert `Shell`, damit sie neben ihrem Eintrag stehen bleibt; ein Fehler in
  der Liste selbst trifft darum die Fehlergrenze der Wurzel, und die Fehleransicht steht ohne Rahmen. Auf dem Handy hat
  eine Unteransicht kein „Mehr“: Sprache, „Hell oder Dunkel“ und Farbton wählt man an einem der drei Orte. Die
  Kurzmeldung steht in der Ansicht der Adresse und zählt ihre 6&nbsp;s nach einem Wechsel der Ansicht neu. Die
  Navigation steht im Markup zuletzt, wie das Stylesheet der Kopie es verlangt: ab 840&nbsp;px ist die Leiste am Rand
  die letzte Station der Tabulatortaste, obwohl sie vorn steht.
- **Regeln für Klassen der Kopie.** `src/app.css` gibt in einer Spalte des Rahmens drei Klassen der Kopie eigene Regeln:
  `.sb-view__content` schrumpft nicht (die Spalte rollt auch unter 840&nbsp;px für sich; die Kopie regelt das erst ab
  840&nbsp;px), `.sb-container` behält den Rand der Spalte (ab 1024&nbsp;px nähme er den breiten Rand einer Seite), und
  `.sb-action-hint` der Liste verschwindet mit ihrer Hauptaktion, solange das Formular daneben die Hauptaktion trägt
  (die Kopie versteckt nur die Taste). Das sind Bitten an die Werkstatt; kopier das Muster nicht für eigene Klassen.
- **Große Schrift ohne `sb-fit.js`.** Übernommen ist eine seiner Formen: Aktionen eines Dialogs, die nicht in eine
  Zeile passen, stehen untereinander (`parts/Dialog.tsx`). Zwei Reihen eines Diagramms bekommen ihre Legende vom
  Stylesheet der Kopie. Es fehlen: der Trennstrich in einem überlangen Wort (es bricht ohne), das Icon über den Wörtern
  einer Aktion, die Auswahl anstelle eines Segment-Schalters ohne Platz, die kurze Form der Schritte, das Auslassen von
  Achsenbeschriftungen, die sich berühren. Auf 1440&nbsp;px bei 200&nbsp;% Schrift zeigt es sich in der Leiste am Rand
  und in der Spalte der Liste: die Wörter der Navigation brechen ohne Trennstrich, und „Mehr“ rückt unter den Titel.
  Auf einem Handy bei 200&nbsp;% zeigt sich mehr.
- **Kein Deploy-Workflow.** Der Host ist die Wahl des Produkts. Es ergänzt `.github/workflows/deploy.yml`: `dist/` auf
  einen statischen Host, mit einer Vorschau-Adresse je Pull Request. Der Host muss jede Adresse ohne Datei auf
  `index.html` leiten (die Routen sind echte Pfade) und schickt die Content-Security-Policy besser als Kopfzeile.
- **Befehlspalette mit ⌘K / Strg+K fehlt.** NAV-06 verlangt sie auch in einer Web-App ohne Fenster („⌘K öffnet auch
  dort die Befehlspalette“). Die Vorlage hat sie noch nicht; das Markup steht in `docs/bauteile.html` (Befehlspalette).
  NAV-09 nennt nur Apps mit Fenster; das ist eine offene Frage an den Inhaber, keine Erlaubnis, sie wegzulassen.
- **Kurzmeldung „Alle Beispiele sind schon da.“** meldet, dass nichts geschah. Eine Kurzmeldung gibt es nur für das
  umkehrbare Ergebnis einer Aktion außerhalb der Hauptaktion (EBE-05). Ein „Rückgängig“ zeigt sie nicht mehr: eine
  Aktion ohne Rückgängig steht nicht im DOM.
- **Titel als Satz:** „Diesen Eintrag gibt es nicht“ und „Diese Ansicht gibt es nicht“ in `src/i18n/de.json`.
  Bildschirmtitel sind kurze Substantive (TXT-03), etwa „Unbekannter Eintrag“; der Satz gehört in den Text darunter.
- **Barrierefreiheit** ist ein Platzhalter, der auf der Seite „(ZUG-07)“ zeigt. Ein Produkt schreibt die sechs Teile
  Beschreibung, Bedienung, Erfüllung, Einschränkungen, Rückmeldung, Behörde (ZUG-07) und nennt nie gelaufene
  Screenreader-Tests „offen“ (ZUG-08).
- **Datenweg-Zeile** fehlt unter „Sichern“ im Dialog „Änderungen sichern?“ (BEL-10). `src/app.css` setzt den Abstand von
  `.sb-action-hint` in der Aktionszone einer Spalte auf 0 und richtet die Zeile ans Ende aus, mit einer Regel für eine
  Klasse der Kopie. Unter 840&nbsp;px Rahmenbreite und in der Spalte der Liste steht sie darum bündig unter der Aktion;
  erst die breite Form der Zone gibt mit ihrem Zeilenabstand 8&nbsp;px. BEL-10 will sie 8&nbsp;px unter der Hauptaktion
  und zentriert.
- **Nicht eingebaut, obwohl die Regeln gelten:** das Vorschaubild der Startseite (WEB-09) und Markup, das ohne Skript
  den richtigen Zustand zeigt (TEC-02 gilt für `web`; die Ansichten rendert hier React). Bau WEB-09 ein.
- **Frage an den Inhaber:** ob WEB-11 („Drucke jede Website hell“, `sb-print.js`) für eine Web-App gilt, und wie
  TEC-02 („klassische Skripte, keine Module“) zu einem Vite-Build passt, der die Oberfläche als Modul ausliefert. Frag
  mit den IDs, statt es selbst zu entscheiden.
- **`CHECKS.md` fehlt.** TEC-06 verlangt sie in jedem Produkt: jede Prüfung mit Befehl, Datum und Exit-Code, jede nicht
  gelaufene mit Grund.
- **Die Bauteile in `parts/` können weniger als die Skripte der Kopie.** Der Baum kennt weder ⌘↓ noch Ordner, die sich
  beim Wählen öffnen, noch Ebenen tiefer als acht. Die Kurzmeldung zählt ihre 6&nbsp;s nach einer Pause neu. Ein Klick
  neben den Dialog bricht immer ab (er hat keine Felder, deren Text verloren ginge). Das Menü kennt nur Gruppen mit
  einer Wahl: keine Befehle, keine Untermenüs, keine Wahl durch Tippen eines Buchstabens, kein Öffnen mit den
  Pfeiltasten auf der Taste; es steht immer unter seiner Taste und schließt, sobald die Seite rollt oder das Fenster
  seine Größe ändert. Kalender, Heatmap und Menü kennen nur die Leserichtung von links nach rechts.
