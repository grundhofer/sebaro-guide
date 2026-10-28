# Templates

Starting points for new sebaro projects. Copy, then adapt; nothing here is loaded by the guide site.

| File | Use |
|---|---|
| [`AGENTS-snippet.md`](AGENTS-snippet.md) | paste into a product repo's `AGENTS.md` / `CLAUDE.md` so every agent session there follows sebaro |
| [`screen-checklist.md`](screen-checklist.md) | the per-screen review before a screen counts as done (both modes, 390 px and 1440 px) |
| [`web-plain/index.html`](web-plain/index.html) | minimal website/web app page wired to an exported `sebaro/` folder, no build step |
| [`android-compose/`](android-compose/README.md) | Android app (Kotlin, Jetpack Compose) on the private Maven package `sebaro-compose` 1.10.2: list, detail, form, settings, data and the three dialogs, with lint and Robolectric/Roborazzi screenshot tests; README in German |
| [`design-exception.md`](design-exception.md) | how to ask the owner when a rule does not fit (instead of working around it) |
| [`website-astro/`](website-astro/README.md) | runnable static website (Astro): start page DE/EN, article with footnotes, about, contact, imprint, privacy, accessibility, 404, one share image per page from the build |
| [`webapp-vite/`](webapp-vite/README.md) | runnable web app without a window (Vite + TypeScript, no framework): list with search, filter and empty state, detail, form with validation, settings, every data type of `docs/daten.html`, dialogs, toasts with undo |
| [`desktop-tauri/`](desktop-tauri/README.md) | runnable Tauri 2 desktop app: window frame, sidebar with the „Einstellungen“ foot, document tabs, inspector, „Menü“, ⌘K palette, the 15 fixed shortcuts, slim settings, window density |

The three starters are complete small projects: each carries an unchanged copy of the web export in `public/sebaro/`
(copied by `npm run sebaro:sync`, checked by `npm run sebaro:verify`, i.e. `verify-export.mjs --strict`), keeps every
word in one strings module, uses only `sb-*` classes of the export plus its own `app-*` classes with `var(--sb-*)`
tokens, runs under a strict Content-Security-Policy and has Playwright tests (Chromium) for every screen in light and
dark at 100 % and real 200 % text with axe. CI: `.github/workflows/templates.yml`. Names and content are invented
(„Beispielseite“, „Musterapp“); the sign tile is the umbrella sign as a placeholder.

## New project in five steps

1. **Pick the product id** and its tile group (studio, collaboration, everyday, learning, tools, media, money, system).
   A new product needs its sign drawn and checked in sebaroDesign first (rules ZEI-*).
2. **Start from a starter or get the system files**: copy `website-astro/`, `webapp-vite/` or `desktop-tauri/` and run
   `npm run sebaro:sync -- --from <docs/sebaro of a guide checkout>` there; else web → copy `docs/sebaro/` of this
   repo into the project (e.g. `public/sebaro/`), check it with `node public/sebaro/checks/verify-export.mjs
   public/sebaro --strict`; Tauri (own export)/macOS/Android/iOS → `export_system.py` in sebaroDesign (see [AGENTS.md §4](../AGENTS.md)).
3. **Paste the agent snippet** into the project's `AGENTS.md`.
4. **Build screens from recipes**: `docs/app.html`, `docs/ios.html`, `docs/web.html`, `docs/desktop.html`; components from
   `docs/bauteile.html`; data from `docs/daten.html`.
5. **Review with the checklist** in both modes; record exceptions with `design-exception.md`. In a starter, `npm test`
   runs the automatic part (both modes, 100 % and 200 % text, the screen asked for with its heading and open overlays,
   axe, no sideways scroll, no cut text or control value, CSP; no word written into markup, no length without a token).
