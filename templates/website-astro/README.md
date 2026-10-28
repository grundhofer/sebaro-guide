# Startvorlage: Website mit Astro

Eine kleine statische Website („Beispielseite“, erfunden) mit Astro und sebaro, so gebaut, wie der
[sebaro Guide](https://grundhofer.github.io/sebaro-guide/web.html) es vorschreibt: Kopf mit Lockup, den vier Wörtern,
DE / EN und „Hell oder Dunkel“, Fußzeile mit Impressum, Datenschutz, Barrierefreiheit und „Darstellung“, ein Artikel
mit Fußnoten, eine Seite „Über“, die Pflichtseiten, eine 404-Seite und ein Vorschaubild je Seite.
Kopier den Ordner, ersetz Namen und Inhalte, behalte die Regeln.

## Starten

Node 22.12 oder neuer.

```sh
npm ci
npx playwright install chromium   # für die Vorschaubilder und die Tests
npm run dev                        # Entwicklung, ohne Vorschaubilder
npm run build                      # Vorschaubilder (scripts/og.mjs) und dist/
npm run preview
npm test                           # Playwright in Chromium, nach npm run build
npm run sebaro:verify              # die Systemdateien sind unverändert
```

## Seiten

| Seite | Datei | Zeigt |
|---|---|---|
| Start, deutsch und englisch | `src/pages/index.astro`, `src/pages/en/index.astro` | eine Hauptaktion, zuletzt in ihrer Gruppe; DE / EN führt auf dieselbe Seite |
| Apps | `src/pages/apps.astro` | leerer Zustand „Noch keine App“ |
| Projekte, Artikel | `src/pages/projekte/` | Liste mit Schlusssatz; Artikel mit Brotkrumen, Inhalt, Code, Hinweis, Zitat, Fußnoten mit zwei Rücksprüngen, Popover unter 1024&nbsp;px, „Weiter:“ |
| Über, Kontakt | `src/pages/ueber.astro`, `src/pages/kontakt.astro` | Person als Initialen; E-Mail als Aktion mit dem Hinweis zum Datenweg |
| Impressum, Datenschutz, Barrierefreiheit | `src/pages/*.astro` | Pflichtseiten des Fußes, als Beispieldaten markiert |
| 404 | `src/pages/404.astro` | was passiert ist, was du tun kannst, „Technische Angaben“ |

Alle Wörter stehen in `src/strings.mjs` (deutsch, für die Startseite auch englisch). Eigene Gestaltung steht nur in
`public/css/site.css` (als Datei verlinkt, nicht importiert: `astro dev` setzte sie sonst als `<style>` ein, das die Content-Security-Policy sperrt), mit dem Präfix `app-` und nur mit `var(--sb-*)`.

## sebaro-Dateien aktualisieren

`public/sebaro/` ist eine unveränderte Kopie des Web-Exports aus `docs/sebaro/` des Guides; nie darin ändern.

```sh
npm run sebaro:sync                                  # aus ../../docs/sebaro, wenn der Ordner im Guide liegt
npm run sebaro:sync -- --from <Ordner mit dem Export> # sonst aus einer Kopie von docs/sebaro/
```

Das Skript kopiert den Ordner, prüft ihn mit `checks/verify-export.mjs --strict` und legt Favicons und Manifest aus
`brand/site-root/` an die Wurzel. Danach `npm run build` und `npm test`, dann die kopierten Dateien committen.

## Was die Vorlage zeigt (Regel-IDs)

- Kopf und Fuß: NAV-06, NAV-07, NAV-01, WEB-02, WEB-03, WEB-10, FAR-15, AKT-09, ZUG-06
- Laden und Sicherheit: WEB-01, HAL-09, SCH-02, TEC-01, TEC-10; strenge Content-Security-Policy ohne `'unsafe-inline'`
- Inhalt: AKT-01, AKT-04, AKT-11, DAT-01, DAT-03, DAT-05, DAT-06, DAT-07, TXT-01, TXT-03 bis TXT-08, TXT-10, TXT-17,
  STA-02, STA-05, BEL-02, BEL-07, BEL-09, BEL-10, LNK-01, LNK-02, ZUG-07 (vorläufig)
- Vorschaubild je Seite aus dem Build: WEB-09 (`scripts/og.mjs` ruft `public/sebaro/brand/og/render.mjs`)
- Druck immer hell: WEB-11 (`sb-print.js`); große Schrift: ZUG-09 (`sb-fit.js`)

Geprüft mit `npm test`: jede Seite hell und dunkel, bei 320, 390 und 1440&nbsp;px, bei 100&nbsp;% und echten
200&nbsp;% Schrift (kein seitliches Scrollen, kein abgeschnittener Text, axe ohne Verstoß, kein Fehler in der Konsole,
keine Verletzung der Content-Security-Policy), dazu die Wege mit der Tastatur.

## Platzhalter

- Kachel im Kopf, Favicons, Manifest und Vorschaubilder zeigen das Zeichen der Dachmarke sebaro. Ein echtes Produkt
  braucht sein eigenes Zeichen aus der Werkstatt (ZEI-03, ZEI-08) und ersetzt `tile-studio-small.svg` in
  `src/layouts/Base.astro` und `SITE.product` in `src/strings.mjs`. Markendateien stehen nicht unter der Lizenz des
  Projekts (`public/sebaro/LICENSE.md`).
- „GitHub“ im Fuß fehlt, weil die Beispielseite kein öffentliches Repository hat (WEB-03).
- Kein Kontaktformular: eine statische Seite hat keinen Server, der es annimmt (dann `sb-form.js`, WEB-05).

## Für Agenten

Übernimm [`../AGENTS-snippet.md`](../AGENTS-snippet.md) in das `AGENTS.md` des Projekts. Behalte: nur Klassen aus
`public/sebaro/css/sebaro.css` und `app-` für Eigenes, nur `var(--sb-*)`, keine Inline-Stile oder -Skripte (die
Content-Security-Policy in `src/layouts/Base.astro` verbietet sie), alle Wörter in `src/strings.mjs`, kein Shiki
(es schreibt `style`-Attribute; Code mit `sb-tok-*`), nichts von fremden Servern, und `npm test` grün vor jedem
Commit. Passt eine Regel nicht, nenn ihre ID und frag, statt sie zu umgehen.
