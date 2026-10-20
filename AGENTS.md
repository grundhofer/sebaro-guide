# AGENTS.md: sebaro Guide

Entry point for AI agents (Claude Code, Codex, others) that **build a sebaro app, website or desktop app**, and for
agents that **change this guide**. The owner's overview in German is [README.md](README.md). Live site:
<https://grundhofer.github.io/sebaro-guide/>.

## 1 What this repository is

The sebaro Guide is the complete, demonstrated design guide of every sebaro product: colour jobs, type, space, shape,
layers, motion, behaviour, components, data display, writing, signs, platforms, and the reasoning behind each rule.

| You need | Read / use |
|---|---|
| every rule, machine-readable | [`rules/rules.json`](rules/rules.json) (schema [`rules/rules.schema.json`](rules/rules.schema.json)); also served as `docs/rules.json` |
| every rule as Markdown | [`guide/RULES.md`](guide/RULES.md) (generated, grouped by area, with why/do/don't/check) |
| live examples (right/wrong) per rule | `docs/regeln.html#<RULE-ID>` |
| tokens with live values | `docs/grundlagen.html` |
| correct markup of every component | `docs/bauteile.html` (each entry has a "Markup" block) |
| how to show any kind of data | `docs/daten.html` |
| full example: website / phone app / desktop app | `docs/web.html`, `docs/app.html`, `docs/desktop.html` |
| why it is the way it is | `docs/gedanken.html` |
| what waits for the owner's choice, is open, comes later or is done | `docs/ausblick.html` |
| what changed between versions | [`CHANGELOG.md`](CHANGELOG.md) (every rule change by id) |
| starting a new project | [`templates/`](templates/README.md) |
| system files (CSS tokens, components, fonts, icons, tiles, scripts) | `docs/sebaro/`, a verified web export, see §4 |

Rule status: **entschieden** = owner decision, binding. **vorläufig** = an agent's decision, valid until the owner
changes it. **offen** = proposal only, do not build it as a rule. `D<n>` refers to row n of the decision log in the
workshop repository sebaroDesign (private; the guide covers D1–D90). A rule id (e.g. `AKT-01`) is stable; cite it
in code reviews, commit messages and ADRs.

## 2 The ten rules most often broken

1. **One colour, one job.** Cobalt = current place, link, focus. Lime = the one primary action. Status = glyph + word.
   Tile colours only inside the app's sign tile. Everything else is grey with hairlines. (FAR-01, FAR-03, STA-01, ZEI-01)
2. **At most one lime primary action per view, at the bottom of the area it acts on** (D74), in the 56 px action zone,
   labelled verb + thing, and **last** in every action group (D83). (AKT-01, AKT-02, AKT-04, AKT-11)
3. **Deleting always asks** in a dialog; only destructive actions carry the 45° cut. (AKT-07, AKT-08, FOR-04)
4. **Layers are separated by a 2 px ink line**, never by a tinted ground or a shadow. (EBE-01, EBE-02)
5. **The current place is a 3 px cobalt line** plus weight/shape; app navigation shows icon + word. (NAV-01, NAV-02)
6. **Links**: word in text colour with a 2 px cobalt underline; external links end in the `external-link` icon. (LNK-01, LNK-02)
7. **Progress shows inside the primary action** (label + ink bar, then "✓ Angelegt", errors as a sentence); no spinner
   over the view, no toast for the result. (AKT-05, EBE-05)
8. **Motion** only in answer to an action: new content enters from below, 8 px in 200 ms; only a fade with reduced
   motion or the app setting „Bewegung immer reduzieren“. (BEW-01, BEW-02, BEW-04)
9. **Type**: sebaro Sans for everything, sebaro Mono (Medium 500, D70) only for code, IDs, versions; these are the only
   two families (D71). Code only in the five looks, no bold or italic (TXT-10, FAR-11). U+00A0 between number and unit,
   German thousands `10.000`. (SCH-01, SCH-03, TXT-04)
10. **Honest content**: no claim without proof; outflows stay visible; demo data is labelled „Beispieldaten“. (HAL-03, BEL-01, BEL-09)

Before you call a screen done, walk the checklist in [`templates/screen-checklist.md`](templates/screen-checklist.md).

## 3 Building a product with sebaro

1. Read `guide/RULES.md` (or filter `rules/rules.json` by `platforms`: `web`, `mobile`, `desktop`, `alle`).
2. Get the system files for your platform (§4). Never copy colour values; reference tokens (`var(--sb-color-*)`,
   `SebaroTheme`, `Color.sb*`).
3. Copy markup from `docs/bauteile.html` and screen recipes from `docs/app.html`, `docs/web.html`, `docs/desktop.html`.
   Their specimens use only `sb-*` classes from `docs/sebaro/css/sebaro.css`. Classes starting with `demo-` and `g-` are
   guide chrome; never ship them. Patterns marked „Vorschlag, noch nicht im System“ are not part of sebaro yet.
4. Pick the product's sign tile by product id; its colour appears nowhere else in the UI.
5. Light or dark per product kind (D75): websites have the labelled button „Hell oder Dunkel“ in the header; phone
   apps choose System, Hell or Dunkel in their settings; desktop apps in the menu „Darstellung“ and in the settings
   view (WEB-02, MOB-04, DSK-05). Desktop and windowed web apps: command palette on ⌘K / Ctrl+K (D84, NAV-09),
   sidebar and inspector can be hidden and the content keeps at least 480 px (D81, DSK-04). Plan every product for
   several languages: no string built into code, script messages by `lang` (D87, TEC-10).
6. Check both light and dark, 390 px and 1440 px, keyboard and screen reader basics, then the checklist.
7. When a rule does not fit your case, do not work around it silently: name the rule id and ask the owner.
8. Components that wait for the owner's choice (category and mark colours, warm palette, board, calendar, timeline,
   table sort and sum row, quote, audio, video, map, onboarding, about head, website patterns, charts beyond bars,
   iOS, the remaining desktop window questions) are sketched in the workshop but **not decided**. Do not build them
   as sebaro; if a product needs one now, ask the owner (see `docs/ausblick.html#entscheidung`).

