# Startvorlage: Desktop-App mit Tauri 2

Eine kleine, lauffähige Desktop-App „Musterapp Desktop“ (erfunden) mit sebaro: Tauri 2, die Oberfläche als Vite und
TypeScript ohne UI-Framework. Die Webview lädt denselben Web-Export wie eine Website (D77); der Guide liefert keinen
eigenen Tauri-Export, die Schriften kommen als WOFF2 aus `public/sebaro/fonts/web/`. Alle Notizen sind Beispieldaten.

## Starten

```sh
npm ci
npm run tauri dev          # das Fenster mit Vite im Hintergrund
npm run build              # nur die Oberfläche: tsc und vite build nach dist/
npm test                   # Playwright in Chromium gegen dist/ (vorher npm run build)
npm run sebaro:verify      # der Export ist unverändert (verify-export.mjs --strict)
npx tauri build --debug --no-bundle   # die App bauen, ohne Installationspaket
```

Unter Linux braucht Tauri diese Pakete (Debian, Ubuntu):

```sh
sudo apt-get install -y libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev \
  libayatana-appindicator3-dev librsvg2-dev
```

Die CI (`.github/workflows/templates.yml`, ubuntu-latest) baut die Oberfläche, prüft den Export, lässt alle Tests in
Chromium laufen und baut die App mit `tauri build --debug --no-bundle`.

## sebaro-Dateien erneuern

`public/sebaro/` ist eine unveränderte Kopie von `docs/sebaro/` aus dem sebaro Guide. Nie darin ändern.

```sh
npm run sebaro:sync                              # aus ../../docs/sebaro (diese Vorlage im Guide-Repository)
npm run sebaro:sync -- --from <Pfad zum Export>  # aus einem anderen Checkout des Guides
```

Das Skript kopiert den Ordner und prüft ihn danach mit `checks/verify-export.mjs --strict`. Die kopierten Dateien
werden eingecheckt, damit die Vorlage allein läuft. Das Fenster bekommt seinen Grund beim Bauen aus `tokens.css`
(`src-tauri/build.rs`), nie als abgeschriebenen Wert.

## Was die Vorlage zeigt

Wo die Vorlage eine dieser Regeln noch nicht ganz erfüllt, steht es unter „Lücken der Vorlage“: DSK-01 und DSK-06
(Ziehfläche), ZUG-06 (Fokus nach „In den Papierkorb legen“), ZUG-09 (`sbFit.refresh`) und STA-07 (Fehler beim
Sichern).

| Teil | Regeln |
|---|---|
| Fenster: Titelleiste, Seitenleiste, Inhalt, Inspektor, Aktionszone über die ganze Breite, Dichte „window“ | DSK-01, EBE-01, EBE-08, RAU-06 |
| Titelleiste mit Kachel, Name, Pfad, Werkzeugen mit Tooltip und der Taste „Menü“ mit fünf Gruppen | DSK-06, DSK-08, NAV-10, EBE-06, EBE-07 |
| Seitenleiste mit Suchfeld, Baum, Status als Zeichen und Wort, Fuß „Einstellungen“ | NAV-04, NAV-11, EIN-05, STA-08, TXT-09 |
| Seitenleiste und Inspektor ausblendbar, ziehbare Trennlinien, „Schmal · Normal · Breit“ | DSK-04, DSK-07 |
| Dokument-Reiter mit Punkt für „geändert“, Entf und ⌘W | DSK-10 |
| Zählerzeile, Stand-Satz, eine Hauptaktion „Neue Notiz“ zuletzt | STA-07, AKT-01, AKT-02, AKT-11 |
| Befehlspalette mit ⌘K / Strg+K | NAV-09 |
| die 15 festen Kürzel und F6, auch als Dialog „Tastaturkürzel“ | DSK-09, ICO-08 |
| schlanke Einstellungen (⌘,): Hell oder Dunkel, Farbton, Bewegung | DSK-02, DSK-05, FAR-15, BEW-04 |
| „In den Papierkorb legen …“ fragt; der Papierkorb im Baum hält die Notizen, „Zurücklegen“ holt eine zurück, „Papierkorb leeren …“ fragt und löscht endgültig; Dialog vor dem Schließen „Abbrechen“ · „Verwerfen“ · „Sichern“ | AKT-07, AKT-08, AKT-11, EBE-03, FOR-04, DSK-08 |
| Fenstergrund aus der gespeicherten Wahl (`appearance.json`), Sprachen in `Info.plist` | DSK-14, DSK-08 |
| alle Wörter in `src/strings.ts`, CSP ohne `unsafe-inline`, Schriften selbst gehostet | TEC-10, TXT-05, HAL-09, SCH-02 |
| 200 % Schrift ohne seitliches Scrollen und ohne abgeschnittenen Text, axe ohne Befund | ZUG-01, ZUG-09, ZUG-06 |

