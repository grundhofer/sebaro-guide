// Every screen of the window, light and dark, 390 / 480 / 1440 px, 100 % and real 200 % text (sebaro-checks.ts).
// 480 px is the smallest window a desktop app allows (DSK-07); 390 px covers the same frontend as a web app.
import { expect, type Page } from "@playwright/test";
import { checkScreens, type Screen } from "./sebaro-checks";

// an overlay fades in for 200 ms even with reduced motion (BEW-04): check it once it stands
async function settle(page: Page): Promise<void> {
  await page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running"));
}

const openDialog = (id: string): Screen["prepare"] => async (page) => {
  await page.evaluate((dialogId) => {
    document.querySelector<HTMLElement>(`[data-sb-opens="${dialogId}"]`)?.click();
  }, id);
  await expect(page.locator(`#${id}`)).toHaveJSProperty("open", true);
  await settle(page);
};

const screens: Screen[] = [
  { name: "fenster", path: "/" },
  { name: "einstellungen", path: "/#/einstellungen" },
  {
    name: "palette",
    path: "/",
    prepare: async (page) => {
      await page.locator("[data-sb-palette-open='palette']").first().click();
      await expect(page.locator("#palette")).toHaveJSProperty("open", true);
      await settle(page);
    },
  },
  {
    name: "menue",
    path: "/",
    prepare: async (page) => {
      await page.locator("#menue-taste").click();
      await expect(page.locator("#menue [popovertarget='menue-datei']")).toBeFocused();
      await page.keyboard.press("ArrowRight");   // „Datei“ opens beside the menu, or in its place without room
      await expect(page.locator("#menue-datei")).toBeVisible();
      await settle(page);
    },
  },
  { name: "dialog-papierkorb", path: "/", prepare: openDialog("dlg-papierkorb") },
  { name: "dialog-kuerzel", path: "/", prepare: openDialog("dlg-kuerzel") },
  {
    name: "dialog-ungesichert",
    path: "/",
    prepare: async (page) => {
      await page.locator("#reiter-wochenplan").focus();
      await page.keyboard.press("Delete");
      await expect(page.locator("#dlg-ungesichert")).toHaveJSProperty("open", true);
      await settle(page);
    },
  },
];

checkScreens(screens, { widths: [390, 480, 1440] });
