// Every screen of the window, light and dark, 390 / 480 / 1440 px, 100 % and real 200 % text (sebaro-checks.ts):
// the screen asked for (heading, view, open overlays), axe, no sideways scroll, no cut text or control value, no
// console or CSP error. 480 px is the smallest window a desktop app allows (DSK-07); 390 px covers the same frontend
// as a web app.
import { expect, type Page } from "@playwright/test";
import { checkScreens, type Screen } from "./sebaro-checks";

// an overlay fades in for 200 ms even with reduced motion (BEW-04): check it once it stands
async function settle(page: Page): Promise<void> {
  await page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running"));
}

/** A click by script: in a narrow window the sidebar and the menu are closed, the app still answers the click. */
const press = (page: Page, selector: string) =>
  page.evaluate((s) => { document.querySelector<HTMLElement>(s)!.click(); }, selector);

const openDialog = (id: string): Screen["prepare"] => async (page) => {
  await press(page, `[data-sb-opens="${id}"]`);
  await expect(page.locator(`#${id}`)).toHaveJSProperty("open", true);
  await settle(page);
};

/** „Umzug Checkliste“ into the bin through its dialog, then the bin opened in the tree. */
async function binWithNote(page: Page): Promise<void> {
  await press(page, "#baum [data-note='umzug']");
  await press(page, "[data-sb-opens='dlg-papierkorb']");
  await press(page, "#dlg-papierkorb button[value='confirm']");
  await expect(page.locator("#baum [data-trashed='umzug']")).toHaveCount(1);
  await press(page, "#baum [data-bin]");
  await expect(page.locator("#baum [data-bin]")).toHaveAttribute("aria-expanded", "true");
}

const MAIN = "#ansicht-haupt:not([hidden])";

const screens: Screen[] = [
  { name: "fenster", path: "/", heading: "Wochenplan", view: MAIN, overlay: null },
  { name: "einstellungen", path: "/#/einstellungen", heading: "Einstellungen", view: "#ansicht-einstellungen:not([hidden])", overlay: null },
  {
    name: "palette",
    path: "/",
    heading: "Wochenplan",
    overlay: "palette",
    prepare: async (page) => {
      await page.locator("[data-sb-palette-open='palette']").first().click();
      await expect(page.locator("#palette")).toHaveJSProperty("open", true);
      await settle(page);
    },
  },
  {
    name: "menue",
    path: "/",
    heading: "Wochenplan",
    overlay: ["menue", "menue-datei"],
    prepare: async (page) => {
      await page.locator("#menue-taste").click();
      await expect(page.locator("#menue [popovertarget='menue-datei']")).toBeFocused();
      await page.keyboard.press("ArrowRight");   // „Datei“ opens beside the menu, or in its place without room
      await expect(page.locator("#menue-datei")).toBeVisible();
      await settle(page);
    },
  },
  { name: "dialog-papierkorb", path: "/", heading: "Wochenplan", overlay: "dlg-papierkorb", prepare: openDialog("dlg-papierkorb") },
  { name: "dialog-kuerzel", path: "/", heading: "Wochenplan", overlay: "dlg-kuerzel", prepare: openDialog("dlg-kuerzel") },
  {
    name: "dialog-ungesichert",
    path: "/",
    heading: "Wochenplan",
    overlay: "dlg-ungesichert",
    prepare: async (page) => {
      await page.locator("#reiter-wochenplan").focus();
      await page.keyboard.press("Delete");
      await expect(page.locator("#dlg-ungesichert")).toHaveJSProperty("open", true);
      await settle(page);
    },
  },
  {
    // a note in the bin, chosen in the tree: the inspector shows where it came from and „Zurücklegen“
    name: "papierkorb-notiz",
    path: "/",
    heading: "Einkauf",
    view: MAIN,
    overlay: null,
    prepare: async (page) => {
      await binWithNote(page);
      await press(page, "#baum [data-trashed='umzug']");
      await expect(page.locator("#zuruecklegen")).not.toHaveAttribute("hidden");
      await expect(page.locator("#menue-zuruecklegen")).not.toHaveAttribute("aria-disabled");
      await settle(page);
    },
  },
  {
    name: "dialog-leeren",
    path: "/",
    heading: "Einkauf",
    overlay: "dlg-leeren",
    prepare: async (page) => {
      await binWithNote(page);
      await openDialog("dlg-leeren")!(page);
      await expect(page.locator("#dlg-leeren-x")).toContainText("endgültig gelöscht");
    },
  },
  {
    // every tab closed: the window says so and has no heading of a document (D108: the counter line keeps its place)
    name: "keine-notiz",
    path: "/",
    heading: null,
    view: MAIN,
    overlay: null,
    prepare: async (page) => {
      await page.evaluate(() => localStorage.setItem("app-autosave", "on"));   // a changed tab closes without asking
      await page.reload();
      await page.waitForLoadState("networkidle");
      for (const id of ["wochenplan", "einkauf"]) {
        await page.locator(`#reiter-${id}`).focus();
        await page.keyboard.press("Delete");
      }
      await expect(page.locator(".sb-doc-tabs__none")).toBeVisible();
    },
  },
];

checkScreens(screens, {
  widths: [390, 480, 1440],
  // placeholders of sebaro's parts whose width does not grow with the text; the words are the guide's own
  controlWaivers: [
    {
      at: "#suche", text: "Suchen …", scale: 2,
      reason: "the sidebar keeps sebaro's 240 px at 200 % text (NAV-04, D108); its sb-search frame leaves less than the word „Suchen …“ needs (workshop request)",
    },
    {
      at: 'input[name=""]', text: "Befehl oder Einstellung suchen", scale: 2,
      reason: "the placeholder of sb-command-palette as on docs/desktop.html; at 200 % text it is wider than the palette's field on every window width (workshop request)",
    },
  ],
});
