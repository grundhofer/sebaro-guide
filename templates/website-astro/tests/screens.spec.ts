// Every page of the site, light and dark, at 320, 390 and 1440 px, at 100 % and at real 200 % text
// (checks in sebaro-checks.ts: the page asked for with its HTTP status, heading, view and open overlays; no sideways
// scroll, no cut text or control value, axe 0 violations, no console or CSP error).
import { expect, type Page } from "@playwright/test";
import { checkScreens } from "./sebaro-checks";

const openFootnotePopover = async (page: Page) => {
  // a narrow screen (below 64rem, so also 1440 px at 200 % text) opens the note in the popover (BEL-07); a wide one
  // jumps to the note (BEL-02)
  await page.locator("#fnref-1").click();
  await page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running"));
};
const narrow = (width: number, scale: number) => width < 64 * 16 * scale;

checkScreens([
  { name: "start", path: "/", heading: "Kleine Werkzeuge, ruhig gebaut.", view: '[data-sb-view="start"]', overlay: null },
  { name: "start-en", path: "/en/", heading: "Small tools, built calmly.", view: '[data-sb-view="start-en"]', overlay: null },
  { name: "apps", path: "/apps/", heading: "Apps", view: '[data-sb-view="apps"]', overlay: null },
  { name: "projekte", path: "/projekte/", heading: "Projekte", view: '[data-sb-view="projekte"]', overlay: null },
  { name: "artikel", path: "/projekte/liste-als-csv/", heading: "Eine Liste als CSV-Datei sichern", view: '[data-sb-view="artikel"]', overlay: null },
  {
    name: "artikel-fussnote",
    path: "/projekte/liste-als-csv/",
    heading: "Eine Liste als CSV-Datei sichern",
    view: '[data-sb-view="artikel"]',
    overlay: (width, scale) => (narrow(width, scale) ? "sb-note-popover" : null),
    prepare: async (page) => {
      await openFootnotePopover(page);
      if (!(await page.evaluate(() => matchMedia("(max-width: 63.99rem)").matches))) await expect(page).toHaveURL(/#fn-1$/);
    },
  },
  { name: "ueber", path: "/ueber/", heading: "Über", view: '[data-sb-view="ueber"]', overlay: null },
  { name: "kontakt", path: "/kontakt/", heading: "Kontakt", view: '[data-sb-view="kontakt"]', overlay: null },
  { name: "impressum", path: "/impressum/", heading: "Impressum Beispieldaten", view: '[data-sb-view="impressum"]', overlay: null },
  { name: "datenschutz", path: "/datenschutz/", heading: "Datenschutz Beispieldaten", view: '[data-sb-view="datenschutz"]', overlay: null },
  { name: "barrierefreiheit", path: "/barrierefreiheit/", heading: "Barrierefreiheit Beispieldaten", view: '[data-sb-view="barrierefreiheit"]', overlay: null },
  // an address that does not exist: the server answers 404 with the site's own page
  { name: "404", path: "/gibt-es-nicht/", status: 404, heading: "Diese Seite gibt es nicht", view: '[data-sb-view="nicht-gefunden"]', overlay: null },
]);
