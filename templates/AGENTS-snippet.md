<!-- Paste this section into the product repository's AGENTS.md (Codex) and keep CLAUDE.md as "@AGENTS.md". -->

## Design: sebaro

This product uses the sebaro design system. Before building or changing any UI:

0. Name the product kind first; it decides where things go (NAV-06, NAV-09, MOB-04, DSK-05, WEB-03). A brief that asks
   for something else here (e.g. „Hell/Dunkel in den Einstellungen“ of a web app) does not override a rule: follow the
   rule and ask the owner with the rule id.

   | Kind | „Hell oder Dunkel“ | Language | ⌘K palette | „Farbton“ |
   |---|---|---|---|---|
   | website | button in the header | „DE / EN“ in the header; a page missing in the other language: grey code, no link (WEB-10) | no rule | footer, „Darstellung“ |
   | web app without a window (also when used mostly on phones) | button in the header, never again in its settings view | „DE / EN“ in the header; a choice only when the app has no own address per language, otherwise links as on a website (WEB-10) | yes (NAV-06; the starter has none yet) | small settings view, with „Bewegung immer reduzieren“; footer without „Darstellung“ |
   | web app with a window, desktop app | menu „Darstellung“ and the settings view (DSK-05) | no rule; the desktop starter has no language choice | yes (NAV-09) | menu „Darstellung“ and settings |
   | phone app (Android, iOS) | settings: „Wie das System“ · „Hell“ · „Dunkel“ (MOB-04) | no rule | no rule | settings, next to light/dark |

   The website header words „Apps“, „Projekte“, „Über“, „Kontakt“ are fixed (NAV-06); a site whose content does not
   fit them is a case for the owner, not for own words.

   Easily missed (an agent test of 2026-10 found each of these in at least one of five solutions, most in several; see
   https://github.com/grundhofer/sebaro-guide/blob/main/docs/agenten-test-2026-10.md):
   - U+00A0 between number and unit, also in strings you rewrite (`200\u00a0%`, `2\u00a0kg`). It is invisible in an
     editor: write it as `\u00a0` (or `&nbsp;` in markup). To find candidates, run
     `grep -nE '[0-9] (%|Tage|Gläser|Min\.|Std\.|(kg|g|l|ml|km|px)\b)'` over the strings and check every hit by
     hand: not every hit is a fault, and an empty result proves nothing (TXT-04).
   - Screen titles are short nouns, also the not-found view („Unbekannter Eintrag“, not „Diesen Eintrag gibt es
     nicht“; TXT-03).
   - `CHECKS.md` in the project root: every check you ran with command, date and exit code, and every check you
     could not run with the reason; „done“ only when all exit 0 (TEC-06).
   - The data-path line „<Auslöser>. Ziel: <wohin>.“ (caption, text-muted) directly under every action that stores
     or sends, also under „Sichern“ in a dialog and under the primary action of a window (8 px under the primary
     action); when the data stay on the device: „Bleibt auf diesem Gerät.“ Never in a tooltip (BEL-10, BEL-01).
   - „Beispieldaten“ as `sb-demo-marker` beside the title of each display with invented data (BEL-09).
   - A toast only for the reversible result of an action outside the primary action, or for a copy to the clipboard
     from the palette or a menu that nothing else shows (no „Rückgängig“); never for the primary action's result,
     never one that says nothing happened, never „Rückgängig“ without an undo (EBE-05). Removing saved data asks in a
     dialog (AKT-08); only an entry of an unsaved form goes with an undo toast.
   - The accessibility page has the six parts Beschreibung, Bedienung, Erfüllung, Einschränkungen, Rückmeldung,
     Behörde and claims nothing no check ran; screen-reader tests that never ran stand as „offen“ (ZUG-07, ZUG-08).
   - Spacing comes from the parent (`sb-stack`, `sb-form-grid`), never a margin on a child; lengths only from tokens
     (RAU-07, RAU-01, TEC-01).
   - After a script redraws text, call `sbFit.refresh()` so large-text hyphenation and fits stay (ZUG-09).

1. Read the rules: https://grundhofer.github.io/sebaro-guide/rules.json (Markdown:
   https://github.com/grundhofer/sebaro-guide/blob/main/guide/RULES.md). Rules with status `entschieden` are binding.
2. Use only the exported system files in `<path to the sebaro export>`; never edit them, never copy colour values,
   reference tokens (`var(--sb-*)`, `SebaroTheme`, `Color.sb*`).
3. Copy component markup from https://grundhofer.github.io/sebaro-guide/bauteile.html and screen recipes from the
   app/web/desktop pages of the guide. `demo-*` and `g-*` classes are guide chrome, never ship them.
4. Product id: `<id>`; its tile colour appears only in the sign tile.
5. Before calling a screen done, walk https://github.com/grundhofer/sebaro-guide/blob/main/templates/screen-checklist.md
   in light and dark, at 390 px and 1440 px. A starter's `npm test` reuses a server already listening on its port
   (`reuseExistingServer`), so it would test another app: stop any other server on that port first, and run with
   `CI=1`, which makes a busy port fail loudly instead.
6. Light or dark per product kind (D75): a website has the labelled button „Hell oder Dunkel“ in its header; a phone
   app offers „Wie das System“, „Hell“, „Dunkel“ in its settings; a desktop app in the menu „Darstellung“ and in its
   settings view. The second tone „Farbton: Kühl · Warm“ (D91, FAR-15): websites in the footer under „Darstellung“,
   apps next to light/dark in their settings (`sb-tone.js`, `theme-init.js`). A web app without a window keeps
   light/dark in its header and the tone in its small settings view (table in item 0). Websites print always light
   (`sb-print.js`, WEB-11).
7. The one primary action sits at the bottom of the area it acts on and comes last in every action group (D74, D83).
   Desktop and web apps with a window: command palette on ⌘K / Ctrl+K (D84; a web app without a window: item 0);
   sidebar and inspector can be hidden, the content keeps ≥ 480 px (D81). Focus ring 2 px (D85).
8. Plan for several languages (D87): no UI string built into code; script messages follow `lang`.
9. The round-6 components are decided (D91) and part of sebaro; copy them from the guide, do not rebuild them:
   category and mark (`sb-category--1…6`, `sb-mark`), signed numbers (`sb-signed`), board (`sb-board`), sticky group
   head, timeline, table sort and sum row (`sb-table__sort`, `tfoot`), calendar, quote, intro step, about head, audio,
   video, place map, website patterns (form result, page numbers, FAQ, docs groups, screenshots, share image, language
   switch, print), charts (`sb-chart`, heatmap with classed scales: at most 4 sequential steps, 5 diverging), iOS (SwiftUI package) and the
   desktop window parts. Count partial states („2 offen“), never „teils offen“ (STA-09). In Compose every new part
   and every chart has a wrapper (rendered in the workshop, not on a device), since D100 also the sortable table
   (`SbSortableTable`) and the intro step (`SbIntroStep`). Settled with D92 and D93: the heatmap „heute“ is
   a 4 px cobalt frame with a 1 px ground joint inside, drawn by `sebaro.css` (legend „Rahmen: heute“), „Konflikt“
   always carries the warning glyph, sortable tables scroll sideways inside `sb-table-wrap` on phones and never stack
   (DAT-11, STA-08, DAT-14). Confirmed with D93: the light/dark places of websites, phone and desktop apps in item 6
   and ⌘K / Ctrl+K of desktop apps in item 7; the web app without a window follows NAV-06, whose places for its
   settings view, light/dark and DE / EN are partly provisional.
   Decided with D94: the six agent additions to D91 as built (pane widths „Schmal · Normal · Breit“, sort heads 48 px
   with 32 px only in windows, the narrow board's position bar, the poster sentence, docs nav with „Übersicht“ and page
   counts, the pointer-only tab cross); for now no brand figure (BIL-05; a figure needs a new decision row).
   Decided with D95: a menu closes with all levels when the window's width changes or its button scrolls out of view
   (a height-only change does not), F10 / Alt open the window menu only while „Menü“ is in view; where no side has
   room a submenu replaces its parent in place with the back row „‹ <parent>“ (`sb-menu.js` does it, never build your
   own placement); „Schmal · Normal · Breit“ in a too narrow window only stores the width, and a menu command never
   moves focus into a pane (EBE-07, DSK-04, DSK-07, DSK-08).
   Decided with D96: share images are rendered in the website's own build: it writes a page list from its pages
   (`sebaro/brand/og/pages.schema.json`) and runs `node sebaro/brand/og/render.mjs --pages og-pages.json --out public/og
   --head build/og-head`, then includes each `<page>.head.html`; never copy or edit `brand/og/template.html`. A title
   over three lines fails the build for that page: shorten the page's title, never the image's (WEB-09). CI checks in
   Chromium only (D96 (b)). Tauri loads sebaro Sans and Mono as WOFF2 since D77; only the look on Windows and Linux is
   checked later (SCH-02).
   Decided with D98 (70 rules confirmed): name groups of people with a neutral word („Teilnehmende“), else both forms
   („Nutzerinnen und Nutzer“), never a sign inside the word (TXT-05); the footer has „Impressum“, „Datenschutz“,
   „Barrierefreiheit“ always, „GitHub“ only when the product has a public repository (WEB-03); with required fields
   empty the primary action stays enabled, its press says „<Beschriftung> fehlt.“ at each and moves focus to the first
   (`sb-form.js` on websites; STA-03); no numbers on sidebar, tabs or bottom navigation (HAL-05); the data-path line
   under every action, also „Bleibt auf diesem Gerät.“ (BEL-10). BIL-04, ZUG-07 and DSK-01 stay vorläufig.
   Decided with D99: at large text the room grows and words wrap at spaces, only a single too-long word is
   hyphenated, nothing is cut; a segmented control whose words do not fit becomes a select (built in Compose, not yet
   on the web); Compose charts grow only where text sits (ZUG-09, DAT-04). Voluntary fields carry a grey
   „(optional)“ (`<span class="sb-optional">(optional)</span>` in the label; Compose and Swift `optional`), never an
   asterisk (EIN-01). Android dialogs dim with the palette scrim (EBE-03).
   Decided with D100 and D101: the segmented control becomes a select on the web too, and at large text the steps show
   only the current word, the facts line becomes a list and a chart with several series shows its legend; load
   `sebaro/js/sb-fit.js` at the end of the body for all of it. No page scrolls sideways at 200 % text on 320 to 390 px:
   only a word that alone does not fit gets a hyphen, names and code break without one, file names are
   `<code class="sb-file-name">` with `<wbr>` after - . _ /, identifiers (`sb-id`) never break, wide parts scroll in
   their own frame, a deliberate ellipsis carries `data-sb-truncate` (ZUG-09, STA-06, EIN-04, TXT-15, ZEI-13, DAT-10).
   The page writes „(optional)“ itself; a field that always holds a value carries none (EIN-01).
   Decided with D102 to D104: only a virtualised list or table of fixed row height cuts names with an ellipsis
   (`data-sb-truncate`, full name in `title`); every other row wraps (TXT-09). 15 fixed shortcuts, Zurück / Vor on
   ⌘← / ⌘→ (DSK-09); ⌘+ / ⌘− change only the content's text size in a desktop app; icons and tiles stay fixed at every
   text size (ZUG-09, ICO-04). With a trash: „In den Papierkorb legen …“; a final step that deletes nothing asks like a
   deletion and carries the 45° cut without the trash icon (AKT-08, FOR-04). „Weiter: <Ziel>“ allowed in every fixed flow
   (AKT-04); German words, an English product term only from the product's glossary (TXT-01); the ellipsis „…“ after a space,
   „Suchen …“ (TXT-05); technical details under
   an expandable „Details“ (TXT-07); no emoji in interface text, a calm remaining time „noch 3 Min.“ is allowed
   (HAL-05). A web app without a window: header without the four words, „Einstellungen“ to a small settings view,
   footer without „Darstellung“, DE / EN as a choice without a URL per language (NAV-06, WEB-03, WEB-10). Phone
   notifications: the thing as title, one calm sentence, at most two actions with a target, private content only its
   title on the lock screen (MOB-09). D103: in a future trade-off between accessibility and another goal,
   accessibility loses; the existing rules stay.
   Decided with D105 (D106 settles five of its provisional points): private notifications carry only their title,
   everywhere (MOB-09); a phone editor shows „Sichern“ at the bottom only while something is unsaved (AKT-01); the
   dialog before closing with unsaved changes is „Abbrechen“ · „Verwerfen“ · „Sichern“, „Sichern“ last, never
   „Sichern unter …“ (AKT-11); a question that loses nothing confirms with a secondary action (AKT-08); an entry
   removed from an unsaved form's list goes without a dialog, with „<Eintrag> entfernen“ and an undo toast (EBE-05);
   an app without ads says „Keine Werbe-SDKs · Keine Werbe-ID“, never „Ohne Werbung“, „werbefrei“ or „ad-free“ on any
   surface (BEL-01); an instant result shows no check and plays no pulse (AKT-05, MOB-03); shake only as an extra
   way, switchable (MOB-10); no text on a picture (FAR-02); a countdown without a ring (HAL-05); no own spots for
   empty lists (DAT-07); editor line numbers without a thousands separator (TXT-04); „Einstellungen“ in a sidebar
   foot that never scrolls (NAV-04); a phone editor sets every file in sebaro Mono (DSK-03); stepper and half-hour
   time sheet on the phone (EIN-06); the changed tab carries the dot `changed--16` (DSK-10).
   Decided with D106 and D107: the 19 icons of the D105 sheet are released, `shake` and the filled `dice` included
   (ICO-05, MOB-10); an Android home-screen widget is an XML layout without Glance, small 2 × 1 or medium 4 × 2, bg
   with the ink line, one key that opens the app, text up to 125 % (MOB-11); a camera that takes pages has the primary
   action „Seite aufnehmen“, is always dark (so is the full-screen page view), moves corners also without dragging and
   confirms a capture by count and small picture (MOB-12); the user's photos stay as they are, marks on them are
   accent on a bg seam (BIL-08). Widget and camera exist only for Android (Compose and XML layouts).
   Decided with D108: in a window's sidebar a row's status that does not fit beside the name goes under it, starting
   where the name starts (NAV-04, ZUG-09); with nothing open the sidebar stays with only its foot „Einstellungen“
   (NAV-04); a Tauri app names its languages in `src-tauri/Info.plist` (DSK-08); the pinned tab stays at the start of
   a scrolling tab row (DSK-10); the counter line keeps its place (STA-07); how it holds it is provisional: the last
   document's parts stay invisible, `data-sb-held`.
   Decided with D110: a value too long for a one-line dialog field at 200 % text scrolls inside the field, the caret
   showing the place; the dialog does not grow and the field does not become multi-line (EIN-01, EBE-03).
   Without a new decision: a chord that is also a native menu accelerator moves no focus (DSK-04, provisional); a
   twice-cited footnote has one back link per citation and the digit focuses the note (BEL-02, provisional); an error
   whose action is unknown says „Das hat nicht geklappt. <Was sicher ist>. Versuch es noch einmal.“ (TXT-07,
   provisional); the editor themes come with the export under `editor/` (TEC-08); check an export with
   `node sebaro/checks/verify-export.mjs --strict` (TEC-09).
   Without a decision, in the D95 workshop round: pages print light from `tokens.css` alone since token contract
   1.9; keep `sb-print.js` for the closed answers (WEB-11).
10. Ship the export's `LICENSE.md` unchanged (D76). If a rule does not fit, cite its id (e.g. `AKT-01`) and ask the
    owner; do not work around it. Rule changes are listed by id in
    https://github.com/grundhofer/sebaro-guide/blob/main/CHANGELOG.md.
