// Every view and every overlay state of Musterapp: light and dark, 320, 390 and 1440 px, at 100 % and, at the
// widest width, real 200 % text; the screen asked for (heading, view, open overlays), axe, no sideways scroll, no
// cut text or control value, no console or CSP error, and the copy's check of a view: its action levels and colours
// (tests/sebaro-checks.ts). Below 840 px the app frame shows one pane and the navigation at the bottom, at 1440 px
// the rail and, for the list, two panes.
import { expect, type Page } from "@playwright/test";
import { checkScreens, type Screen } from "./sebaro-checks";

// overlays fade in (200 ms, also under reduced motion): check them once every animation has ended
const settle = (page: Page) =>
  page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running"));

const press = (name: string) => async (page: Page) => {
  await page.getByRole("button", { name, exact: true }).first().click();
  await settle(page);
};
/** Stores a choice the app reads at its start and loads the page again: a sub-view on a phone has no „Mehr“. */
const stored = (key: string, value: string) => async (page: Page) => {
  await page.evaluate(([k, v]) => localStorage.setItem(k, v), [key, value]);
  await page.reload();
  await page.waitForLoadState("networkidle");
};
const english = stored("sb-lang", "en");

/** Puts `entries` into the app's storage and loads the page again, so the app starts with them. */
const withEntries = (entries: unknown[]) => async (page: Page) => {
  const stored = JSON.stringify({ state: { entries }, version: 0 });
  await page.evaluate((json) => localStorage.setItem("musterapp-entries", json), stored);
  await page.reload();
  await page.waitForLoadState("networkidle");
};

