# Screen checklist

Walk this for every screen in **light and dark**, at **390 px and 1440 px** (desktop apps: smallest and a wide window).
Rule ids in brackets; details at https://grundhofer.github.io/sebaro-guide/regeln.html. Decisions up to D90.

## Colour and hierarchy
- [ ] Cobalt only for current place, links and focus; lime only for the one primary action (FAR, AKT)
- [ ] Product colour only inside the sign tile; tiles carry the three-letter code, never words or names (ZEI)
- [ ] User categories are a grey word and search hits a 1 px frame until the owner picks their tones (FAR-12)
- [ ] Status shows glyph + word, never colour alone (STA)
- [ ] Layers end in the 2 px ink line; no tinted card grounds, no shadows (EBE)
- [ ] Lists and stats flat with hairlines; directly labelled bars neutral (DAT)

## Actions and behaviour
- [ ] At most one primary action, at the bottom of the area it acts on, verb + thing, 56 px zone; it comes **last** in
      every action group; wide windows: the state sentence (the status total, once) at the start of the zone (AKT, STA)
- [ ] Busy primary action shows its own label and ink bar; no spinner over the view, no toast for the result (AKT)
- [ ] Delete opens a confirmation; only destructive actions carry the 45° cut (AKT, FOR)
- [ ] Toast only for a reversible result outside the primary action, fixed duration, never for errors (EBE)
- [ ] Motion only in answer to an action: new content enters from below (8 px, 200 ms); only a fade with reduced
      motion / „Bewegung immer reduzieren“ (BEW)
- [ ] The start shows the tile only while really loading and moves it into the header; on the web only on the first
      visit per tab (STR)

## Light or dark (D75)
- [ ] Website: the labelled button „Hell oder Dunkel“ in the header, after the navigation and the language switch (NAV, WEB)
- [ ] Phone app: System / Hell / Dunkel in the settings, no button in the app bar (MOB)
- [ ] Desktop app: menu „Darstellung“ and the settings view (DSK)

## Desktop windows
- [ ] Command palette opens with ⌘K / Ctrl+K (NAV-09)
- [ ] Sidebar and inspector can be hidden (tool with aria-expanded, menu „Darstellung“); content keeps ≥ 480 px (DSK-04)
- [ ] Rows 32 / 48 / 64 px for one / two / three lines with a pointer, 48 px with touch (RAU)

## Navigation and links
- [ ] Current place: 3 px cobalt line + weight; app navigation with icon + word (NAV)
- [ ] Links: text-coloured word with 2 px cobalt underline; external links end in the external-link icon (LNK)

## Type and text
- [ ] sebaro Sans for UI/prose/numbers; sebaro Mono (Medium 500) only for code, IDs, versions; shortcuts as text with the
      key glyphs („⇧⌘P“) (SCH, ICO)
- [ ] Code only in the five looks (three tones, comments grey, rest ink), no bold or italic; errors and diffs not by colour alone (TXT, FAR)
- [ ] du, verb + thing, concrete sentences; U+00A0 between number and unit; German thousands 10.000 (TXT)
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

## Content and evidence
- [ ] No claim without proof; outflows stay visible; unknown = „nicht belegt“ (BEL)
- [ ] Websites: footnote digits are text, notes 1..n in one column with backlinks; apps: claim rows (BEL)
- [ ] No invented demo data shipped; no foreign network requests (WEB)
