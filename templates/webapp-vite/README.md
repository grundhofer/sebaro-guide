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

`npm test` lädt jede Ansicht und jeden Zustand (leere Liste, kein Treffer, abgeschlossener und unbekannter Eintrag,
offene Dialoge, Kurzmeldungen, Formularfehler, lange Werte, Englisch) hell und dunkel, bei 320, 390 und 1440&nbsp;px, mit
100 und echten 200&nbsp;% Schrift (CDP `Page.setFontSizes` vor dem Laden). Er scheitert an seitlichem Scrollen,
abgeschnittenem Text, jedem axe-Fund (WCAG 2.2 AA), Konsolenfehlern und CSP-Verstößen (`tests/sebaro-checks.ts`).
Jeder Fall nennt, was auf dem Bildschirm stehen muss: den HTTP-Status der Seite, den Text der einen sichtbaren
Überschrift `h1`, die Ansicht (`data-sb-view` oder ein Selektor) und genau die offenen Überlagerungen (Dialoge, Popover,
Kurzmeldungen; keine, wenn der Fall `null` sagt). Er scheitert auch an Text, den ein Bedienelement selbst abschneidet: der
gewählte Eintrag einer Auswahl, ein Platzhalter, der Wert eines schreibgeschützten Felds, oder ein Icon oder Suffix über
dem Text. Ein eingetippter Wert, der länger ist als sein einzeiliges Feld, läuft darin seitlich weiter (D110, „wie in
jedem Textfeld“); er zählt als Notiz im Test, nicht als Fehler. Nicht gemessen: Datums- und Zeitfelder (ihre Teile zeichnet
der Browser) und die offene Liste einer Auswahl (zeichnet das System). Einen Schnitt, den sebaros eigenes CSS verursacht
und den die Vorlage nicht ändern darf, nennt der Fall als `controlWaivers` mit Grund; er steht bei jedem Lauf als Notiz
im Bericht und ist eine Bitte an die Werkstatt.
Heute steht dort einer: „Gesundheit“ in der Auswahl „Kategorie“ fehlen bei 200&nbsp;% auf 320&nbsp;px 4&nbsp;px, weil
`.sb-select > select` am Ende Platz in rem für das Chevron hält.

`tests/keyboard.spec.ts` prüft die vier festen Aufgaben nur mit der Tastatur und dass jede Klasse von sebaro stammt oder
mit `app-` beginnt. `tests/data-safety.spec.ts` prüft, dass nichts ungefragt verloren geht: jeder Weg aus einem Formular
mit ungesicherten Änderungen fragt zuerst (Link, Adresse, Zurück, Vor, Schließen und Neuladen; DE / EN behält den
Entwurf), und „Beispieldaten wiederherstellen“ fügt nur fehlende Beispiele hinzu, die eigenen Einträge bleiben.
`tests/strings.spec.ts` und `tests/dimensions.spec.ts` lesen den Quelltext: kein Wort im Markup einer Ansicht, keine Länge
ohne Token oder Begründung. Die Bildschirmfotos liegen danach in `test-results/screens/`.

## sebaro aktualisieren

`public/sebaro/` ist eine unveränderte Kopie des Web-Exports aus `docs/sebaro/` des sebaro Guides; nie darin ändern.

```sh
npm run sebaro:sync                          # in diesem Repository: kopiert ../../docs/sebaro und prüft die Kopie
npm run sebaro:sync -- --from <Exportordner> # außerhalb: aus einem frischen Checkout des Guides
```

Danach `npm test` und die Fotos in beiden Modi ansehen. Die kopierten Dateien gehören ins Repository.

## Was die Vorlage zeigt (Regeln)

Wo die Vorlage eine dieser Regeln noch nicht ganz erfüllt, steht es unter „Lücken der Vorlage“: NAV-06 (⌘K), BEL-10,
RAU-07, EBE-05, TXT-04 und ZUG-08.

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

- Jedes Wort steht in `src/strings.ts` (de und en), auch die Beispieleinträge (`samples`); was in beiden Sprachen gleich
  ist (Kürzel, Adressen, IDs, Dateinamen, Code), steht dort in `SHARED`. Zahlen und Daten über `src/format.ts`.
- Maße nur aus Tokens (TEC-01). Wo sebaro keins hat, sagt ein Kommentar „no sebaro token“ warum; Umbrüche in rem oder
  em, damit sie der Schriftgröße folgen. Heute ohne Token: die kleinste Breite einer Karte im Raster (`16rem`,
  `.app-card-grid`).
- Eigene Klassen beginnen mit `app-` und nutzen nur `var(--sb-*)`; nie eine eigene `sb-*`-Klasse, nie eine Farbe von Hand.
- Kein `style`-Attribut, kein Inline-Skript: die CSP in `index.html` bleibt so streng.
- Die Kachel im Kopf ist ein Platzhalter (die Dachmarke). Ein echtes Produkt bekommt sein eigenes Zeichen aus der
  Werkstatt (ZEI-03, ZEI-08) und exportiert sich mit `--product <id>`.
- `npm test` muss grün sein, bevor eine Ansicht fertig ist; die Prüfliste `../screen-checklist.md` gilt dazu.

## Nicht geprüft

