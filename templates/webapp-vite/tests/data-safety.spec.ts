// Nothing the user typed or stored is lost without a question: every way out of a form with unsaved changes asks
// first (AKT-11: a link, a hash change, Back, Forward, closing or reloading; DE / EN keeps the draft), and
// „Beispieldaten wiederherstellen“ adds the missing examples without touching the user's entries (AKT-08).
import { test, expect, type Page } from "@playwright/test";

test.use({ reducedMotion: "reduce", colorScheme: "light" });

async function open(page: Page, hash: string) {
  await page.goto(`/${hash}`);
  await page.waitForLoadState("networkidle");
}

const heading = (page: Page) => page.locator("main h1");
const unsaved = (page: Page) => page.locator("#app-dlg-unsaved");

/** A new entry with a title, a category and one sub-step, not saved. */
async function dirtyForm(page: Page) {
  await expect(heading(page)).toHaveText("Neuer Eintrag");
  await page.fill("#app-f-title", "Keller aufräumen");
  await page.selectOption("#app-f-cat", "home");
  await page.fill("#app-f-step", "Regal leeren");
  await page.locator("[data-app-step-add]").click();
  await expect(page.locator("#app-steps")).toContainText("Regal leeren");
}

/** The question is open, the form and what was typed still stand, the address is the form's. */
async function heldBack(page: Page) {
  await expect(unsaved(page)).toHaveJSProperty("open", true);
  await expect(heading(page)).toHaveText("Neuer Eintrag");
  await expect(page.locator("#app-f-title")).toHaveValue("Keller aufräumen");
  expect(new URL(page.url()).hash).toBe("#/neu");
}

test("a hash change (an address typed in) asks first; „Abbrechen“ stays with the draft", async ({ page }) => {
  await open(page, "#/neu");
  await dirtyForm(page);
  await page.evaluate(() => { location.hash = "#/daten"; });
  await heldBack(page);
  await unsaved(page).locator('button[value="cancel"]').click();
  await expect(unsaved(page)).toHaveJSProperty("open", false);
  await expect(page.locator("#app-f-title")).toHaveValue("Keller aufräumen");
  await expect(page.locator("#app-steps")).toContainText("Regal leeren");
});

test("Back asks first; „Verwerfen“ then goes where Back went", async ({ page }) => {
  await open(page, "#/");
  await page.locator('a.sb-primary-action[href="#/neu"]').click();
  await dirtyForm(page);
  await page.goBack();
  await heldBack(page);
  await unsaved(page).locator('button[value="discard"]').click();
  await expect(heading(page)).toHaveText("Einträge");
  await expect(page.locator("main")).not.toContainText("Keller aufräumen");
});

test("Forward asks first; „Sichern“ stores the entry and then goes forward", async ({ page }) => {
  await open(page, "#/neu");
  await page.locator('.sb-site-nav a[href="#/einstellungen"]').click();
  await expect(heading(page)).toHaveText("Einstellungen");
  await page.goBack();
  await dirtyForm(page);
  await page.fill("#app-f-effort", "30");
  await page.goForward();
  await heldBack(page);
  await unsaved(page).locator('button[value="save"]').click();
  await expect(heading(page)).toHaveText("Einstellungen");
  await open(page, "#/");
  await expect(page.locator("main")).toContainText("Keller aufräumen");
});

test("DE / EN keeps every typed value and the unsaved state", async ({ page }) => {
  await open(page, "#/neu");
  await dirtyForm(page);
  await page.fill("#app-f-step", "Kisten holen");
  await page.locator('[data-sb-language-choice] label:has(input[value="en"])').click();
  await expect(heading(page)).toHaveText("New entry");
  await expect(page.locator("#app-f-title")).toHaveValue("Keller aufräumen");
  await expect(page.locator("#app-f-cat")).toHaveValue("home");
  await expect(page.locator("#app-steps")).toContainText("Regal leeren");
  await expect(page.locator("#app-f-step")).toHaveValue("Kisten holen");
  // still unsaved: leaving asks, now in English
  await page.locator("[data-app-cancel]").click();
  await expect(unsaved(page)).toHaveJSProperty("open", true);
  await expect(unsaved(page).locator("h2")).toHaveText("Save changes?");
});

test("closing or reloading with unsaved changes gets the browser's question, without changes none", async ({ page }) => {
  await open(page, "#/neu");
  const asked: string[] = [];
  page.on("dialog", async (d) => { asked.push(d.type()); await d.dismiss(); });
  // clean: reload goes without a question
  await page.reload();
  await page.waitForLoadState("networkidle");
  expect(asked).toEqual([]);
  await dirtyForm(page);
  // dirty: closing asks (the dismissed question keeps the page)
  await page.close({ runBeforeUnload: true });
  await expect.poll(() => asked).toEqual(["beforeunload"]);
});

test("„Beispieldaten wiederherstellen“ adds the missing examples and keeps the user's entries", async ({ page }) => {
  // the user deleted the example „Fenster putzen“, changed „Rosen schneiden“ (now theirs) and added an entry
  await open(page, "#/");
  await page.evaluate(() => {
    const entries = JSON.parse(localStorage.getItem("musterapp-entries") ?? "[]");
    const kept = entries.filter((e: { id: string }) => e.id !== "4");
    const roses = kept.find((e: { id: string }) => e.id === "2");
    Object.assign(roses, { title: "Rosen und Hecke schneiden", demo: false });
    kept.push({ id: "5", title: "Keller aufräumen", category: "home", due: "", effort: 90, note: "", steps: [], state: "open", created: "2026-10-28", demo: false });
    localStorage.setItem("musterapp-entries", JSON.stringify(kept));
    location.hash = "#/einstellungen";
  });
  await page.reload(); // the app reads the storage at its start
  await page.waitForLoadState("networkidle");
  await expect(page.locator("main h1")).toHaveText("Einstellungen");
  await page.locator("[data-app-reset]").click();
  // no dialog: nothing is removed
  expect(await page.evaluate(() => document.querySelectorAll("dialog[open]").length)).toBe(0);
  await expect(page.locator("#app-toast p")).toHaveText("2 Beispiele wiederhergestellt");
  const titles = await page.evaluate(() => JSON.parse(localStorage.getItem("musterapp-entries") ?? "[]").map((e: { title: string }) => e.title));
  expect(titles).toEqual(["Wasser trinken", "Rosen und Hecke schneiden", "Steuerunterlagen sortieren", "Keller aufräumen", "Rosen schneiden", "Fenster putzen"]);
  // „Rückgängig“ takes back only the added examples
  await page.locator("#app-toast .sb-toast__action").click();
  await expect(page.locator("#app-toast")).toBeHidden();
  const afterUndo = await page.evaluate(() => JSON.parse(localStorage.getItem("musterapp-entries") ?? "[]").map((e: { title: string }) => e.title));
  expect(afterUndo).toEqual(["Wasser trinken", "Rosen und Hecke schneiden", "Steuerunterlagen sortieren", "Keller aufräumen"]);
  // adding them again, then a second press finds nothing missing and changes nothing
  await page.locator("[data-app-reset]").click();
  await expect(page.locator("#app-toast p")).toHaveText("2 Beispiele wiederhergestellt");
  await page.locator("[data-app-reset]").click();
  await expect(page.locator("#app-toast p")).toHaveText("Alle Beispiele sind schon da.");
  const twice = await page.evaluate(() => JSON.parse(localStorage.getItem("musterapp-entries") ?? "[]").length);
  expect(twice).toBe(6);
});
