# Templates

Starting points for new sebaro projects. Copy, then adapt; nothing here is loaded by the guide site.

| File | Use |
|---|---|
| [`AGENTS-snippet.md`](AGENTS-snippet.md) | paste into a product repo's `AGENTS.md` / `CLAUDE.md` so every agent session there follows sebaro |
| [`screen-checklist.md`](screen-checklist.md) | the per-screen review before a screen counts as done (both modes, 390 px and 1440 px) |
| [`web-plain/index.html`](web-plain/index.html) | minimal website/web app page wired to an exported `sebaro/` folder, no build step |
| [`android-compose/`](android-compose/README.md) | Android app (Kotlin, Jetpack Compose) on the private Maven package `sebaro-compose` 1.10.3: list, detail, form, settings, data and the three dialogs, with lint and Robolectric/Roborazzi screenshot tests; README in German |
| [`ios-swiftui/`](ios-swiftui/README.md) | iOS app (Swift, SwiftUI, iOS 17+) on the local Swift package `SebaroDesign/`, the filtered iOS export (D112, a snapshot updated with `tools/sebaro-sync.sh` from the workshop): tab bar, list, detail, form sheet with stepper and time row, settings with language, data and the three dialogs, a JSON file in Application Support; screenshot tests light/dark, default and AX5, 393 and 320 pt with a text check, behaviour tests, SwiftUI lint, CI on `macos-latest`; README in German |
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
   public/sebaro --strict`; Android → copy `android-compose/`, which takes sebaro from the Maven package `sebaro-compose`
   (read access needed, see its README); iOS → copy `ios-swiftui/`, which carries the iOS export as a local Swift
   package (`tools/sebaro-verify.py` checks the copy; a product re-exports with its id, see its README); Tauri (own
   export)/macOS → `export_system.py` in sebaroDesign (see [AGENTS.md §4](../AGENTS.md)).
3. **Paste the agent snippet** into the project's `AGENTS.md`, fill in the export path and the product id, and name the
   product kind (its first item says where light/dark, language, „Farbton“ and ⌘K go). Read what the starter itself
   does not do yet, so it is never copied as a pattern: the section „Lücken der Vorlage“ in `website-astro/`,
   `webapp-vite/`, `desktop-tauri/` and `ios-swiftui/`, „Bekannte Grenzen“ in `android-compose/` (the agent test did
   not cover the Android and iOS templates).
4. **Build screens from recipes**: `docs/app.html`, `docs/ios.html`, `docs/web.html`, `docs/desktop.html`; components from
   `docs/bauteile.html`; data from `docs/daten.html`.
5. **Review with the checklist** in both modes; record exceptions with `design-exception.md`. In a starter, `npm test`
   runs the automatic part (both modes, 100 % and 200 % text, the screen asked for with its heading and open overlays,
   axe, no sideways scroll, no cut text or control value, CSP; no word written into markup, no length without a token).
   `npm test` reuses a server already listening on its port outside CI: with another preview running it tests that
   app. Stop any other server on the port first and run `CI=1 npm test`, which makes a busy port fail loudly instead.
   Write what ran into `CHECKS.md` (TEC-06).

An agent test of 2026-10 built five small products from these starters with only the snippet, `llms.txt`, `RULES.md`
and the guide pages; what agents missed and why is in [`../docs/agenten-test-2026-10.md`](../docs/agenten-test-2026-10.md).
