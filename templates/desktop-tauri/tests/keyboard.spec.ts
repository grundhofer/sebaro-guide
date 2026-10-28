// The window by keyboard alone (ZUG-06, ZUG-08, DSK-09, NAV-09): the fixed shortcuts reach their targets through
// sb-window.js, Escape closes and focus returns. On macOS the chords use ⌘, elsewhere Strg (sb-window.js reads the
// platform from the user agent in a browser; a Tauri app sets html[data-sb-platform]).
import { test, expect, type Page } from "@playwright/test";

const mac = process.platform === "darwin";
const MOD = mac ? "Meta" : "Control";
const SIDEBAR = mac ? "Control+Meta+s" : "Control+Alt+s";
const TRASH = mac ? "Meta+Backspace" : "Delete";

async function load(page: Page, path = "/") {
  await page.goto(path);
  await page.waitForLoadState("networkidle");
  await page.evaluate(() => document.fonts.ready.then(() => true));
}

test("⌘K / Strg+K opens the palette, Escape closes it and focus returns", async ({ page }) => {
  await load(page);
  await page.locator("#neue-notiz").focus();
  await page.keyboard.press(`${MOD}+k`);
  await expect(page.locator("#palette")).toHaveJSProperty("open", true);
  await expect(page.locator("#palette input")).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(page.locator("#palette")).toHaveJSProperty("open", false);
  await expect(page.locator("#neue-notiz")).toBeFocused();
});

test("a palette option runs: „Dunkel“ sets the theme (DSK-05) and the check follows", async ({ page }) => {
  await load(page);
  await page.keyboard.press(`${MOD}+k`);
  await page.keyboard.type("Dunkel");
  await page.keyboard.press("Enter");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("#menue-hell [data-sb-theme-choice='dark']")).toHaveAttribute("aria-checked", "true");
});

test("⌘, / Strg+, opens the settings view, Escape leads back", async ({ page }) => {
  await load(page);
  await page.locator("#neue-notiz").focus();
  await page.keyboard.press(`${MOD}+Comma`);
  await expect(page).toHaveURL(/#\/einstellungen$/);
  await expect(page.locator("#einstellungen-h")).toBeFocused();
  await expect(page.locator("#ansicht-haupt")).toBeHidden();
  await page.keyboard.press("Escape");
  await expect(page).toHaveURL(/#\/$/);
  await expect(page.locator("#zu-einstellungen")).toBeFocused();
});

test("F6 and ⇧F6 move through the window's areas", async ({ page }) => {
  await load(page);
  await page.locator("#werkzeug-seite").focus();
  await page.keyboard.press("F6");
  expect(await page.evaluate(() => !!document.activeElement?.closest("#seite"))).toBe(true);
  await page.keyboard.press("F6");
  expect(await page.evaluate(() => !!document.activeElement?.closest("#inhalt"))).toBe(true);
  await page.keyboard.press("Shift+F6");
  expect(await page.evaluate(() => !!document.activeElement?.closest("#seite"))).toBe(true);
});

test("⌃⌘S / Strg+Alt+S hides and shows the sidebar (DSK-04)", async ({ page }) => {
  await load(page);
  await page.locator("#neue-notiz").focus();
  await page.keyboard.press(SIDEBAR);
  await expect(page.locator("#seite")).toBeHidden();
  await expect(page.locator("#werkzeug-seite")).toHaveAttribute("aria-expanded", "false");
  await page.keyboard.press(SIDEBAR);
  await expect(page.locator("#seite")).toBeVisible();
});

test("closing a changed tab asks: Abbrechen keeps it, Verwerfen closes it (AKT-11)", async ({ page }) => {
  await load(page);
  const tab = page.locator("#reiter-wochenplan");
  await tab.focus();
  await page.keyboard.press("Delete");
  const dialog = page.locator("#dlg-ungesichert");
  await expect(dialog).toHaveJSProperty("open", true);
  await expect(dialog.locator("button[value='cancel']")).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(dialog).toHaveJSProperty("open", false);
  await expect(tab).toBeFocused();
  await page.keyboard.press("Delete");
  await dialog.locator("button[value='discard']").click();
  await expect(tab).toHaveCount(0);
  await expect(page.locator("#stand")).toHaveText("Alles gesichert.");
});

test("⌘⌫ / Entf asks before a note goes to the bin (AKT-08), then it is gone", async ({ page }) => {
  await load(page);
  await page.locator("#baum [data-note='umzug']").click();
  await page.keyboard.press(TRASH);
  const dialog = page.locator("#dlg-papierkorb");
  await expect(dialog).toHaveJSProperty("open", true);
  await expect(page.locator("#dlg-papierkorb-t")).toHaveText("„Umzug Checkliste“ in den Papierkorb legen?");
  await dialog.locator("button[value='confirm']").click();
  await expect(page.locator("#baum [data-note='umzug']")).toHaveCount(0);
});

test("⌘N / Strg+N is the primary action: a new note opens in a tab", async ({ page }) => {
  await load(page);
  await page.locator("#werkzeug-seite").focus();
  await page.keyboard.press(`${MOD}+n`);
  await expect(page.locator("#reiter-neu-1")).toHaveAttribute("aria-selected", "true");
  await expect(page.locator("#pfad-notiz")).toHaveText("Neue Notiz 1");
});

test("F10 opens „Menü“ on its first item, Escape gives focus back", async ({ page }) => {
  await load(page);
  await page.locator("#neue-notiz").focus();
  await page.keyboard.press("F10");
  await expect(page.locator("#menue [popovertarget='menue-datei']")).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(page.locator("#neue-notiz")).toBeFocused();
});
