# Screen checklist

Walk this for every screen in **light and dark**, at **390 px and 1440 px** (desktop apps: smallest and a wide window).
Rule ids in brackets, „K5“ = core rule 5 of `design/KERN.md`, which wins where the catalogue differs; details in
https://github.com/grundhofer/sebaro-blueprint/blob/main/rules/rules.json. Decisions up to D148.

## Before you start
- [ ] Product kind named (phone app, website, web app, desktop app); light/dark, language, „Farbton“ and ⌘K sit
      where that kind puts them (K28, section *Light or dark*; NAV-09). A brief that asks otherwise is a question for
      the owner with the rule id, not a reason to move them
- [ ] Every string you wrote or rewrote keeps U+00A0 between number and unit (`\u00a0` in code, `&nbsp;` in markup)
      (TXT-04). Search aid, not a pass condition: `grep -nE '[0-9] (%|Tage|Gläser|Min\.|Std\.|(kg|g|l|ml|km|px)\b)'`
      over the strings; check every hit by hand (not every hit is a fault, and an empty result proves nothing)

## Colour and hierarchy
- [ ] Cobalt only for current place, links, focus and the selected mark; lime only for the one primary action and the
      sebaro key (K4, FAR, AKT)
- [ ] Product colour only in the sign tile, the start and at most one product area per view (entry, overview with one
      value, detail with one value, result, empty state), never behind controls or links; the tile shows the symbol
      alone, no code, unaltered, always beside the app's name (K5, K25, D143)
- [ ] User categories: a 10 px dot in one of the six tones next to the word, never a fill or the only cue; search hits
      and highlights: fill with a 2 px edge, the current hit with „Treffer n von m“ (FAR-12)
- [ ] Plus and minus in number apps: colour follows the sign, always with + / − and the arrow icon (FAR-14)
- [ ] Status shows glyph + word, never colour alone; „Konflikt“ always with the warning glyph (STA)
- [ ] Layers end in the 2 px ink line; no tinted card grounds, no shadows (EBE)
- [ ] Lists stay lists of flat rows with hairlines at every width, stats flat; directly labelled bars neutral (K10, DAT)
- [ ] Colour scales in classes, at most 4 sequential or 5 diverging, each step tellable from its neighbours and from
      the ground; the legend above the chart names the numbers of every class; a heatmap marks today with the 4 px
      cobalt frame and its 1 px ground joint from `sebaro.css` („Rahmen: heute“), never like the focus ring; with
      three or more series the legend shows line styles (DAT-10, DAT-11)
- [ ] Partially done is counted („2 offen“, „3 von 5 beantwortet“), never „teils offen“ (STA-09)
- [ ] Sortable tables: the arrow and title weight only on the sorted column, `aria-sort` on its header; a sum row
      in `tfoot` under its column, „Summe der bekannten …“ when a value is missing, never 0; on phones the table
      scrolls sideways inside `sb-table-wrap`, never the page, and never stacks into blocks (DAT-14)

## Actions and behaviour
- [ ] At most one primary action (two panes are one view), at the bottom of the area it acts on, verb + thing, 56 px
      zone; it comes **last** in every action group; none without a clear next step, none on a detail view; at most one
      outlined action per area, the rest text actions; wide windows: the state sentence (the status total, once) at the
      start of the zone (K12, K13, AKT, STA)
- [ ] Busy primary action shows its own label and ink bar; no spinner over the view, no toast for the result (AKT)
- [ ] Deleting something saved asks in a dialog that says what is lost; the 45° cut only on actions that cannot be
      undone (K11, K15, AKT, FOR)
- [ ] Required fields empty: the primary action stays enabled, its press sends nothing, says „<Beschriftung> fehlt.“
      at each and moves focus to the first (`sb-form.js` on websites); disabled only while the action cannot work at
      all (STA-03, D98)
- [ ] Required fields carry no mark; voluntary fields end their label with a grey „(optional)“ (`sb-optional`), never
      an asterisk or a „Pflichtfeld“ legend (EIN-01, D99)
- [ ] Toast only for a reversible result outside the primary action, with „Rückgängig“, fixed duration, never for
      errors, never to say that nothing happened (K14, EBE-05). Removing saved data asks in a dialog; only an entry of
      an unsaved form goes with an undo toast (AKT-07, AKT-08)
- [ ] Every action that stores or sends has its data-path line „<Auslöser>. Ziel: <wohin>.“ directly under it (8 px
      under the primary action), also „Sichern“ in a dialog and the primary action of a window; local data: „Bleibt
      auf diesem Gerät.“ (BEL-10)
- [ ] Motion only in answer to an action: new content enters from below (8 px, 200 ms); only a fade with reduced
      motion / „Bewegung immer reduzieren“ (BEW)
- [ ] Start: the whole screen in the product colour with the white symbol, then the app; on the web only on the first
      visit per tab. „Über“ shows tile, name, version and the sender „von sebaro“ (K29, D144)
- [ ] Android home-screen widget: bg with the ink line, small 2 × 1 or medium 4 × 2, sebaro Sans through the XML
      layout (no Glance), the whole widget one key, pressed-fill, text up to 125 %, nothing cut in its cell (MOB-11)
- [ ] Camera: „Seite aufnehmen“ as the primary action, camera and full-screen page view always dark, corners also
      without dragging, a capture confirmed by count and small picture, no flash or sound; the user's photos as they
      are, marks on them in accent on a bg seam (MOB-12, BIL-08)

