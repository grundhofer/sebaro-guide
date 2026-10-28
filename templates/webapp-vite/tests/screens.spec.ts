// Every screen and every overlay state of Musterapp: light and dark, 320, 390 and 1440 px, 100 % and real 200 % text;
// axe, no sideways scroll, no cut text, no console or CSP error (tests/sebaro-checks.ts).
import type { Page } from "@playwright/test";
import { checkScreens, type Screen } from "./sebaro-checks";

// overlays fade in (200 ms, also under reduced motion, BEW-04): check them once every animation has ended
const settle = (page: Page) => page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running"));

const click = (selector: string) => async (page: Page) => {
  await page.locator(selector).first().click();
  await settle(page);
};

const screens: Screen[] = [
  { name: "liste", path: "/#/" },
  {
    name: "liste-kein-treffer",
    path: "/#/",
    prepare: async (page) => {
      await page.fill("#app-search", "zzz");
    },
  },
  { name: "eintrag", path: "/#/eintrag/2" },
  { name: "eintrag-loeschen", path: "/#/eintrag/2", prepare: click('[data-sb-opens="app-dlg-delete"]') },
  { name: "eintrag-abschliessen", path: "/#/eintrag/2", prepare: click('[data-sb-opens="app-dlg-finish"]') },
  { name: "eintrag-kurzmeldung", path: "/#/eintrag/2", prepare: click("[data-app-toggle]") },
  { name: "neu", path: "/#/neu" },
  {
    name: "neu-fehler",
    path: "/#/neu",
    prepare: async (page) => {
      await page.fill("#app-f-effort", "viel");
      await page.locator('#app-form button[type="submit"]').click();
    },
  },
  {
    name: "neu-ungesichert",
    path: "/#/neu",
    prepare: async (page) => {
      await page.fill("#app-f-title", "Keller aufräumen");
      await page.locator("[data-app-cancel]").click();
      await settle(page);
    },
  },
  { name: "bearbeiten", path: "/#/bearbeiten/2" },
  { name: "einstellungen", path: "/#/einstellungen" },
  { name: "daten", path: "/#/daten" },
  { name: "daten-englisch", path: "/#/daten", prepare: click('[data-sb-language-choice] label:has(input[value="en"])') },
  { name: "impressum", path: "/#/impressum" },
  { name: "datenschutz", path: "/#/datenschutz" },
  { name: "barrierefreiheit", path: "/#/barrierefreiheit" },
  { name: "unbekannt", path: "/#/gibt-es-nicht" },
];

checkScreens(screens);
