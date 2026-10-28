// Every screen and every overlay state of Musterapp: light and dark, 320, 390 and 1440 px, 100 % and real 200 % text;
// the screen asked for (heading, view, open overlays), axe, no sideways scroll, no cut text or control value, no
// console or CSP error (tests/sebaro-checks.ts).
import { expect, type Page } from "@playwright/test";
import { checkScreens, type Screen } from "./sebaro-checks";

// overlays fade in (200 ms, also under reduced motion, BEW-04): check them once every animation has ended
const settle = (page: Page) => page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running"));

const click = (selector: string) => async (page: Page) => {
  await page.locator(selector).first().click();
  await settle(page);
};

/** Puts `entries` into the app's storage and loads the page again, so the app starts with them. */
const withEntries = (entries: unknown[]) => async (page: Page) => {
  await page.evaluate((json) => localStorage.setItem("musterapp-entries", json), JSON.stringify(entries));
  await page.reload();
  await page.waitForLoadState("networkidle");
};

const screens: Screen[] = [
  { name: "liste", path: "/#/", heading: "Einträge", view: '[data-sb-view="liste"]', overlay: null },
  {
    name: "liste-kein-treffer",
    path: "/#/",
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
    path: "/#/",
    heading: "Einträge",
    view: '[data-sb-view="liste"]',
    overlay: null,
    prepare: async (page) => {
      await withEntries([])(page);
      await expect(page.locator("#app-results")).toContainText("Noch keine Einträge");
    },
  },
  { name: "eintrag", path: "/#/eintrag/2", heading: "Rosen schneiden", view: '[data-sb-view="eintrag"]', overlay: null },
  {
    name: "eintrag-abgeschlossen",
    path: "/#/eintrag/2",
    heading: "Rosen schneiden",
    view: '[data-sb-view="eintrag"]',
    overlay: null,
    prepare: async (page) => {
      await page.locator('[data-sb-opens="app-dlg-finish"]').click();
      await page.locator('#app-dlg-finish button[value="confirm"]').click();
      await expect(page.locator("main .sb-callout")).toBeVisible();
      await settle(page);
    },
  },
  { name: "eintrag-unbekannt", path: "/#/eintrag/99", heading: "Diesen Eintrag gibt es nicht", view: '[data-sb-view="eintrag"]', overlay: null },
  { name: "eintrag-loeschen", path: "/#/eintrag/2", heading: "Rosen schneiden", overlay: "app-dlg-delete", prepare: click('[data-sb-opens="app-dlg-delete"]') },
  { name: "eintrag-abschliessen", path: "/#/eintrag/2", heading: "Rosen schneiden", overlay: "app-dlg-finish", prepare: click('[data-sb-opens="app-dlg-finish"]') },
  { name: "eintrag-kurzmeldung", path: "/#/eintrag/2", heading: "Rosen schneiden", overlay: "app-toast", prepare: click("[data-app-toggle]") },
  { name: "neu", path: "/#/neu", heading: "Neuer Eintrag", view: '[data-sb-view="formular"]', overlay: null },
  {
    name: "neu-fehler",
    path: "/#/neu",
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
    path: "/#/neu",
    heading: "Neuer Eintrag",
    overlay: "app-dlg-unsaved",
    prepare: async (page) => {
      await page.fill("#app-f-title", "Keller aufräumen");
      await page.locator("[data-app-cancel]").click();
      await settle(page);
    },
  },
  {
    // a long value typed into a one-line field runs on inside it (D110); the check counts it in an annotation
    name: "neu-langer-titel",
    path: "/#/neu",
    heading: "Neuer Eintrag",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: async (page) => {
      await page.fill("#app-f-title", "Steuerunterlagen der letzten drei Jahre sortieren und abheften");
    },
  },
  { name: "bearbeiten", path: "/#/bearbeiten/2", heading: "Eintrag bearbeiten", view: '[data-sb-view="formular"]', overlay: null },
  {
    // the longest category word chosen in the select (DE „Gesundheit“): its value must fit the control at 200 %
    name: "bearbeiten-lange-kategorie",
    path: "/#/bearbeiten/1",
    heading: "Eintrag bearbeiten",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: async (page) => {
      await expect(page.locator("#app-f-cat")).toHaveValue("health");
    },
  },
  { name: "einstellungen", path: "/#/einstellungen", heading: "Einstellungen", view: '[data-sb-view="einstellungen"]', overlay: null },
  {
    name: "einstellungen-beispiele",
    path: "/#/einstellungen",
    heading: "Einstellungen",
    view: '[data-sb-view="einstellungen"]',
    overlay: "app-toast",
    prepare: click("[data-app-reset]"),
  },
  { name: "daten", path: "/#/daten", heading: "Datenarten", view: '[data-sb-view="daten"]', overlay: null },
  {
    name: "daten-englisch",
    path: "/#/daten",
    heading: "Data types",
    view: '[data-sb-view="daten"]',
    overlay: null,
    prepare: click('[data-sb-language-choice] label:has(input[value="en"])'),
  },
  {
    name: "bearbeiten-englisch",
    path: "/#/bearbeiten/1",
    heading: "Edit entry",
    view: '[data-sb-view="formular"]',
    overlay: null,
    prepare: click('[data-sb-language-choice] label:has(input[value="en"])'),
  },
  { name: "impressum", path: "/#/impressum", heading: "Impressum", view: '[data-sb-view="impressum"]', overlay: null },
  { name: "datenschutz", path: "/#/datenschutz", heading: "Datenschutz", view: '[data-sb-view="datenschutz"]', overlay: null },
  { name: "barrierefreiheit", path: "/#/barrierefreiheit", heading: "Barrierefreiheit", view: '[data-sb-view="barrierefreiheit"]', overlay: null },
  { name: "unbekannt", path: "/#/gibt-es-nicht", heading: "Diese Ansicht gibt es nicht", view: '[data-sb-view="nicht-gefunden"]', overlay: null },
];

checkScreens(screens);