## 4 Where the system files come from

sebaro's sources (palettes, contracts, generators, gates) live in the workshop repository **sebaroDesign**. This guide
never edits colours, fonts, icons or brand files by hand. `docs/sebaro/` is a **web export** made with sebaroDesign's
`tools/export_system.py`; `docs/sebaro/sebaro-export.json` lists every file with sha256, and
`docs/sebaro/GUIDE-SYNC.json` names the sebaroDesign commit.

| Target | How to get the files |
|---|---|
| Website, web app (plain CSS, Astro, React, Tailwind v4) | copy `docs/sebaro/` into your project as one folder, never edit inside it; wiring in `docs/sebaro/README.md` |
| Tauri / macOS / Android (Compose) | with a sebaroDesign checkout: `python3 tools/export_system.py sebaro --target tauri|macos|android --out <dir> --product <id>` then `--verify <dir>` |
| Packages (planned, D88) | private GitHub Packages built on a workshop version tag: `@grundhofer/sebaro` (npm, web and Tauri) and a Maven artifact for Android (Compose). The workflow is set up; no package is published yet. Until then use the export. |

Fonts are self-hosted (D18, D66, D68, D71): sebaro Sans + sebaro Mono, the only two families, as variable WOFF2 with
the key glyphs (⌘ ⇧ ⌥ ⌃ ↩ ⎋ ⌫ ⇥ ↑ ↓ ← →) included, for web and for Tauri on every platform (D77); OFL texts in
`docs/sebaro/fonts/web/`. Licence (D76): `LICENSE.md` here is byte-identical to `docs/sebaro/LICENSE.md` and to the
workshop's; ship it unchanged with every export (TEC-09).
Code highlighting (highlight.js, Prism, `sb-tok-*`) comes with `css/sebaro.css`; Shiki and CodeMirror see TEC-08.
No request may leave for a foreign server (no Google Fonts, no CDNs, no analytics).

## 5 Changing this guide

```sh
python3 tools/sync_from_design.py      # re-export sebaro from ../sebaroDesign (or $SEBARO_DESIGN) into docs/sebaro/
python3 tools/build.py                 # fill the marker blocks of all pages, write docs/rules.json, guide/RULES.md, docs/llms.txt
python3 tools/check_site.py --strict   # all groups (list below); exit 0 required
python3 tools/build.py --check         # freshness gate (CI runs this and check_site.py)
python3 tools/sync_from_design.py --verify-local   # docs/sebaro/ untouched since the export
npm ci && node tools/check_a11y.mjs    # axe WCAG 2.2 AA, overflow, console errors; light/dark, 390/1440 (CI runs it)
python3 tools/release.py 2.0.0         # turn "Unveröffentlicht" in CHANGELOG.md into a version + rules/releases/ snapshot
```

`check_site.py` groups: PAGE, LINK, NET, CSS, TOKEN (every `var(--sb-*)` exists in `tokens.css` / `sebaro.css`), STYLE,
SWATCH, LICENSE, TEXT, CHANGE, TERM, RULES; the docstring explains each.

