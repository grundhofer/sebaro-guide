# Vorlage: Web-App mit Vite und TypeScript

Eine kleine, lauffähige Web-App ohne Fenster („Musterapp“, ein erfundener Name) mit sebaro: Vite und TypeScript,
ohne UI-Framework. Die Oberfläche besteht nur aus dem Markup von `docs/bauteile.html`; das Verhalten der Bauteile kommt
aus sebaros eigenen Skripten (`public/sebaro/js/sb-*.js`). Alle Einträge und Werte sind Beispieldaten.

| Ansicht | Adresse | Was sie zeigt |
|---|---|---|
| Einträge | `#/` | Suche, Filterchips, Liste mit Erledigtem, leerer Zustand, Stand-Satz und „Neuer Eintrag“ unten |
| Eintrag | `#/eintrag/2` | Eigenschaften, Zustand als Zeichen und Wort, Kurzmeldung mit „Rückgängig“, Löschen mit Dialog, endgültiger Schritt mit 45°-Kante |
| Neuer Eintrag, Bearbeiten | `#/neu`, `#/bearbeiten/2` | Formular mit „(optional)“, Fehlern je Feld, Teilschritten mit „Rückgängig“, Dialog „Abbrechen“ · „Verwerfen“ · „Sichern“ |
| Einstellungen | `#/einstellungen` | Farbton Kühl · Warm, „Bewegung immer reduzieren“ |
| Datenarten | `#/daten` | jede Datenart von `docs/daten.html`: Text, Zahlen, Geld, Zeit, Kalender, Zustände, Tabellen mit Sortierung und Summe, Baum, Mehrfachauswahl, alle Diagramme, Orte, Belege |
| Impressum, Datenschutz, Barrierefreiheit | `#/impressum` … | Platzhalter für die Pflichtseiten |

## Starten

```sh
npm ci
npx playwright install chromium   # einmal, für die Prüfungen
npm run dev                       # http://localhost:5173
npm run build                     # tsc --noEmit, dann vite build nach dist/
npm test                          # baut, startet vite preview und prüft jede Ansicht (Playwright, Chromium)
npm run sebaro:verify             # die Kopie von sebaro ist unverändert (verify-export.mjs --strict)
```

`npm test` lädt jede Ansicht und jeden Zustand (offene Dialoge, Kurzmeldung, Formularfehler, Englisch) hell und dunkel,
bei 320, 390 und 1440&nbsp;px, mit 100 und echten 200&nbsp;% Schrift (CDP `Page.setFontSizes` vor dem Laden). Er scheitert
an seitlichem Scrollen, abgeschnittenem Text, jedem axe-Fund (WCAG 2.2 AA), Konsolenfehlern und CSP-Verstößen
(`tests/sebaro-checks.ts`). `tests/keyboard.spec.ts` prüft die vier festen Aufgaben nur mit der Tastatur und dass jede
Klasse von sebaro stammt oder mit `app-` beginnt. Die Bildschirmfotos liegen danach in `test-results/screens/`.

## sebaro aktualisieren

`public/sebaro/` ist eine unveränderte Kopie des Web-Exports aus `docs/sebaro/` des sebaro Guides; nie darin ändern.

```sh
npm run sebaro:sync                          # in diesem Repository: kopiert ../../docs/sebaro und prüft die Kopie
npm run sebaro:sync -- --from <Exportordner> # außerhalb: aus einem frischen Checkout des Guides
```

Danach `npm test` und die Fotos in beiden Modi ansehen. Die kopierten Dateien gehören ins Repository.

## Was die Vorlage zeigt (Regeln)

- Kopf einer Web-App ohne Fenster mit „Einstellungen“, DE / EN als Auswahl ohne Neuladen und „Hell oder Dunkel“; Fuß mit
  Impressum, Datenschutz, Barrierefreiheit und GitHub: NAV-06, NAV-07, WEB-02, WEB-03, WEB-10, AKT-09, TEC-10
- Farbton und Bewegung in den Einstellungen: FAR-15, BEW-04; Laden im Kopf: WEB-01
- eine Hauptaktion unten in der Aktionszone, zuletzt in jeder Gruppe, mit Stand-Satz und Datenweg-Zeile: AKT-01, AKT-02,
  AKT-04, AKT-11, STA-07, EBE-08, BEL-10
- Listen, Leerzustand, Suche, Chips: DAT-01, DAT-02, DAT-07, EIN-04, EIN-05, STA-09
- Formular: EIN-01, EIN-02, STA-03, RAU-07; Dialoge: EBE-03, AKT-07, AKT-08, AKT-11, FOR-04; Kurzmeldung: EBE-05
- Zustände und Daten: STA-01, STA-02, STA-05, STA-06, DAT-03 bis DAT-17 außer DAT-13 (Board), FOR-05, TXT-04, TXT-09, TXT-11 bis TXT-17, FAR-12, FAR-14,
  BEL-02, BEL-03, BEL-09
- Zugang: ZUG-01 bis ZUG-04, ZUG-06, ZUG-08, ZUG-09; strenge CSP ohne Inline-Skripte und -Stile, nichts von fremden
  Servern: HAL-09; nur Tokens: TEC-01, TEC-03 (`data-sb-view` an jeder Ansicht)

## Was ein Agent behalten muss

Übernimm den Abschnitt aus [`../AGENTS-snippet.md`](../AGENTS-snippet.md) in die `AGENTS.md` deines Projekts. Für diese
Vorlage gilt zusätzlich:

- Jedes Wort steht in `src/strings.ts` (de und en); Zahlen und Daten über `src/format.ts`.
- Eigene Klassen beginnen mit `app-` und nutzen nur `var(--sb-*)`; nie eine eigene `sb-*`-Klasse, nie eine Farbe von Hand.
- Kein `style`-Attribut, kein Inline-Skript: die CSP in `index.html` bleibt so streng.
- Die Kachel im Kopf ist ein Platzhalter (die Dachmarke). Ein echtes Produkt bekommt sein eigenes Zeichen aus der
  Werkstatt (ZEI-03, ZEI-08) und exportiert sich mit `--product <id>`.
- `npm test` muss grün sein, bevor eine Ansicht fertig ist; die Prüfliste `../screen-checklist.md` gilt dazu.

## Nicht geprüft

Nur Chromium; kein Firefox, kein WebKit, kein echter Screenreader. Das Datumsfeld zeigt das Format der Browsersprache,
nicht der Seitensprache. Audio und Video sind nicht dabei (keine Mediendateien), die Befehlspalette mit ⌘K auch nicht:
sie gehört zur Web-App mit Fenster (siehe `../desktop-tauri/`).