const screens: Screen[] = [
  { name: "liste", path: "/", heading: "Einträge", view: '[data-sb-view="liste"]', overlay: null },
  {
    name: "liste-kein-treffer",
    path: "/",
    heading: "Einträge",
    view: '[data-sb-view="liste"]',
    overlay: null,
    prepare: async (page) => {
      await page.fill("#app-search", "zzz");
      await expect(page.locator("#app-results")).toContainText("Kein Eintrag passt");
    },
  },
  {
    name: "liste-leer",
    path: "/",
    heading: "Einträge",
    view: '[data-sb-view="liste"]',
    overlay: null,
    prepare: async (page) => {
      await withEntries([])(page);
      await expect(page.locator("#app-results")).toContainText("Noch keine Einträge");
    },
  },
  { name: "eintrag", path: "/eintrag/2", heading: "Rosen schneiden", view: '[data-sb-view="eintrag"]', overlay: null },
  {
    name: "eintrag-abgeschlossen",
    path: "/eintrag/2",
    heading: "Rosen schneiden",
    view: '[data-sb-view="eintrag"]',
    overlay: null,
    prepare: async (page) => {
      await page.getByRole("button", { name: "Eintrag abschließen" }).click();
      await page.locator('#app-dlg-finish button[value="confirm"]').click();
      await expect(page.getByRole("main").locator(".sb-callout")).toBeVisible();
      await settle(page);
    },
  },
  {
    name: "eintrag-unbekannt",
    path: "/eintrag/99",
    heading: "Diesen Eintrag gibt es nicht",
    view: '[data-sb-view="eintrag"]',
    overlay: null,
  },
  {
    name: "eintrag-loeschen",
    path: "/eintrag/2",
    heading: "Rosen schneiden",
    overlay: "app-dlg-delete",
    prepare: press("Eintrag löschen"),
  },
  {
    name: "eintrag-abschliessen",
    path: "/eintrag/2",
    heading: "Rosen schneiden",
    overlay: "app-dlg-finish",
    prepare: press("Eintrag abschließen"),
  },
  {
    name: "eintrag-kurzmeldung",
    path: "/eintrag/2",
    heading: "Rosen schneiden",
    overlay: "app-toast",
    prepare: press("Als erledigt markieren"),
  },
  {
    // the „Mehr“ menu of a top-level view: „Hell oder Dunkel“, „Farbton“ and the language
    name: "liste-mehr",
    path: "/",
    heading: "Einträge",
    view: '[data-sb-view="liste"]',
    overlay: "app-more",
    prepare: press("Mehr"),
  },
  {
    name: "liste-warm",
    path: "/",
    heading: "Einträge",
    view: '[data-sb-view="liste"]',
    overlay: null,
    prepare: stored("sb-tone", "warm"),
  },
  { name: "neu", path: "/neu", heading: "Neuer Eintrag", view: '[data-sb-view="formular"]', overlay: null },
  {
    name: "neu-fehler",
    path: "/neu",
    heading: "Neuer Eintrag",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: async (page) => {
      await page.fill("#app-f-effort", "viel");
      await page.locator('#app-form button[type="submit"]').click();
      await expect(page.locator("#app-f-effort-error")).toBeVisible();
    },
  },
  {
    name: "neu-ungesichert",
    path: "/neu",
    heading: "Neuer Eintrag",
    overlay: "app-dlg-unsaved",
    prepare: async (page) => {
      await page.fill("#app-f-title", "Keller aufräumen");
      await page.locator("#app-form").getByRole("button", { name: "Abbrechen" }).click();
      await settle(page);
    },
  },
  {
    // a long value typed into a one-line field runs on inside it; the check counts it in an annotation
    name: "neu-langer-titel",
    path: "/neu",
    heading: "Neuer Eintrag",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: async (page) => {
      await page.fill("#app-f-title", "Steuerunterlagen der letzten drei Jahre sortieren und abheften");
    },
  },
  {
    name: "bearbeiten",
    path: "/bearbeiten/2",
    heading: "Eintrag bearbeiten",
    view: '[data-sb-view="formular"]',
    overlay: null,
  },
  {
    // the longest category word chosen in the select (DE „Gesundheit“): its value must fit the control at 200 %
    name: "bearbeiten-lange-kategorie",
    path: "/bearbeiten/1",
    heading: "Eintrag bearbeiten",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: async (page) => {
      await expect(page.locator("#app-f-cat")).toHaveValue("health");
    },
  },
  {
    name: "einstellungen",
    path: "/einstellungen",
    heading: "Einstellungen",
    view: '[data-sb-view="einstellungen"]',
    overlay: null,
  },
  {
    name: "einstellungen-beispiele",
    path: "/einstellungen",
    heading: "Einstellungen",
    view: '[data-sb-view="einstellungen"]',
    overlay: "app-toast",
    prepare: press("Beispieldaten wiederherstellen"),
  },
  {
    // „About“ with the tile, the name, the version and the sender in English (core rule 29)
    name: "einstellungen-englisch",
    path: "/einstellungen",
    heading: "Settings",
    view: '[data-sb-view="einstellungen"]',
    overlay: null,
    prepare: english,
  },
  { name: "daten", path: "/daten", heading: "Datenarten", view: '[data-sb-view="daten"]', overlay: null },
  {
    name: "daten-englisch",
    path: "/daten",
    heading: "Data types",
    view: '[data-sb-view="daten"]',
    overlay: null,
    prepare: english,
  },
  {
    // a note's digit: below 1024 px (in rem, so also at 200 % text) the note opens over the text, else the page jumps
    name: "daten-beleg",
    path: "/daten",
    heading: "Datenarten",
    view: '[data-sb-view="daten"]',
    overlay: (width, scale) => (width < 1024 * scale ? "div.sb-note-popover" : null),
    prepare: async (page) => {
      await page.getByRole("link", { name: "Beleg 2" }).click();
      await settle(page);
    },
  },
  {
    name: "bearbeiten-englisch",
    path: "/bearbeiten/1",
    heading: "Edit entry",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: english,
  },
  { name: "impressum", path: "/impressum", heading: "Impressum", view: '[data-sb-view="impressum"]', overlay: null },
  {
    name: "datenschutz",
    path: "/datenschutz",
    heading: "Datenschutz",
    view: '[data-sb-view="datenschutz"]',
    overlay: null,
  },
  {
    name: "barrierefreiheit",
    path: "/barrierefreiheit",
    heading: "Barrierefreiheit",
    view: '[data-sb-view="barrierefreiheit"]',
    overlay: null,
  },
  {
    name: "unbekannt",
    path: "/gibt-es-nicht",
    heading: "Diese Ansicht gibt es nicht",
    view: '[data-sb-view="nicht-gefunden"]',
    overlay: null,
  },
];

checkScreens(screens, { viewCheck: "src/sebaro/checks/sb-colour-count.js" });
