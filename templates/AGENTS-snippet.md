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
6. If a rule does not fit, cite its id (e.g. `AKT-01`) and ask the owner; do not work around it.