**Automatic sync (D88, set up; runs from the next workshop push).** A workflow in sebaroDesign exports on every push
to its main branch, runs this repository's `sync_from_design.py` and `build.py`, and pushes a branch `sync/<short sha>`
when the guide is behind. `.github/workflows/sync-pr.yml` opens a pull request from it; `check.yml` runs on the push.
Nothing merges automatically; a newer sync closes the older PR. **Manual steps for the owner:** the SSH deploy key
with write access to this repository and the list of excluded products as secrets in sebaroDesign, and here the
setting "Allow GitHub Actions to create and approve pull requests". Until they exist the sync does not run; sync by
hand with `tools/sync_from_design.py`.

- **Every rule change is versioned (D88):** a new, changed or removed rule must be named under „Unveröffentlicht“ in
  `CHANGELOG.md` and get a newer `"changed"` date (a rule already dated on the day of the last release keeps that
  day), otherwise `check_site.py` (CHANGE) fails. Major = a rule is
  dropped or reversed, minor = new rules/values/pages, patch = wording and examples.
- **Accessibility exceptions** go into `tools/a11y-waivers.json` with page, axe rule, target and a reason; never a
  blanket waiver.
- **Guide chrome contracts** (classes in `docs/assets/guide.css`, never shipped):
  - `g-ex--dont` marks a deliberate "Nicht so" specimen (`<div class="g-ex g-ex--dont">` with `g-ex__label`,
    `g-ex__stage`, `g-ex__note`). Inside it, except label and note, `check_site.py` accepts colour literals and
    `box-shadow` in CSS rules whose every selector contains `.g-ex--dont` and in inline styles, and `check_a11y.mjs`
    skips only axe `color-contrast`. Every other check (names, roles, keyboard, links) still runs there.
  - `g-swatch` is a reference colour swatch (FAR-13, vorläufig), only on index, grundlagen and regeln:
    `<span class="g-swatch" role="img" aria-label="Farbfeld Lindgrün" style="--g-swatch-color: var(--sb-color-primary-action)"></span>`
    with visible text next to it that starts with „Farbfeld“. `check_site.py` (SWATCH) checks page, role and name.
  - `g-table-stack` on an `sb-table` inside `sb-table-wrap`: below 560 px of its own place (container query, not the
    screen) every row becomes a block; `th scope="row"` (else the first cell) is the title and every other cell shows
    its `data-label`. Give each `td` a `data-label` equal to its column header; `guide.js` adds missing table roles.
    The wrapper must take its width from its parent (not a shrink-to-fit grid or flex item).
  - Inline code in `main` breaks with `overflow-wrap: anywhere`; code blocks keep their lines.
- **Marker blocks nest:** `build.py` pairs `<!-- guide:x -->` / `<!-- /guide:x -->` with a stack and fills markers at
  any depth (e.g. `guide:tile` in a rule fragment). Use a `guide:tile` marker instead of pasting a tile SVG; an
  unclosed or crossed marker stops the build.

- **Never edit** `docs/sebaro/`, `docs/assets/vendor/`, `docs/rules.json`, `guide/RULES.md`, `docs/llms.txt`, or
  anything between `<!-- guide:… -->` and `<!-- /guide:… -->` markers. Change the source and rebuild.
- **Rules** change only in `rules/rules.json`; a rule's live example lives in `src/rule-examples/<RULE-ID>.html`
  (fragment with `g-examples` / `g-ex--do` / `g-ex--dont`). Never renumber ids; retire a rule by setting
  `"status": "offen"` with a `note`, or remove it with a changelog entry.
- A rule may only become **entschieden** with an owner decision (a D-row of type I). Agents add rules as
  **vorläufig** and say so.
- Guide chrome CSS (`docs/assets/*.css`) uses only `var(--sb-*)` tokens that exist: no colour literals, no shadows
  (checked; the only exception is inside `g-ex--dont`, see above).
- New pages start from `src/page-template.html` and must be added to `PAGES` in `tools/build.py`.
- Pages are German with „du“; agent documents (this file, `guide/`, code) are English (D2). The guide's own voice may
  say „unser“/„wir“ about sebaro (D85); product UIs never do.
- Preview locally: `python3 -m http.server -d docs 8000`; screenshots in both schemes before calling a page done.
- Public repository: never commit personal data, local paths, account names, e-mail addresses, session ids or the
  names of unreleased products (those go into the git-ignored `tools/sync.local.json`).

## 6 Known limits

The guide shows sebaro as built and checked in sebaroDesign; Chromium screenshots do not verify real Android/iOS
devices, Windows rendering, WebKit/Tauri webviews or screen readers. All example data on the pages is invented.
What waits for the owner (the round-6 sketch with 63 questions is private and never linked from here) is collected on
`docs/ausblick.html`.