Getestet wird auf 390, 480 und 1440&nbsp;px, hell und dunkel, mit 100 und 200&nbsp;% Schrift (`tests/sebaro-checks.ts`),
mit dem Papierkorb (eine Notiz darin gewählt, Dialog „Papierkorb leeren?“) und dem Fenster ohne offene Notiz.
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
`tests/strings.spec.ts` prüft, dass `index.html` kein Wort selbst schreibt; `tests/dimensions.spec.ts`, dass jede Länge
in `src/app.css` ein Token ist (heute keine Ausnahme).

## Was ein Agent behalten muss

Die Regeln für Agenten stehen in [`../AGENTS-snippet.md`](../AGENTS-snippet.md); kopier sie in das `AGENTS.md` deines
Projekts. Dazu für diese Vorlage:

- `public/sebaro/` nie ändern, nur mit `npm run sebaro:sync` erneuern.
- Eigene Klassen beginnen mit `app-` und nutzen nur `var(--sb-*)`; keine neuen `sb-*`-Klassen, keine Farbwerte.
- Kein `style`-Attribut, kein Skript im HTML: die CSP in `index.html` und `src-tauri/tauri.conf.json` bleibt gleich.
- Jedes Wort kommt aus `src/strings.ts`. `src/main.ts` schreibt seine Wörter mit `t()`; das prüft kein Test, nur die
  Durchsicht.
- Maße nur aus Tokens (TEC-01); wo sebaro keins hat, sagt ein Kommentar „no sebaro token“ warum, Umbrüche in rem oder em.
- Die Kachel in der Titelleiste ist ein Platzhalter (die Kachel der Dachmarke). Ein echtes Produkt bekommt sein Zeichen
  aus der Werkstatt (ZEI-03, ZEI-08); die App-Icons erzeugt `npx tauri icon` aus dessen Bild.

## Lücken der Vorlage (Agenten-Test 2026-10)

Eine Probeaufgabe auf dieser Vorlage („Notizen“, [`../../docs/agenten-test-2026-10.md`](../../docs/agenten-test-2026-10.md))
hat gezeigt, was ein Agent übernimmt oder übersieht. Bau es so:

- **Datenweg-Zeile:** unter „Neue Notiz“ fehlt „Bleibt auf diesem Gerät.“ (BEL-10 gilt für jede Aktion mit Datenweg,
  auch im Fenster; die Fenster auf `docs/desktop.html` zeigen sie auch nicht, eine Frage an die Werkstatt).
- **Titelleiste:** `data-tauri-drag-region` fehlt an der Leiste (DSK-01, DSK-06: an `sb-window__titlebar`,
  `sb-window__name` und `sb-window__path`, nie an Tasten), und `src-tauri/capabilities/default.json` erlaubt das
  Ziehen nicht: ergänze `core:window:allow-start-dragging` (`core:default` enthält es nicht). Ohne beides lässt sich
  das Fenster unter macOS nicht ziehen, weil die Leiste dort die Titelleiste ist. „Neues Fenster“ ist gesperrt,
  mehrere Fenster baut die Vorlage nicht (DSK-12).
- **Neu gezeichneter Text:** wer den Baum, die Reiter oder den Inspektor neu schreibt, ruft danach
  `window.sbFit?.refresh(<Element>)`; sonst verlieren Wörter bei 200&nbsp;% ihren Trennstrich („Papierko|rb“, ZUG-09).
- **Fokus nach einem Dialog:** nach „In den Papierkorb legen“ steht der Fokus auf einem sinnvollen Ziel, etwa der
  nächsten Notiz im Baum, nie auf `<body>` (ZUG-06).
- **Fehler beim Sichern:** schlägt `localStorage` oder ein Rust-Befehl fehl, sagt die Aktionszone das als Satz; nie
  „Alles gesichert.“ nach einem verschluckten Fehler (HAL-04, STA-07).
- **Start mit der Kachel:** STR-01 gilt auf jeder Plattform; die Vorlage baut ihn noch nicht ein (weder
  `data-sb-start` noch `sb-start.js`). Bau ihn ein: die 96-px-Kachel wandert in die Kachel der Titelleiste.
- **Markup ohne Skript:** TEC-02 gilt auch hier (Plattformen `web` und `desktop`) und verlangt klassische Skripte,
  keine Module; die Oberfläche ist aber ein Modul (`type="module"`). Das ist eine Lücke der Vorlage. Wie TEC-02 zu
  einem Vite-Build passt, ist eine Frage an den Inhaber; frag mit der ID.
- **`CHECKS.md`:** TEC-06 verlangt sie, mit jedem Befehl, Datum und Exit-Code, auch dem nicht gelaufenen
  `tauri build` mit Grund.
- **Port 4174:** `npm test` nutzt einen Server, der dort schon läuft (`reuseExistingServer` außerhalb der CI). Beende
  zuerst jeden anderen Server auf dem Port und starte mit `CI=1`: dann bricht ein belegter Port den Lauf laut ab,
  statt eine fremde App zu prüfen.

## Nicht geprüft

Nichts davon ist in einem echten Tauri-Fenster getestet (WebKit unter macOS und Linux, WebView2 unter Windows): weder
Titelleiste, natives Menü, Fenstergrund noch Alt und F10. Die Tests laufen nur in Chromium (D96 (b)). DSK-01 bleibt
deshalb vorläufig.
