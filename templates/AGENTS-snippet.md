<!-- Paste this section into the product repository's AGENTS.md (Codex) and keep CLAUDE.md as "@AGENTS.md". -->

## Design: sebaro

This product uses the sebaro design system. Before building or changing any UI:

1. Read the rules: https://grundhofer.github.io/sebaro-guide/rules.json (Markdown:
   https://github.com/grundhofer/sebaro-guide/blob/main/guide/RULES.md). Rules with status `entschieden` are binding.
2. Use only the exported system files in `<path to the sebaro export>`; never edit them, never copy colour values,
   reference tokens (`var(--sb-*)`, `SebaroTheme`, `Color.sb*`).
3. Copy component markup from https://grundhofer.github.io/sebaro-guide/bauteile.html and screen recipes from the
   app/web/desktop pages of the guide. `demo-*` and `g-*` classes are guide chrome, never ship them.
4. Product id: `<id>`; its tile colour appears only in the sign tile.
5. Before calling a screen done, walk https://github.com/grundhofer/sebaro-guide/blob/main/templates/screen-checklist.md
   in light and dark, at 390 px and 1440 px.
6. Light or dark per product kind (D75): a website has the labelled button „Hell oder Dunkel“ in its header; a phone
   app offers System, Hell, Dunkel in its settings; a desktop app in the menu „Darstellung“ and in its settings view.
   The second tone „Farbton: Kühl · Warm“ (D91, FAR-15): websites in the footer under „Darstellung“, apps next to
   light/dark in their settings (`sb-tone.js`, `theme-init.js`). Websites print always light (`sb-print.js`, WEB-11).
7. The one primary action sits at the bottom of the area it acts on and comes last in every action group (D74, D83).
   Desktop: command palette on ⌘K / Ctrl+K (D84); sidebar and inspector can be hidden, the content keeps ≥ 480 px
   (D81). Focus ring 2 px (D85).
8. Plan for several languages (D87): no UI string built into code; script messages follow `lang`.
9. The round-6 components are decided (D91) and part of sebaro; copy them from the guide, do not rebuild them:
   category and mark (`sb-category--1…6`, `sb-mark`), signed numbers (`sb-signed`), board (`sb-board`), sticky group
   head, timeline, table sort and sum row (`sb-table__sort`, `tfoot`), calendar, quote, intro step, about head, audio,
   video, place map, website patterns (form result, page numbers, FAQ, docs groups, screenshots, share image, language
   switch, print), charts (`sb-chart`, heatmap with classed scales, at most 5 steps), iOS (SwiftUI package) and the
   desktop window parts. Count partial states („2 offen“), never „teils offen“ (STA-09). Compose versions of the new
   web parts and charts do not exist yet: ask before building one. Still with the owner: the heatmap „heute“ marker,
   the „Konflikt“ glyph and the licence reading (see the guide's „Ausblick“).
10. Ship the export's `LICENSE.md` unchanged (D76). If a rule does not fit, cite its id (e.g. `AKT-01`) and ask the
    owner; do not work around it. Rule changes are listed by id in
    https://github.com/grundhofer/sebaro-guide/blob/main/CHANGELOG.md.
