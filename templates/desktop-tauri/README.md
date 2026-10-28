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
| „In den Papierkorb legen …“ fragt, Dialog vor dem Schließen „Abbrechen“ · „Verwerfen“ · „Sichern“ | AKT-07, AKT-08, AKT-11, EBE-03, FOR-04 |
| Fenstergrund aus der gespeicherten Wahl (`appearance.json`), Sprachen in `Info.plist` | DSK-14, DSK-08 |
| alle Wörter in `src/strings.ts`, CSP ohne `unsafe-inline`, Schriften selbst gehostet | TEC-10, TXT-05, HAL-09, SCH-02 |
| 200 % Schrift ohne seitliches Scrollen und ohne abgeschnittenen Text, axe ohne Befund | ZUG-01, ZUG-09, ZUG-06 |

Getestet wird auf 390, 480 und 1440&nbsp;px, hell und dunkel, mit 100 und 200&nbsp;% Schrift.

## Was ein Agent behalten muss

Die Regeln für Agenten stehen in [`../AGENTS-snippet.md`](../AGENTS-snippet.md); kopier sie in das `AGENTS.md` deines
Projekts. Dazu für diese Vorlage:

- `public/sebaro/` nie ändern, nur mit `npm run sebaro:sync` erneuern.
- Eigene Klassen beginnen mit `app-` und nutzen nur `var(--sb-*)`; keine neuen `sb-*`-Klassen, keine Farbwerte.
- Kein `style`-Attribut, kein Skript im HTML: die CSP in `index.html` und `src-tauri/tauri.conf.json` bleibt gleich.
- Jedes Wort kommt aus `src/strings.ts`.
- Die Kachel in der Titelleiste ist ein Platzhalter (die Kachel der Dachmarke). Ein echtes Produkt bekommt sein Zeichen
  aus der Werkstatt (ZEI-03, ZEI-08); die App-Icons erzeugt `npx tauri icon` aus dessen Bild.

## Nicht geprüft

Nichts davon ist in einem echten Tauri-Fenster getestet (WebKit unter macOS und Linux, WebView2 unter Windows): weder
Titelleiste, natives Menü, Fenstergrund noch Alt und F10. Die Tests laufen nur in Chromium (D96 (b)). DSK-01 bleibt
deshalb vorläufig.
