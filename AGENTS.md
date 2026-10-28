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
| the four platform pages at a glance, what differs per platform | `docs/plattformen.html` (the header entry „Plattformen“) |
| iOS (SwiftUI): what differs on the iPhone | `docs/ios.html`; the SwiftUI package comes with the workshop export (`--target ios`, §4), its spec is sebaroDesign `systems/sebaro/spec/12-platform-ios.md` (private) |
| why it is the way it is | `docs/gedanken.html` |
| what waits for the owner's choice, is open, comes later or is done | `docs/ausblick.html` |
| what changed between versions | [`CHANGELOG.md`](CHANGELOG.md) (every rule change by id) |
| starting a new project | [`templates/`](templates/README.md) |
| which rules agents miss when they build from the starters, and why | [`docs/agenten-test-2026-10.md`](docs/agenten-test-2026-10.md) (agent test of 2026-10, five products) |
| system files (CSS tokens, components, fonts, icons, tiles, scripts) | `docs/sebaro/`, a verified web export, see §4 |

Rule status: **entschieden** = owner decision, binding. **vorläufig** = an agent's decision, valid until the owner
changes it. **offen** = proposal only, do not build it as a rule. `D<n>` refers to row n of the decision log in the
workshop repository sebaroDesign (private; the guide covers D1–D110; D109 orders product adoptions and sets no rule). A rule id (e.g. `AKT-01`) is stable; cite it
in code reviews, commit messages and ADRs.

## 2 The ten rules most often broken

1. **One colour, one job.** Cobalt = current place, link, focus. Lime = the one primary action. Status = glyph + word.
   Tile colours only inside the app's sign tile. Everything else is grey with hairlines. (FAR-01, FAR-03, STA-01, ZEI-01)
2. **At most one lime primary action per view, at the bottom of the area it acts on** (D74), in the 56 px action zone,
   labelled verb + thing, and **last** in every action group (D83). (AKT-01, AKT-02, AKT-04, AKT-11)
