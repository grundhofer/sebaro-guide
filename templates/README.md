# Templates

Starting points for new sebaro projects. Copy, then adapt; nothing here is loaded by the guide site.

| File | Use |
|---|---|
| [`AGENTS-snippet.md`](AGENTS-snippet.md) | paste into a product repo's `AGENTS.md` / `CLAUDE.md` so every agent session there follows sebaro |
| [`screen-checklist.md`](screen-checklist.md) | the per-screen review before a screen counts as done (both modes, 390 px and 1440 px) |
| [`web-plain/index.html`](web-plain/index.html) | minimal website/web app page wired to an exported `sebaro/` folder, no build step |
| [`design-exception.md`](design-exception.md) | how to ask the owner when a rule does not fit (instead of working around it) |

## New project in five steps

1. **Pick the product id** and its tile group (studio, collaboration, everyday, learning, tools, media, money, system).
   A new product needs its sign drawn and checked in sebaroDesign first (rules ZEI-*).
2. **Get the system files**: web → copy `docs/sebaro/` of this repo into the project (e.g. `public/sebaro/` or
   `src/sebaro/`); Tauri/macOS/Android → `export_system.py` in sebaroDesign (see [AGENTS.md §4](../AGENTS.md)).
3. **Paste the agent snippet** into the project's `AGENTS.md`.
4. **Build screens from recipes**: `docs/app.html`, `docs/web.html`, `docs/desktop.html`; components from
   `docs/bauteile.html`; data from `docs/daten.html`.
5. **Review with the checklist** in both modes; record exceptions with `design-exception.md`.
