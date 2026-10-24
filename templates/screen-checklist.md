# Screen checklist

Walk this for every screen in **light and dark**, at **390 px and 1440 px** (desktop apps: smallest and a wide window).
Rule ids in brackets; details at https://grundhofer.github.io/sebaro-guide/regeln.html. Decisions up to D99.

## Colour and hierarchy
- [ ] Cobalt only for current place, links and focus; lime only for the one primary action (FAR, AKT)
- [ ] Product colour only inside the sign tile; tiles carry the three-letter code, never words or names (ZEI)
- [ ] User categories: a 10 px dot in one of the six tones next to the word, never a fill or the only cue; search hits
      and highlights: fill with a 2 px edge, the current hit with „Treffer n von m“ (FAR-12)
- [ ] Plus and minus in number apps: colour follows the sign, always with + / − and the arrow icon (FAR-14)
- [ ] Status shows glyph + word, never colour alone; „Konflikt“ always with the warning glyph (STA)
- [ ] Layers end in the 2 px ink line; no tinted card grounds, no shadows (EBE)
- [ ] Lists and stats flat with hairlines; directly labelled bars neutral (DAT)
- [ ] Colour scales in classes, at most 4 sequential or 5 diverging, each step tellable from its neighbours and from
      the ground; the legend above the chart names the numbers of every class; a heatmap marks today with the 4 px
      cobalt frame and its 1 px ground joint from `sebaro.css` („Rahmen: heute“), never like the focus ring; with
      three or more series the legend shows line styles (DAT-10, DAT-11)
- [ ] Partially done is counted („2 offen“, „3 von 5 beantwortet“), never „teils offen“ (STA-09)
- [ ] Sortable tables: the arrow and title weight only on the sorted column, `aria-sort` on its header; a sum row
      in `tfoot` under its column, „Summe der bekannten …“ when a value is missing, never 0; on phones the table
      scrolls sideways inside `sb-table-wrap`, never the page, and never stacks into blocks (DAT-14)

## Actions and behaviour
- [ ] At most one primary action, at the bottom of the area it acts on, verb + thing, 56 px zone; it comes **last** in
      every action group; wide windows: the state sentence (the status total, once) at the start of the zone (AKT, STA)
- [ ] Busy primary action shows its own label and ink bar; no spinner over the view, no toast for the result (AKT)
- [ ] Delete opens a confirmation; only destructive actions carry the 45° cut (AKT, FOR)
- [ ] Required fields empty: the primary action stays enabled, its press sends nothing, says „<Beschriftung> fehlt.“
      at each and moves focus to the first (`sb-form.js` on websites); disabled only while the action cannot work at
      all (STA-03, D98)
- [ ] Required fields carry no mark; voluntary fields end their label with a grey „(optional)“ (`sb-optional`), never
      an asterisk or a „Pflichtfeld“ legend (EIN-01, D99)
- [ ] Toast only for a reversible result outside the primary action, fixed duration, never for errors (EBE)
- [ ] Motion only in answer to an action: new content enters from below (8 px, 200 ms); only a fade with reduced
      motion / „Bewegung immer reduzieren“ (BEW)
- [ ] The start shows the tile only while really loading and moves it into the header; on the web only on the first
      visit per tab (STR)

## Light or dark (D75)
- [ ] Website: the labelled button „Hell oder Dunkel“ in the header, after the navigation and the language switch (NAV, WEB)
- [ ] Phone app: System / Hell / Dunkel in the settings, no button in the app bar (MOB)
- [ ] Desktop app: menu „Darstellung“ and the settings view (DSK)
- [ ] Tone „Farbton: Kühl · Warm“: websites in the footer under „Darstellung“, apps next to light/dark in the
      settings; only grounds, text and lines turn warm, cobalt, lime, status and tiles stay (FAR-15)
- [ ] Website print is always light, whatever the screen shows (`sb-print.js`), and shows only the content (WEB-11, WEB-04)
- [ ] Website: every page with its own title has its own share image and head tags from the build (`sebaro/brand/og/render.mjs`
      on the site's page list, exit 0; canonical, og:url, og:image absolute); the template is never copied or edited (WEB-09, D96)

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
- [ ] Groups of people: a neutral word („Teilnehmende“, „Mitglieder“), else both forms („Nutzerinnen und Nutzer“);
      never a sign inside the word: no star, colon, underscore, middle dot or Binnen-I (TXT-05, D98)
- [ ] Money, ranks, „etwa“, „keine“ vs „keine Angabe“, no automatic hyphenation in running text; menu paths as
      „Einstellungen, dann Über“ (TXT-12 to TXT-16)
- [ ] No UI string built into code; script messages and number/date formats follow the page's language (TEC-10)
- [ ] Empty states have a useful sentence; errors say what happened and what to do (TXT)

## Access
- [ ] Text ≥ 4.5:1, functional shapes ≥ 3:1, focus ring 2 px visible everywhere (ZUG)
- [ ] The four fixed tasks work by keyboard alone: create, delete with dialog, open a claim/evidence, switch light/dark (ZUG-08)
- [ ] Touch targets ≥ 48 px (desktop rows 32 px with pointer) (ZUG, RAU)
- [ ] Keyboard: open/close, Escape, focus enters and returns; screen-reader names on icon-only controls (ZUG)
- [ ] No clipping, no horizontal scrolling at 390 px
- [ ] Large text (200 % on a 360 px phone): rooms grow, words wrap at spaces, only a single too-long word is
      hyphenated, nothing is cut; Android dialogs dim with the palette scrim (ZUG-09, EBE-03, D99)

## Content and evidence
- [ ] No claim without proof; outflows stay visible; unknown = „nicht belegt“ (BEL)
- [ ] Websites: footnote digits are text, notes 1..n in one column with backlinks; apps: claim rows (BEL)
- [ ] No invented demo data shipped; no foreign network requests (WEB)
- [ ] Website footer: „Impressum“, „Datenschutz“, „Barrierefreiheit“ always; „GitHub“ only with a public repository (WEB-03, D98)