3. **Deleting always asks** in a dialog; only destructive actions (and a final step that deletes nothing, D102) carry
   the 45° cut. (AKT-07, AKT-08, FOR-04)
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
An agent test of 2026-10 ([`docs/agenten-test-2026-10.md`](docs/agenten-test-2026-10.md)) found these missed in at
least four of the solutions a rule applied to: no `CHECKS.md` (TEC-06, 5 of 5), U+00A0 between number and unit
(TXT-04, part of rule 9, 4 of 5), toasts (EBE-05, part of rule 7, 4 of 4: three kept the starter's toast that says
nothing happened, one used a toast for removing a saved tag), the data-path line (BEL-10, 4 of 5: missing under
„Sichern“ in a dialog or under „Neue Notiz“ in a window) and the header (NAV-06, 4 of 4: the three web apps without a
window had no ⌘K palette, where the guide's own texts disagreed; for the club website it was the fixed header words).
The report's table lists the rules missed in two or three. Most came from the starters themselves; the READMEs of
`website-astro`, `webapp-vite` and `desktop-tauri` now list these gaps under „Lücken der Vorlage“.

## 3 Building a product with sebaro

1. Name the product kind (website, web app without a window, web app with a window or desktop app, phone app); the
   first item of [`templates/AGENTS-snippet.md`](templates/AGENTS-snippet.md) says where light/dark, language, tone
   and ⌘K go for each. Then read `guide/RULES.md` (or filter `rules/rules.json` by `platforms`: `web`, `mobile`,
   `desktop`, `alle`; `mobile` covers Android and iOS, rules only for iOS say „Nur iOS“ in their note). A web app
   without a window follows the `web` rules even when it is used mostly on phones.
2. Get the system files for your platform (§4). Never copy colour values; reference tokens (`var(--sb-color-*)`,
   `SebaroTheme`, `Color.sb*`).
3. Copy markup from `docs/bauteile.html` and screen recipes from `docs/app.html`, `docs/ios.html`, `docs/web.html`,
   `docs/desktop.html`.
   Their specimens use only `sb-*` classes from `docs/sebaro/css/sebaro.css`. Classes starting with `demo-` and `g-` are
   guide chrome; never ship them. Patterns marked „Vorschlag, noch nicht im System“ are not part of sebaro yet.
4. Pick the product's sign tile by product id; its colour appears nowhere else in the UI.
5. Light or dark per product kind (D75): websites have the labelled button „Hell oder Dunkel“ in the header; phone
   apps choose System, Hell or Dunkel in their settings; desktop apps in the menu „Darstellung“ and in the settings
   view (WEB-02, MOB-04, DSK-05). Desktop and windowed web apps: command palette on ⌘K / Ctrl+K (D84, NAV-09),
   sidebar and inspector can be hidden and the content keeps at least 480 px (D81, DSK-04). Plan every product for
   several languages: no string built into code, script messages by `lang` (D87, TEC-10). The second tone
   „Farbton: Kühl · Warm“ (D91, FAR-15): websites in the footer under „Darstellung“, apps next to light/dark in their
   settings (`js/sb-tone.js`; `theme-init.js` applies a stored tone). Websites print always light (`js/sb-print.js`,
   WEB-11).
6. Check both light and dark, 390 px and 1440 px, keyboard and screen reader basics, then the checklist.
7. When a rule does not fit your case, do not work around it silently: name the rule id and ask the owner.
8. The round-6 components are **decided and built** (owner's answers D91 to the 63 sketch questions); copy them, never
   rebuild them in a product:
   - colours: category `sb-category--1…6` (dot next to the word), mark `mark` / `sb-mark`, signed numbers `sb-signed`,
     warm tone `html[data-sb-tone="warm"]` with `js/sb-tone.js` (FAR-12, FAR-14, FAR-15);
   - data: board `sb-board` + `js/sb-board.js`, sticky group head `sb-list-header--sticky` + `js/sb-sticky.js`,
     timeline `sb-timeline`, table sort `sb-table__sort` + `js/sb-table.js` and the sum row in `tfoot`, calendar
     `sb-calendar` + `js/sb-calendar.js`, menu path `sb-breadcrumb--path`, rating `sb-rating`, diff `sb-diff`, place
     with a small static map (DAT-09, DAT-13 to DAT-17, TXT-11, TXT-16);
   - charts: `sb-chart` + `js/sb-chart.js` (text as HTML, grey line with the now in cobalt, sparkline after the number,
     labelled share rows, dense histogram, heatmap with classed scales, diverging, goal ring, legend above), scales
     `--sb-dataviz-sequential-1…4` and `--sb-dataviz-diverging-1…5` (DAT-04, DAT-10 to DAT-12);
   - text and media: quote `sb-quote` (and `.sb-prose > blockquote`), intro step, about head, audio `sb-audio` and video
     with poster via `js/sb-media.js` (TXT-17, STR-03, ZEI-13, BIL-06, BIL-07);
   - website patterns: form result `sb-form-result` (+ optional `js/sb-form.js`), page numbers `sb-pagination`, FAQ
     `sb-faq`, docs groups `sb-toc__group`, screenshots `sb-shots`, one share image per page, language switch to the
     same page or none, print always light `js/sb-print.js` (WEB-04 to WEB-11);
   - states: count partial states („2 offen“), never „teils offen“ (STA-09); the sheet is at most 560 px wide from
     640 px (EBE-04);
   - iOS: SwiftUI package (own bottom bar, system navigation bar, no row swipe, own delete dialog, form sheet with
     „Sichern“ at the bottom, `SbHaptics`, Dynamic Type without a cap) (MOB-05 to MOB-08);
   - desktop windows: title bar per system, small windows, draggable dividers, „Menü“ key with submenus, 15 fixed
     shortcuts (14 of D91, Zurück / Vor of D102), F6, document tabs, drop target, several windows, notifications, update word, window ground, compact
     inspector (DSK-06 to DSK-15).

   Settled by the owner with D92 (2026-10-21): „Konflikt“ always carries the warning glyph, in rows, trees and the
   timeline (STA-08, DAT-15); the heatmap „heute“ is a cobalt frame on the cell, rounded like it, while focus
   stays the square 2 px ring with a 2 px gap outside (cells 6 px apart, legend „Rahmen: heute“); the scale
   thresholds stand, sequential at most 4 steps and diverging 5 (DAT-11, entschieden; sebaro's palette names both limits as
   `dataviz.maxClasses`, PALETTE-CONTRACT 2.6, and `check_palette.py` checks them); the licence reading (TEC-09); FAR-13; sortable tables scroll sideways
   inside their `sb-table-wrap` on phones, never the page, and never stack (DAT-14); the `pin` and `star` icons and
   the five D86 sign near cases (DAT-09, DAT-17, ZEI-12). The marking of generated images stays open until the first
   product publication with generated images, then a legal check (BIL-04, vorläufig).
   Settled by the owner with D93 (2026-10-21): the heatmap „heute“ frame is 4 px `accent` (border-width-strong +
   hairline) on the cell's edge with a 1 px `bg` joint inside before the fill, so it has ≥ 3 : 1 on every class
   (the D92 frame directly on the fill had 1.1–2.4 : 1); `sebaro.css` draws it, never write your own (DAT-11). The
   D75 reading is confirmed: phone apps choose light or dark in settings, desktop apps in the menu „Darstellung“ and
   in settings (AKT-09, MOB-04, DSK-05); ⌘K / Ctrl+K in every app is confirmed (D84, NAV-09). The brand figure is
   only ever an image (website, about page, introduction, communication), never a control, icon, app sign, favicon,
   wordmark substitute or empty-state picture (BIL-05).
   Settled by the owner with D94 (2026-10-21): the six agent additions to D91 stand as built: pane widths „Schmal ·
   Normal · Breit“ in the menu „Darstellung“ (DSK-07), sort heads 48 px on pages and phones, 32 px only in windows and
   48 px there under touch (DAT-14), the narrow board's bar „Spalte 2 von 3: …“ with step buttons and the column in the
   primary action (DAT-13), the poster sentence for screen readers only (BIL-07), the docs nav with „Übersicht“ first,
   page counts and the current group open (WEB-07), the pointer-only tab cross with Entf / ⌘W (DSK-10). For now there
   is **no brand figure** (BIL-05): the brand comes from type, colour and app signs; D90 still allows one within the
   D93 limits, but only with a new decision row, so never generate or show one.
   Settled by the owner with D95 (2026-10-22), menus in a changed or narrow window (`sb-menu.js`, `sb-window.js`,
   synced from workshop `90843c8`): an open menu closes with every level when the window's **width** changes or its
   button („Menü“) scrolls out of view, focus back on the button if it was in the menu; a height-only change (address
   bar, on-screen keyboard) does not close it; F10 / a lone Alt open the window menu only while „Menü“ is in view
   (EBE-07, DSK-08). „Schmal · Normal · Breit“ for a pane that is an overlay in a too narrow window only stores the
   width: the pane stays closed, focus goes back to „Menü“ (DSK-07); a menu command that opens a pane never moves focus
   into it, and Escape on „Menü“ closes such an overlay (DSK-04; the Escape part is a workshop addition from the review).
   Submenus open beside their parent (the top menu's on the reading side, else the other; deeper ones keep their
   parent's direction); where no side has room the submenu **replaces its parent in place** (same edge and width, the
   parent hidden under it, `data-sb-replaced`) with the back row „‹ <parent>“ first (`li.sb-menu__back-row >
   button.sb-menu__back[role="menuitem"]`, accessible name „Zurück zu <parent>“ / „Back to <parent>“ from the script's
   message table); the back row, ← and Escape go back one level. No level covers items of another level any more; this
   replaces the D94 overlap. Every menu and submenu needs a name (`aria-label`). Never build your own submenu
   placement. D95 decided this part of the menu pattern; D98 confirmed the rest (EBE-07 is entschieden).
   In the same workshop round, without a new decision: `tokens.css` ends with a generated `@media print` block with
   the light values (TOKEN-CONTRACT 1.9), so pages print light without scripts too; keep loading `sb-print.js` (it opens
   closed answers; its theme half was removed in workshop `68ba334`, after a print check in Chromium) (WEB-11). The studio share
   image has a light ground (WEB-09). Compose caught up: `SbStatus(…, glyph = SbStatusGlyph.Warning)` for „Konflikt“,
   `SbStatusGlyph.Pending` in the neutral tone for a „2 offen“ that only informs (STA-01, STA-09), `SbToneChoice` and
   `SbMotionSetting` with `SebaroAppTheme(mode, reduceMotion, tone)` (MOB-01, MOB-04, BEW-04), the wrappers' words from
   `SbMessages` (build an app table with `SbMessages.De.copy(…)`); all compiled, none rendered. The inspector overlay
   below 1004 px is 280 px wide again (it was 34 px).
   Settled by the owner with D96 (2026-10-23, synced from workshop `2b1003b`): (a) share images are rendered **in
   each website's own build** (WEB-09): the site writes a page list from its own pages (title, path, reading time,
   date; format `docs/sebaro/brand/og/pages.schema.json`) and runs the exported
   `node sebaro/brand/og/render.mjs --pages og-pages.json --out public/og --head build/og-head`, then puts each
   `<page>.head.html` into that page's head (it still writes `<title>` itself). The image title is the page's `<title>` without its suffix, or its `<h1>` where `<title>` is only the navigation word (D97, as this guide does); if it does not fit in three lines, shorten the page's heading, never only the image's. The look comes from the one template
   `brand/og/template.html`; never copy, fill or edit it yourself. The script fails loud (exit 1, page id named, no
   image and no head for that page): a title over three lines or a word wider than its line (shorten the page's
   title, never cut it or set it smaller in the image), a character sebaro Sans lacks, a ground that is not
   `color.bg` light; exit 2 for a list that breaks the schema or a missing export file. It needs Node 20+ and
   Playwright with Chromium. The workshop's own images (`brand/src/og/`) stay samples and its test case. (b) CI
   checks in Chromium only; WebKit and Firefox come only with a new decision row. (c) No new decision: Tauri loads
   sebaro Sans and Mono as WOFF2 on every platform since D77; only the look on Windows (WebView2) and Linux
   (WebKitGTK) is checked later.
   Settled by the owner with D98 (2026-10-23, synced from workshop `47b42db`): 70 of the 73 vorläufig rules are
   entschieden, ten after a question each (V1–V10) and 59 as a package, as built. The answers that changed a text:
   groups of people get a neutral word („Teilnehmende“, „Mitglieder“), else both forms („Nutzerinnen und Nutzer“),
   never a sign inside the word (gender star, colon, underscore, middle dot, Binnen-I; Amtliches Regelwerk, version of
   1 July 2024), checked by `TXT8` of the workshop's `check_demo.py` (TXT-05); a website footer always has
   „Impressum“, „Datenschutz“ and „Barrierefreiheit“, „GitHub“ only when the product has a public repository (this
   guide keeps it, its code is public) (WEB-03); with required fields empty the primary action stays enabled, its press
   says „<Beschriftung> fehlt.“ at each and moves focus to the first; `sb-form.js` does this for `required` fields,
   Compose and SwiftUI have no helper for it (STA-03); in a tree arrows only move focus, Enter, Space or a click opens
   (NAV-11); no numbers on sidebar, tabs or bottom navigation, only in the list head and the state sentence (HAL-05,
   DAT-01); the data-path line under every action, also „Bleibt auf diesem Gerät.“ (BEL-10); evidence is optional but
   generated when shown (BEL-06); the first screen of an app website has only heading, sentence and primary action,
   screenshots below (BIL-02); a sketch page shows at least two ways per question (HAL-08); the iOS form sheet is the
   one exception to pickers-only sheets (EBE-04, MOB-07). Confirmed as written: a tap on Android is the short grey
   fill, no ripple (FAR-08), and generated images stay fineliner without colour (BIL-03).
   Settled by the owner with D99 (2026-10-24, synced from workshop `f8bdbee`), the answers to the four workshop
   questions: at large text the room grows and the text wraps at spaces onto two lines; only a single word that alone
   does not fit its line is hyphenated, nothing is cut (bottom navigation, segments, steps, toast, title); a segmented
   control whose words still do not fit becomes a select; Compose charts grow only where text sits, areas, gaps and
   lines stay fixed dp (ZUG-09, new; DAT-04). Voluntary fields carry a grey „(optional)“ after their label, never an
   asterisk (so no „Pflichtfeld“ legend either; that wording, and no „(Pflicht)“ or „freiwillig“, is the workshop's
   spec/07 §3 rule 12, written after D99): on the web `Notiz <span class="sb-optional">(optional)</span>` in the label,
   Compose `SbTextField(…, optional = true)` and `SbSelectField(…, optional = true)`, Swift `SbTextField(…, optional:
   true)` (EIN-01, STA-03). Provisional agent choices, not D99: the page writes the suffix itself (no script adds it),
   a field that always holds a value carries none, a select is voluntary only with „Keine“ among its options. Android
   dialogs dim with the palette scrim (light 32 %), never the system dim (EBE-03). As built: the Compose select opens
   in the sebaro menu with checks, ← → choose in a segmented row and ↑ ↓ leave it (EIN-04, EIN-05); the phone heatmap
   has one Tab stop per day, a tap shows the value without a focus ring, arrows lead out at the edge, cells stay about
   30 dp, and „Tipp auf einen Tag, um seinen Wert zu sehen.“ / „Tap a day to see its value.“ stands under it (DAT-11);
   English chart words stay and dates follow the language („from 28 Sep“, TXT-04). On the web `sebaro.css` does the
   large-text part itself for the header (below 640 px a wrapping row), toast, steps, segments and bottom navigation;
   the web segmented control does **not** become a select yet (its words wrap and hyphenate), and in the workshop
   `web.html`, `article.html` and `facts.html` still scroll sideways at 200 % on 360 px. In the same sync, without a
   new decision: the progress ring's value is HTML text after the SVG (`<span class="sb-progress-ring__text"
   aria-hidden="true">60&nbsp;%</span>`) and the ring grows with it and the text; the value as SVG `<text>` is a
   deprecated alias (STA-06).
   Settled by the owner with D100 and D101 (2026-10-24, synced from workshop `0f40a10`), the two open questions and
   the build's follow-up questions: at large text a step indicator (2 to 4 steps) whose word does not fit its column on
   two lines, hyphen included, keeps every bar and check and shows only the current step's word on its own line under
   them, start-aligned; „Schritt 2 von 4“ stays (STA-06; each word in `span.sb-progress__word`). novalis takes sebaro's
   240 px sidebar at adoption (NAV-04, D89). On the web too a segmented control whose word does not fit becomes a select
   (`js/sb-fit.js`; the radios stay the form value; EIN-04, EIN-05). The three „(optional)“ details are decided, no
   longer provisional: the page writes the suffix itself, a field that always holds a value carries none, a select is
   voluntary only with „Keine“ among its options (EIN-01, STA-03). No page scrolls sideways at large text: long words and
   code wrap, wide specimens and tables scroll in their own frame; only a word that alone does not fit its line gets a
   hyphen (`span.sb-hyphenate` from `sb-fit.js`), names and code break at the line end without one, code in headings
   too (ZUG-09, SCH-06, TXT-15). File names are `<code class="sb-file-name">` with `<wbr>` after - . _ / and break only
   there, a part that alone does not fit its line also inside (D100 (6)); identifiers (`sb-id`, D80) never break. The facts line becomes a list once a cell no longer fits one line
   (ZEI-13); a chart with several series shows its legend, also for two, once the names cannot stand at their line
   ends, and the ends keep only their last value (DAT-10). TalkBack reads Compose text completely (`SbWrapText` is a
   normal `BasicText`, D100 (7)). Compose now has `SbSortableTable` (sorts like `sb-table.js`, scrolls in its own frame,
   „Sortiert nach <Spalte>, absteigend“; DAT-14) and `SbIntroStep` (as the web's intro step; STR-03); with them every
   new D91 component and every chart has its Compose wrapper; inline code and keys still have none (the workshop names
   them as open), and the sheet width from 640 dp is not built in Compose (`docs/app.html`). A deliberate
   ellipsis (window rows, the window path, document tabs, D67 (2)) carries `data-sb-truncate`. The workshop's
   `check_demo.py` 1.4.0 checks it on every page: `OVF3` (page width at 200 % text on 320, 360 and 390 px, light and dark)
   and `OVF4` (text cut by a frame). Provisional agent choices, named as such in the rules: the 4 px hysteresis of the
   select, `translate="no"` as the mark of a name, 12 px between facts list entries, the last step's word once all are
   done, the API names of `SbSortableTable`. After D101 no question waited for the owner's choice (a „vorläufig“ rule is never an
   entry on `docs/ausblick.html#entscheidung`). Only three rules stay vorläufig, by D98: BIL-04 and ZUG-07 until
   a legal check before the first publication of a product (the marking of generated images, the accessibility
   statement), DSK-01 until a run in a real Tauri webview with novalis (D89); never present them as decided. Compose is
   rendered on the JVM with the workshop's render tool (`extract_compose.py --render`) and probed in the semantics tree,
   not on a device and not with TalkBack itself; audio row and video are stateless, the app binds its own player.
   Nothing of this is tested on real Android or iOS devices, with TalkBack or VoiceOver, in WebKit, Firefox or real
   Tauri windows; `OVF4` does not see text inside an input or select. See `docs/ausblick.html#offen`.
   Settled by the owner with D102, D103 and D104 (2026-10-25, synced from workshop `68ba334`), the 52 questions from
   the first adoptions (novalis, RetroBeam) and the 45 after them, all as proposed. Windows (D102 (1)–(17)): a grey
   counter line before the state sentence, a failed command's sentence in the action zone (STA-07); changed and pinned
   document tabs, reordering also without a pointer, tabs that never shrink below their name (up to 15 rem), ⌫ alone
   never closes (DSK-10); an app's own menu items in one fixed group, „Farbton ›“ after „Hell oder Dunkel ›“, items
   without a target disabled, the native context menu on macOS (DSK-08, AKT-10); 15 fixed shortcuts with Zurück / Vor
   on ⌘← / ⌘→, the table means characters, ⌘+ / ⌘− change only the content in a desktop app (DSK-09). Texts (D102
   (18)–(25)): the copy toast without „Rückgängig“ (EBE-05), „In den Papierkorb legen …“ with a trash (AKT-08), German
   words with a product glossary as the only exception (TXT-01), „Details“ under an error sentence (TXT-07), „Weiter:
   <Ziel>“ allowed in every fixed flow (AKT-04), no emoji in interface text and a calm remaining time (HAL-05). Patterns: only
   virtualised lists or tables of fixed row height cut names (`data-sb-truncate`, D102 (35), TXT-09); a final step
   that deletes nothing asks and carries the 45° cut without the trash icon (FOR-04, AKT-07); the board's column action
   and least column width (DAT-13). Web apps without a window: header without the four words with „Einstellungen“,
   footer without „Darstellung“, DE / EN as a choice, one share image for access links, „GitHub“ required under the AGPL,
   the hand-written data-path hint (NAV-06, WEB-03, WEB-09, WEB-10, BEL-10); the fade under reduced motion is 200 ms
   under both settings (BEW-04). Also from D102: `data-sb-start="nostore"` for a product that stores nothing (STR-01),
   callout actions with „Ausblenden“ (STA-05), the contents over a reader and a jump target's place line (NAV-08), the
   ellipsis „…“ after a space, „Suchen …“ (TXT-05). D104 also decided the search in the palette's frame, the find bar, the reader, the
   collaboration patterns (votes, hidden cards, free canvas, pointers, invite and wheel dialogs), chips at 32 px in a
   window, weekday heads with two letters where every second one leaves the view (DAT-11, DAT-16), icons that stay fixed
   while text grows (ICO-04), group-head tools in the sidebar (NAV-04), the editor's means (DSK-03, TEC-08) and phone
   notifications (new MOB-09). **D103 is a priority for future decisions:** where accessibility stands against another
   goal it loses, and the proposal is the simpler form or the one that serves the other goal (D104 (0)); the existing
   ZUG rules, D93 and D99–D102 stay (ZUG-01, the area intro of „Zugang“).
   Settled by the owner with D105 (2026-10-26, synced from workshop `ef6121d`), the 46 questions after D104, all as
   proposed and built: the second icon sheet (`eye-off`, `eye` before „Vorschau“, `quote`, `exercise`, filled
   `repeat` / `timer`, the dot `changed--16` on a changed document tab, DSK-10); the wheel turns at most 200 ms (BEW-01);
   private notifications carry only their title, everywhere (MOB-09); an own recording row, stepper and half-hour
   time sheet, Compose only (BIL-06, new EIN-06); editor line numbers without a thousands separator (TXT-04); a phone
   editor shows „Sichern“ only while something is unsaved (AKT-01, NAV-05), sets every file in sebaro Mono on
   Android's EditText, emphasis 600 where Markdown is in sebaro Sans (DSK-03); the dialog before closing with unsaved
   changes, a neutral confirm when nothing is lost, removing an entry from an unsaved form with an undo toast (AKT-11,
   AKT-08, EBE-05); „Keine Werbe-SDKs · Keine Werbe-ID“ (BEL-01); an instant result without check or pulse, haptics
   switchable by the app (AKT-05, MOB-03); shake only as an extra way (new MOB-10); no text on a picture (FAR-02); a
   countdown without a ring (HAL-05); no own spots (DAT-07, ICO-07); an app's own state words with the fixed glyphs
   (STA-02); the data-path hint of a menu row's action in its dialog (BEL-10); the value tile of a die and the
   „erwartet“ line, Compose only (DAT-03, DAT-12); „Einstellungen“ in a sidebar foot that never scrolls (NAV-04).
   D106 (the same day, 24 questions after the D105 build, all as proposed) settles five provisional points of that
   build: „Abbrechen“ · „Verwerfen“ · „Sichern“ (AKT-11), check and cross on the die (DAT-03), the „erwartet“ line
   with a `bg` joint (DAT-12), „Ohne Werbung“, „werbefrei“ and „ad-free“ on no surface at all (BEL-01), the grey
   markers show emphasis in the phone's Mono editor (DSK-03).
   Built with the rest of D106 and settled by D107 (2026-10-26, synced from workshop `3829e6f`, export tool 1.9.0):
   the 19 icons of the D105 sheet are released as drawn (`shake`, the filled `dice` and the others; no draft is left
   in the set, each has an Android drawable `ic_sb_<name>_24`; ICO-05, MOB-10). Android home-screen widgets (new
   MOB-11): bg with the 2 dp ink line, corners 16 dp, small 2 × 1 (number, unit, sentence) and medium 4 × 2 (title,
   number, sentence, at most three rows), sebaro Sans through RemoteViews XML layouts without Glance (D107 (3); an app
   with Glance places them with `AndroidRemoteViews`), the whole widget one key that opens the app (D107 (4)),
   pressed-fill, text up to 125 % and then the sentence or the list goes; the layouts ship in the Android export's
   `res/` with `SbWidget.kt`, which fits the content to the launcher's cell (provisional). Camera and image patterns
   (new MOB-12, BIL-08), Compose only, no camera library: the viewfinder with the primary action „Seite aufnehmen“,
   camera and full-screen page view always dark (`SbDarkArea`, D107 (6)), corners with 48 dp handles and a way without
   dragging, the page view as the D104 reader, a capture confirmed by count and small picture (the small pictures only
   to look at, D107 (7)), a live frame that jumps (the app sends at most five outlines a second, D107 (5)), filters as
   three words, the user's photos as they are and marks on them in accent on a bg seam. Four more Android apps have
   signs in the workshop's registry (D106 (1)–(4)); the guide never shows a sign of an unreleased app, and the
   registry writes a name as the app does (D107 (2); ZEI-08). No question waits for the owner (the workshop's
   SYSTEM.md §5 has none open). Nothing of D106 is checked on a device, in a launcher, with a real camera or with
   TalkBack. Since 2.14.0 the new patterns of D102 to D108 are components of their own on `docs/bauteile.html`
   (dialogs, toasts, callout actions, footnotes, the web app without a window, the group „Zusammenarbeit“) and
   `docs/desktop.html` (sidebar foot, tab marks, find bar, reader, full-text search, start error and more),
   copied from the workshop's demo pages; Compose-only parts are named, not drawn.
   Settled by the owner with D108 (2026-10-27, synced from workshop `2b067c4`, export tool 1.11.0), six questions from
   the new gaps of novalis and this guide, all as proposed: in a window's sidebar a row's status that does not fit
   beside the name goes with glyph and word under the name, in the name's column (twist, icon and check hang in the
   row's start padding, `--sb-row-lead`; a part before the name that sebaro does not know adds its width there,
   provisional), nothing is cut and the sidebar never scrolls sideways; in 240 px at 200 % a status word wider than the
   column („gesichert“) breaks inside itself without a hyphen, the workshop's recorded price (NAV-04, ZUG-09); with no
   folder or collection open the sidebar stays with only its foot „Einstellungen“, its scroll area empty (NAV-04); a
   Tauri app names its languages in `src-tauri/Info.plist` (`CFBundleLocalizations`, DSK-08); the pinned tab stays at
   the start of a scrolling tab row (`position: sticky`, DSK-10); the counter line keeps its place when a view has
   nothing to count, holding the last document's parts invisibly with `data-sb-held` (provisional), so the zone and the
   primary action never jump (STA-07, AKT-01); the editor size keeps multiplying with the system text size (DSK-03).
   In the same workshop round, without a new decision (existing rules decide; choices without a rule provisional):
   a chord that is also a native menu accelerator counts as the menu command and moves no focus (per D103, provisional;
   the workshop asked the guide to write it into DSK-04); after 10 s the longer loading sentence replaces the words in the
   same `sb-loading` line (STA-06, provisional); „Das hat nicht geklappt. <Was sicher ist>. Versuch es noch einmal.“
   for an error whose action is unknown, and a start error without the window frame (`sb-start-error`, TXT-07,
   provisional); a footnote cited twice has one back link per citation („1“, „1b“), the digit focuses the note unless
   the footnote popover takes the press (`sb-notes.js`, BEL-02, provisional); the action zone's message is
   always a `<div>`; the editor themes ship in every web and tauri export as `editor/sebaro-shiki.json` and
   `editor/sebaro-codemirror.ts` (TEC-08); every export carries `checks/verify-export.mjs` (Node 20+) to check itself
   without the workshop (TEC-09). No question waits for the owner (the workshop's SYSTEM.md §5 has none open). None of
   D108 is checked in WebKit or a real Tauri window, the footnote focus not with a screen reader.
   Settled by the owner with D110 (2026-10-28, synced from workshop `fc2e7f2`): a value that does not fit a one-line
   field of a dialog at 200 % text on a narrow phone runs on sideways inside the field, as in every text field, the
   caret showing the place; the dialog does not grow for it and the field does not become multi-line (EIN-01, EBE-03).
   The workshop's demo check 1.9.0 counts such a value in an `OVF5` info line; a placeholder, a read-only field (unless it is being sent, marked
   `aria-busy="true"` on the field or its form) and a field outside a dialog still warn (provisional, workshop: D110 names only the dialog). In the same round, without a
   new decision: a static specimen of a run-time alert (the dialog's failure, the start error, `sb-fatal`) uses
   `role="note"`, while the product's `<div class="sb-dialog__message" role="alert">` starts empty and is collapsed by
   `:empty`, not `hidden`; an input dialog that sends keeps its entry `readonly` with `aria-busy="true"` on its form (on
   the field where there is no form); `.sb-completion[hidden]` and `.sb-completion__empty[hidden]` close the list with
   `hidden` alone, so `docs/assets/desktop.js` no longer sets `display` through the CSSOM. D110 is not checked on a
   real phone or with a screen reader.

## 4 Where the system files come from

sebaro's sources (palettes, contracts, generators, gates) live in the workshop repository **sebaroDesign**. This guide
never edits colours, fonts, icons or brand files by hand. `docs/sebaro/` is a **web export** made with sebaroDesign's
`tools/export_system.py`; `docs/sebaro/sebaro-export.json` lists every file with sha256, and
`docs/GUIDE-SYNC.json` (outside the folder, so `docs/sebaro/` is the export and nothing else) names the sebaroDesign
commit.

| Target | How to get the files |
|---|---|
| Website, web app (plain CSS, Astro, React, Tailwind v4) | copy `docs/sebaro/` into your project as one folder, never edit inside it; wiring in `docs/sebaro/README.md`; check the copy with `node sebaro/checks/verify-export.mjs --strict` |
| Tauri / macOS / Android (Compose) / iOS (SwiftUI) | with a sebaroDesign checkout: `python3 tools/export_system.py sebaro --target tauri|macos|android|ios --out <dir> --product <id>` then `--verify <dir>` |
| Packages (planned, D88) | private GitHub Packages built on a workshop version tag: `@grundhofer/sebaro` (npm, web and Tauri) and a Maven artifact for Android (Compose). Their version follows the token contract, now 1.10 (since 2026-10-25), so `1.10.x`; the first is `1.10.0` (1.9 was never published). The workflow is set up; no package is published yet (the workshop CI is blocked; a self-hosted runner comes later, D95). Until then use the export. |

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
npm ci && node tools/check_a11y.mjs    # axe WCAG 2.2 AA, overflow, console errors; light/dark, 390/1440; 200 % text at 1024/1280 (CI runs it)
node tools/og.mjs                      # share images (D96): render src/og/pages.json to docs/og/ + src/og/head/, then build.py
node tools/og.mjs --check --png-bytes  # fresh render equals the committed snippets and PNGs (CI runs it without --png-bytes)
python3 tools/sync_from_design.py --check          # docs/sebaro/ equals a fresh export of the workshop commit
# with a sebaroDesign checkout, its demo check on every page, run from there (absolute page path):
#   python3 tools/check_demo.py <abs path>/docs/<page>.html --page web --skip content --no-write
python3 tools/release.py 2.15.1        # turn "Unveröffentlicht" in CHANGELOG.md into a version + rules/releases/ snapshot (2.15.0 is the last release)
```

The workshop's demo check (1.8.0) measures one- and two-character text on screen pixels; on `regeln.html` it reports
the deliberately unreadable cells of the „Nicht so“ specimens inside `g-ex--dont` (DAT-11's heatmap, one pill, since 2.13.1 FAR-02's title on a picture) as CTR1
errors, which it cannot tell from real faults. Run `regeln.html` also with `--skip contrast` (a documented group of the
tool; axe still checks contrast) and say so; every other page runs without it.
Two limits of that command on guide pages: the colour group (COL1–COL4) never runs here, because the tool loads
`assets/sb-colour-count.js` next to the page and the guide ships that script at `docs/assets/vendor/` (the report
says „colour skipped“; the tool has no option for another path, so this is a workshop request, never a local
workaround in `docs/`; run on a scratch copy with the script placed there, it flags only the deliberate „Nicht so“
view `TEC-03-bad` on `regeln.html`); and a single file gets the warm tone only with `--tones warm`, so run every
page a second time with `--tones warm` (and `regeln.html` again with `--skip content,contrast`). Say both in your
report. `--skip content` also skips `TXT8` (a sign inside a word for people, D98, TXT-05), so grep the German copy
yourself: `grep -nE '[a-zäöüß][*∗:_·][iI]n|[a-zäöüß]In(nen)?([^a-zA-Zäöüß]|$)' docs/*.html src/rule-examples/*.html`
and look at every hit (code such as `:invalid` and names such as `LinkedIn` hit too; it also finds the singular
Binnen-I after endings `TXT8` does not know, see the note of TXT-05); the guide's own copy has none, also not in its
„Nicht so“ examples.
Since 1.4.0 the same command loads every page once more at 200 % text on 320, 360 and 390 px (in the 390 px run of each
scheme, Chromium's `Page.setFontSizes`; `--large-text` names other widths) and reports `OVF3` (the page is wider than
the screen) and `OVF4` (a frame with `overflow: hidden` or `clip` cuts a text; exempt are a scroll container on the
way and an ellipsis that is both `text-overflow: ellipsis` and marked `data-sb-truncate`). Every guide page passes
both, in light and dark (the warm-tone runs of `--tones warm` check axe, contrast and colour, not the 200 % pass);
never weaken them with a local workaround. To see real 200 % text yourself, set
the font sizes with CDP before `goto` and take viewport screenshots after scrolling (full-page screenshots lose the
setting). `OVF4` does not see text inside an input or a select (since 1.5.0 `OVF5` warns about field text wider than
its field). Since 1.6.0 `OVF6` also reports a word broken inside itself where it would fit its line or the part that
squeezes it (at 100 % and in the 200 % pass); every guide page passes it too. Since 1.8.0 a part narrow on purpose
carries `data-sb-narrow-ok`: its squeezed words are counted in one info line instead of reported, an unneeded break
stays an error (`docs/ausblick.html#p-w-ovf6-schmal`); the narrow columns of SCH-06, TXT-15 and the data page carry it
and are narrow on every screen. Use it only where the narrowness is the content. `build.py` renders file names and
markup fragments of rule texts as code (`code.sb-file-name` with `<wbr>`, never before an extension of one to four
letters or digits, as the workshop's `sbExtensionDot`), so `sb-fit.js` never hyphenates them; hand-written file names
on the pages follow the same rule.

`check_site.py` groups: PAGE, LINK, NET, CSS, TOKEN (every `var(--sb-*)` exists in `tokens.css` / `sebaro.css`), STYLE,
SWATCH, LICENSE, TEXT, CHANGE, OG, TERM, RULES; the docstring explains each.

**The guide's own share images (D96 (a), WEB-09).** The guide follows its own rule like any sebaro website:
`build.py` writes the page list `src/og/pages.json` from the pages themselves (file, `<h1>` as title, meta
description; product `studio`, so the large lockup; no page states a breadcrumb, reading time or date, so every image
takes the start form, title and host). `node tools/og.mjs` runs the exported `docs/sebaro/brand/og/render.mjs` on it
into a temporary folder and, only if every page passes, replaces `docs/og/<page>.png` and `src/og/head/` (snippets,
`head.json`, `inputs.json` with the sha256 of every input). `build.py` then copies each snippet into the page's
`<!-- guide:og page="<page>" -->` block, without its meta description (the page writes its own). Order after a
change of an `<h1>`, a description, a page or a synced export: `build.py`, `og.mjs`, `build.py`. A title that does not
fit fails the render: shorten the page's `<h1>`. The footer says „online unter grundhofer.github.io/sebaro-guide“,
because the image ends with the host and may show no text the page lacks. What is checked where: `build.py --check`
(page list and head blocks fresh), `check_site.py` OG (one canonical and each og tag per page, absolute under the
site address, og:title = `<h1>`, og:description = meta description; every `docs/og/` PNG present, 1200 × 630, RGB
without alpha, ground = `color.bg` light; a warning when an input changed since the render, an error under
`--strict`), `og.mjs --check` (CI, Linux: a fresh render passes render.mjs' own checks and writes the same snippets
byte for byte; `inputs.json` and the PNG bytes are only reported, because a synced token or font may change no
snippet and Linux draws the fonts with other pixels: a sync PR stays green and shows the check_site.py OG warning;
locally add `--png-bytes`). CI never renders or commits images: render on your machine and commit `docs/og/` and `src/og/`.

**Automatic sync (D88, set up; runs once the workshop CI runs).** A workflow in sebaroDesign exports the commit of every
successful gate run on its main branch (its one gate list is `tools/gates.sh` there; since 2026-10-22 the sync waits for
it instead of running beside it), runs this repository's `sync_from_design.py` and `build.py`, and pushes a branch `sync/<short sha>`
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
  - `g-swatch` is a reference colour swatch (FAR-13, entschieden with D92), only on index, grundlagen and regeln:
    `<span class="g-swatch" role="img" aria-label="Farbfeld Lindgrün" style="--g-swatch-color: var(--sb-color-primary-action)"></span>`
    with visible text next to it that starts with „Farbfeld“. `check_site.py` (SWATCH) checks page, role and name.
  - `g-table-stack` on an `sb-table` inside `sb-table-wrap`: below 560 px of its own place (container query, not the
    screen) every row becomes a block; `th scope="row"` (else the first cell) is the title and every other cell shows
    its `data-label`. Give each `td` a `data-label` equal to its column header; `guide.js` adds missing table roles.
    The wrapper must take its width from its parent (not a shrink-to-fit grid or flex item). Never on a sortable
    table (DAT-14, D92 (7): it scrolls sideways inside its `sb-table-wrap`) and never in markup meant to be copied.
    With `g-table-stack--large-text` (rule examples, 2.13.1, provisional) the wrapper is a container only while the
    text is large (a screen of fewer than 20rem, or 1024 px and more with less than 64rem), so at 100 % the table
    keeps its columns.
  - Inline code in `main` breaks with `overflow-wrap: anywhere`, except a file name (`code.sb-file-name`, `<wbr>` after
    - . _ / but not before a short extension, D101 (6); the extension rule is provisional, workshop `ef6121d`) and an identifier (`sb-id`, D80); code blocks keep their lines.
  - Large text (D100 (5), ZUG-09): grids and lists in guide CSS take `minmax(0, 1fr)` or `min-inline-size: 0`, so a
    long word never sets their width; a rule's head puts title and status under the id from 24rem down (a media query's
    rem follows the reader's text size); a `g-ex__stage` is positioned, and a word in it breaks only where it alone does
    not fit its line (sebaro's `overflow-wrap: break-word`, never `anywhere`, which would break words that fit);
    a `sb-changelog` in `main` puts the date above its entry from 22rem down; in a stage a phone frame, a window shot
    and a video keep `min(320px, 12rem)`, and so does the whole content of a stage marked `g-ex__stage--screen` (a
    specimen that stands for a screen or a window and does not reflow below 320 px: dialogs, sheets, palettes, headers,
    views, lists in a window, and specimens whose code bar or action zone would else cut a word), so at large text they
    scroll in the stage instead of squeezing to a column no phone has (provisional, agent); a wide window shot
    (`g-rx-winwide`) is `max(740px, 46.25rem)` wide and its sidebar and inspector grow the same way, so at 200 % it is
    the window at double size (D104 (33)); below 24rem a stage keeps 8 px at its sides. Every other stage reflows as
    far as its content can; since 2.13.1, while the screen holds fewer than 20rem (`regeln-ex-d.css`), drawings and text
    specimens take the stage's width and tables marked `g-table-stack--large-text` stack per row (at 100 % they keep
    their columns). At 200 % only SCH-06's narrow column (`data-sb-narrow-ok`) and DSK-03's phone editor (`min(320px, 12rem)`)
    still scroll in their stage, besides phone frames, window shots and screen specimens, plus code
    blocks and the tables of DAT-05, DAT-14 (sortable), SCH-03 and TXT-12 in their own frame
    (`docs/ausblick.html#p-g-rahmen-scrollen`); the page never scrolls and `OVF4` finds no frame that cuts a text. A menu
    row whose word would break beside its keys gets the keys under the word from the exported `sb-fit.js` (workshop
    `ef6121d`, `docs/ausblick.html#p-w-menue-kuerzel`); the guide adds no width of its own. `guide.js`
    gives a `g-ex__stage` or `g-daten-specimen` that scrolls sideways `tabindex="0"`, `role="region"` and a name, and
    takes them away when it fits again. `data-sb-truncate` marks only a deliberate ellipsis (D102 (35)): a virtualised
    list (the TXT-09 example, whose box keeps a window's width of 16em), the window path, the document tab list and a
    deliberate „Nicht so“ ellipsis (TXT-09, DSK-01, DSK-04); as in the workshop (spec/02 §4.13) no window root under
    „So“ carries it, so every other row wraps. Any other
    `text-overflow: ellipsis` is a fault `OVF4` reports.
- **Header and footer from `build.py`** (`guide:header`, `guide:footer`, D92 (6)): the header shows `PAGES` except
  web, app, ios and desktop, which stand under one entry „Plattformen“ (`plattformen.html`, an overview page; no menu
  button, spec/03 §6.1). On a platform page that entry carries `aria-current="true"` with the place line from
  `guide.css`. The footer lists every page (`g-footer__pages`), `llms.txt` too. Measured: the navigation needs two
  rows at 390 px, three at 320 px, one at 1440 px; no page scrolls sideways.
- **Every page gets from `build.py`** (`guide:og`, `guide:head`, `guide:footer`): the canonical and og tags of its share
  image (above); `sebaro/js/sb-tone.js`, `sebaro/js/sb-print.js` and, after `assets/guide.js`, `sebaro/js/sb-fit.js`
  (deferred, so it measures the finished page) in the head, and the footer section „Darstellung“ with the „Farbton“ radios (`name="sb-tone"`, inside a `<form>`
  so they never join the radio group of a rule example) and a `data-sb-tone-status` element. A page never loads
  `sb-tone.js`, `sb-print.js` or `sb-fit.js` a second time. The footer's host is a name (`translate="no"`, `<wbr>` after
  the slash), so it breaks at the line end without a hyphen. Guide chrome must hold in `data-sb-tone="warm"` too (token-only CSS does).
- **Marker blocks nest:** `build.py` pairs `<!-- guide:x -->` / `<!-- /guide:x -->` with a stack and fills markers at
  any depth (e.g. `guide:tile` in a rule fragment). Use a `guide:tile` marker instead of pasting a tile SVG; an
  unclosed or crossed marker stops the build.

- **Never edit** `docs/sebaro/`, `docs/assets/vendor/`, `docs/rules.json`, `guide/RULES.md`, `docs/llms.txt`, `docs/og/`,
  `src/og/`, or
  anything between `<!-- guide:… -->` and `<!-- /guide:… -->` markers. Change the source and rebuild.
- **Rules** change only in `rules/rules.json`; a rule's live example lives in `src/rule-examples/<RULE-ID>.html`
  (fragment with `g-examples` / `g-ex--do` / `g-ex--dont`). Never renumber ids; retire a rule by setting
  `"status": "offen"` with a `note`, or remove it with a changelog entry.
- A rule may only become **entschieden** with an owner decision (a D-row of type I). Agents add rules as
  **vorläufig** and say so.
- Guide chrome CSS (`docs/assets/*.css`) uses only `var(--sb-*)` tokens that exist: no colour literals, no shadows
  (checked; the only exception is inside `g-ex--dont`, see above).
- New pages start from `src/page-template.html` (set `guide:og page=` to the file name without `.html`) and must be
  added to `PAGES` in `tools/build.py`; then render its share image (`build.py`, `og.mjs`, `build.py`).
- Pages are German with „du“; agent documents (this file, `guide/`, code) are English (D2). The guide's own voice may
  say „unser“/„wir“ about sebaro (D85); product UIs never do.
- Preview locally: `python3 -m http.server -d docs 8000`; screenshots in both schemes before calling a page done.
- Public repository: never commit personal data, local paths, account names, e-mail addresses, session ids or the
  names of unreleased products (those go into the git-ignored `tools/sync.local.json`).

## 6 Known limits

The guide shows sebaro as built and checked in sebaroDesign; Chromium screenshots do not verify real Android/iOS
devices, Windows rendering, WebKit/Tauri webviews or screen readers. All example data on the pages is invented.
The owner answered the round-6 sketch (63 questions, private, never linked from here) with D91 and the open readings
after it with D92 to D97, confirmed 70 of the 73 vorläufig rules with D98 and answered the four workshop questions on large
text, inputs and charts on the phone and required fields with D99, and the steps, the novalis sidebar, page width at large text, the Compose sortable table and intro step with D100 and D101, the questions of the first adoptions with D102 to D104 (D103 sets the priority for future trade-offs) and
the apps' waiting lists with D105 to D107 (D106 and D107 are built: widgets, camera and photos for Android only) and
the new gaps of the adoptions with D108 (built) and the long value in a dialog field at large text with D110 (built);
what is still open, and what is built but untested (real iOS and Android devices, launchers, a real camera, real Tauri
windows), is collected on `docs/ausblick.html`; no question waits for the owner.
No guide page scrolls sideways at 200 % text on 320, 360 and 390 px, no frame cuts a text and, since 2.11.0, no word
breaks inside itself where it would fit (`OVF3`, `OVF4`, `OVF6`; `docs/ausblick.html#p-g-grosse-schrift`); the workshop
built the narrow-column parts after D102. Since 2.13.1 the only rule examples that still scroll at 200 % are phone frames, window shots, screen specimens, code,
SCH-06's narrow column and four deliberate tables (`docs/ausblick.html#p-g-rahmen-scrollen`). The four workshop requests of 2.11.0 (menu rows with keys, a board column
head with a long one-word name, deliberately narrow columns in `OVF6`, the calendar's day numbers at 200 % on 320 px)
are built in workshop `ef6121d` and used here; none of them is checked in WebKit, Firefox or a Tauri window.
Since 2.13.0 the same holds at 200 % text on 1024 and 1280 px (`docs/ausblick.html#p-g-breite-fenster`): every layout
query of the guide's own CSS is in rem, the page frame keeps one column below 64rem (the vendor `demo.css` grid
switches at 1024 px), each grid's least column is `max(<px>, <rem>)`, and a header specimen is its own `sb-page`
container while the text is large (at 100 % every specimen stays as in 2.12.0). `check_a11y.mjs` checks page width, cut text and the contents counts there (LARGE, COUNT); squeezed words
(`OVF6`) at those widths only the workshop's check sees: run `check_demo.py … --checks overflow --viewports mobile
--large-text 1024,1280` on every page when a layout changes.