## Light or dark (K28)
- [ ] Website: the labelled button „Hell oder Dunkel“ in the header, after the navigation and the language switch (NAV, WEB)
- [ ] Web app: in the „Mehr“ menu, not in the head (K28, D143)
- [ ] Phone app: „Wie das System“ · „Hell“ · „Dunkel“ in the settings, no button in the app bar (MOB-04)
- [ ] Desktop app: menu „Darstellung“ and the settings view (DSK)
- [ ] Tone „Farbton: Kühl · Warm“: websites in the footer under „Darstellung“, apps next to „Hell oder Dunkel“ (K28);
      only grounds, text and lines turn warm, cobalt, lime, status and tiles stay (FAR-15)
- [ ] Website print is always light, whatever the screen shows, and shows only the content (WEB-11, WEB-04)
- [ ] Website: every page with its own title has its own share image and head tags from the build
      (`sebaro/product/render.mjs share` on the site's page list, exit 0; canonical, og:url, og:image absolute); the
      template is never copied or edited (WEB-09, D96)

## Desktop windows
- [ ] Command palette opens with ⌘K / Ctrl+K (NAV-09)
- [ ] Sidebar and inspector can be hidden (tool with aria-expanded, menu „Darstellung“); content keeps ≥ 480 px (DSK-04)
- [ ] Rows 32 / 48 / 64 px for one / two / three lines with a pointer, 48 px with touch (RAU)
- [ ] Submenus of „Menü“ at 1440, 1024, 700, 640, 390 and 320 px, right to left and with touch, also with „Menü“ near
      the bottom edge: each opens beside its parent, or without room replaces it in place with the back row
      „‹ <parent>“ first (named „Zurück zu <parent>“; it, ← and Escape go back); no level covers items of another,
      every level stays inside the window (EBE-07, D95)
- [ ] An open menu closes with every level when the window gets narrower or wider or „Menü“ scrolls out of view, focus
      back on „Menü“; a height-only change keeps it open while „Menü“ stays in view; F10 / Alt open nothing while
      „Menü“ is out of view (DSK-08)
- [ ] In a window too narrow for a pane, „Schmal · Normal · Breit“ only stores the width (pane stays closed, focus on
      „Menü“); a menu command that opens a pane leaves focus on „Menü“, Escape there closes the overlay (DSK-07, DSK-04)

## Navigation and links
- [ ] Current place: 3 px cobalt line + weight; app navigation with icon + word (NAV)
- [ ] Links: text-coloured word with 2 px cobalt underline; external links end in the external-link icon (LNK)

## Type and text
- [ ] sebaro Sans for UI/prose/numbers; sebaro Mono (Medium 500) only for code, IDs, versions; shortcuts as text with the
      key glyphs („⇧⌘P“) (SCH, ICO)
- [ ] Code only in the five looks (three tones, comments grey, rest ink), no bold or italic; errors and diffs not by colour alone (TXT, FAR)
- [ ] du, verb + thing, concrete sentences; U+00A0 between number and unit; German thousands 10.000 (TXT)
- [ ] Screen titles are short nouns, also the not-found and error views („Unbekannter Eintrag“); sentence headings
      only on websites (TXT-03)
- [ ] Groups of people: a neutral word („Teilnehmende“, „Mitglieder“), else both forms („Nutzerinnen und Nutzer“);
      never a sign inside the word: no star, colon, underscore, middle dot or Binnen-I (TXT-05, D98)
- [ ] Money, ranks, „etwa“, „keine“ vs „keine Angabe“, no automatic hyphenation in running text; menu paths as
      „Einstellungen, dann Über“ (TXT-12 to TXT-16)
- [ ] No UI string built into code; German and English from the first version, a check fails on a missing string (a
      content site keeps one language); script messages and number/date formats follow the page's language (K26,
      TEC-10)
- [ ] Empty states have a useful sentence; errors say what happened and what to do (TXT)

## Access
- [ ] Text ≥ 4.5:1, functional shapes ≥ 3:1, focus ring 2 px visible everywhere (ZUG)
- [ ] On web and desktop the main flows work by keyboard alone (K30)
- [ ] Touch targets ≥ 48 px (desktop rows 32 px with pointer) (ZUG, RAU)
- [ ] Keyboard: open/close, Escape, focus enters and returns; screen-reader names on icon-only controls (ZUG)
- [ ] No page scrolls sideways at 390 px; text that does not fit wraps or ends in an ellipsis (K30, D147)
- [ ] Large text once per screen (Android font scale 1.3, web 200 % zoom at desktop width): it stays usable, an
      ellipsis is fine (K30, D148)
- [ ] Only a virtualised list cuts names, with `data-sb-truncate` and the full name in `title`; elsewhere names wrap
      (TXT-09)

## Content and evidence
- [ ] No claim without proof; outflows stay visible; unknown = „nicht belegt“ (BEL)
- [ ] No ads: „Keine Werbe-SDKs · Keine Werbe-ID“; never „Ohne Werbung“, „werbefrei“ or „ad-free“, also not in store
      texts, on the website or in headings (BEL-01, D105, D106)
- [ ] Where the product shows evidence: website footnote digits are text, notes 1..n in one column with backlinks;
      apps: claim rows (BEL)
- [ ] Nothing loads from third-party servers (K27, HAL-09)
- [ ] Invented data carries `<span class="sb-demo-marker">Beispieldaten</span>` beside the title of its display (BEL-09)
- [ ] Website footer: „Impressum“ and „Datenschutz“ always; „GitHub“ only with a public repository (WEB-03, D98, D147)

## Done
- [ ] `CHECKS.md` in the project root names every check with command, date and exit code, and every check that could
      not run with its reason; the screen counts as done only when all ran and exit 0 (TEC-06)
- [ ] A starter's end-to-end tests (`npm test` for the website, `pnpm test:e2e` for web and desktop apps) ran against
      this app: any other server on its port was stopped first (outside CI the tests reuse one), and they ran with
      `CI=1`, which makes a busy port fail loudly
