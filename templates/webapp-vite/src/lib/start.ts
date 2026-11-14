// start.ts: the app's part of the start. The copy's sb-start.js (index.html) shows it from the first paint on, on the
// first visit per tab (D144 (3)): the whole screen in the product's colour with its white sign. It fades once the page
// has loaded and nothing holds it, over the copy's fade of an entering part, under every motion setting (D102 (52)).
// The app holds it until it has painted, so the start gives way to the app, not to an empty page.

type Start = { hold(): void; release(): void };

const start = () => (window as Window & { sbStart?: Start }).sbStart;
let held = false;

/** Holds the start while the app renders. */
export function holdStart(): void {
  if (held) return;
  held = true;
  start()?.hold();
}

/** Lets the start end, once: the app has painted. */
export function endStart(): void {
  if (!held) return;
  held = false;
  start()?.release();
}