Nur Chromium; kein Firefox, kein WebKit, kein echter Screenreader. `tests/strings.spec.ts` liest nur Markup in
den Vorlagen der Funktion `html` und `index.html`, keine Zeichenketten, die Code an Hilfsfunktionen übergibt; Zahlen und Zeichen allein
(08:12, ±0) gelten als Werte. Die Frage beim Schließen ist die des Browsers (`beforeunload`); ihr Text ist nicht änderbar. Das Datumsfeld zeigt das Format der Browsersprache,
nicht der Seitensprache. Audio und Video sind nicht dabei (keine Mediendateien).

## Lücken der Vorlage (Agenten-Test 2026-10)

Fünf Probeaufgaben auf dieser und den anderen Vorlagen ([`../../docs/agenten-test-2026-10.md`](../../docs/agenten-test-2026-10.md))
haben gezeigt, was Agenten aus der Vorlage übernehmen, obwohl es keiner Regel folgt. Übernimm es nicht, sondern bau es so:

- **Befehlspalette mit ⌘K / Strg+K fehlt.** NAV-06 verlangt sie auch in einer Web-App ohne Fenster („⌘K öffnet auch
  dort die Befehlspalette“). Die Vorlage hat sie noch nicht; das Markup steht in `docs/bauteile.html` (Befehlspalette),
  das Verhalten in `../desktop-tauri/`. NAV-09 nennt nur Apps mit Fenster; das ist eine offene Frage an den Inhaber,
  keine Erlaubnis, sie wegzulassen.
- **Kurzmeldung „Alle Beispiele sind schon da.“** meldet, dass nichts geschah, und zeigt ein „Rückgängig“, das nichts tut:
  `action.hidden` in `src/main.ts` setzt sich gegen `display` von `.sb-toast__action` in `sebaro.css` nicht durch.
  Eine Kurzmeldung gibt es nur für das umkehrbare Ergebnis einer Aktion außerhalb der Hauptaktion (EBE-05); eine
  Aktion ohne Rückgängig nimm aus dem DOM.
- **Titel als Satz:** „Diesen Eintrag gibt es nicht“ und „Diese Ansicht gibt es nicht“ in `src/strings.ts`. Bildschirmtitel
  sind kurze Substantive (TXT-03), etwa „Unbekannter Eintrag“; der Satz gehört in den Text darunter.
- **Barrierefreiheit** ist ein Platzhalter, der auf der Seite „(ZUG-07)“ zeigt. Ein Produkt schreibt die sechs Teile
  Beschreibung, Bedienung, Erfüllung, Einschränkungen, Rückmeldung, Behörde (ZUG-07) und nennt nie gelaufene
  Screenreader-Tests „offen“ (ZUG-08).
- **Datenweg-Zeile** fehlt unter „Sichern“ im Dialog „Änderungen sichern?“ (BEL-10). `src/app.css` setzt den Abstand von
  `.sb-action-hint` in `sb-view--wide` auf 0 und richtet die Zeile ans Ende aus. Unter 640&nbsp;px Ansichtsbreite steht
  sie darum bündig unter der Aktion; erst ab 640&nbsp;px gibt der Zeilenabstand der Leiste 8&nbsp;px. BEL-10 will sie
  8&nbsp;px unter der Hauptaktion und zentriert.
- **Abstand am Kind:** `.app-view-title` setzt `margin-block-start`; den Abstand trägt das Elternteil (`sb-stack`,
  RAU-07). Kopier das Muster nicht für eigene Klassen.
- **U+00A0 ist unsichtbar.** `src/strings.ts` schreibt es als Zeichen; wer einen Satz neu tippt, verliert es („200 %“).
  Schreib `\u00a0` (TXT-04).
- **Nicht eingebaut, obwohl die Regeln gelten:** der Start mit der Kachel (STR-01 gilt auf jeder Plattform, auch für eine
  App mit einer Hülle: `index.html` hat weder `data-sb-start` noch `sb-start.js`), das Vorschaubild der Startseite
  (WEB-09: eine App mit einer Hülle und privaten Zugangslinks braucht nur das Bild der Startseite; sonst bekommt jede
  Seite mit eigenem Titel ihr eigenes) und Markup, das ohne Skript den richtigen Zustand zeigt
  (TEC-02 gilt für `web`; die Ansichten rendert hier ein Modul). Bau STR-01 und WEB-09 ein.
- **Frage an den Inhaber:** ob WEB-11 („Drucke jede Website hell“, `sb-print.js`) für eine Web-App gilt, und wie
  TEC-02 („klassische Skripte, keine Module“) zu einem Vite-Build passt, der die Oberfläche als Modul ausliefert. Frag
  mit den IDs, statt es selbst zu entscheiden.
- **`CHECKS.md` fehlt.** TEC-06 verlangt sie in jedem Produkt: jede Prüfung mit Befehl, Datum und Exit-Code, jede nicht
  gelaufene mit Grund.
- **Port 4173:** `playwright.config.ts` nutzt einen Server, der dort schon läuft (`reuseExistingServer` außerhalb der CI).
  Läuft die Vorschau eines anderen Projekts, prüft `npm test` dieses. Beende zuerst jeden anderen Server auf dem Port und
  starte mit `CI=1`: dann bricht ein belegter Port den Lauf laut ab, statt eine fremde App zu prüfen.
