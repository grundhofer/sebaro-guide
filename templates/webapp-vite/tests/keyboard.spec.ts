// The four fixed tasks by keyboard alone (ZUG-08): create, delete through the dialog, open a claim (evidence),
// switch light/dark; plus Escape and focus return (ZUG-06), the form's errors (STA-03, EIN-02), the dialog before
// leaving unsaved changes (AKT-11), the toast's „Rückgängig“ (EBE-05) and DE / EN without a reload (WEB-10, D102).
// Last, a class check: every class on every screen is sebaro's (and exists in sebaro.css) or the app's own (app-).
import { readFileSync, readdirSync } from "node:fs";
import { test, expect, type Page } from "@playwright/test";

test.use({ reducedMotion: "reduce", colorScheme: "light" });

/** Presses Tab until the focused element matches the selector (at most 120 presses). */
async function tabTo(page: Page, selector: string) {
  for (let i = 0; i < 120; i++) {
    if (await page.evaluate((s) => !!document.activeElement?.matches(s), selector)) return;
    await page.keyboard.press("Tab");
  }
  throw new Error(`Tab never reached ${selector}`);
}

async function open(page: Page, hash: string) {
  await page.goto(`/${hash}`);
  await page.waitForLoadState("networkidle");
}

test("create an entry by keyboard, with the errors first", async ({ page }) => {
  await open(page, "#/");
  await tabTo(page, 'a.sb-primary-action[href="#/neu"]');
  await page.keyboard.press("Enter");
  await expect(page.locator("main h1")).toHaveText("Neuer Eintrag");
  await expect(page.locator("main h1")).toBeFocused();
  // the primary action stays enabled; its press names what is missing and focuses the first field (STA-03)
  await tabTo(page, '#app-form button[type="submit"]');
  await page.keyboard.press("Enter");
  await expect(page.locator("#app-f-title")).toBeFocused();
  await expect(page.locator("#app-f-title-error")).toHaveText("Titel fehlt.");
  await expect(page.locator("#app-f-effort-error")).toHaveText("Aufwand fehlt.");
  await expect(page.locator("#app-f-title")).toHaveAttribute("aria-invalid", "true");
  await page.keyboard.type("Keller aufräumen");
  await tabTo(page, "#app-f-effort");
  await page.keyboard.type("90");
  await page.keyboard.press("Enter");
  await expect(page.locator("main h1")).toHaveText("Keller aufräumen");
  await expect(page.locator("main h1")).toBeFocused();
});

test("delete through the dialog: Escape returns focus, „Löschen“ removes", async ({ page }) => {
  await open(page, "#/eintrag/4");
  await tabTo(page, '[data-sb-opens="app-dlg-delete"]');
  await page.keyboard.press("Enter");
  const dialog = page.locator("#app-dlg-delete");
  await expect(dialog).toBeVisible();
  await expect(dialog.locator('button[value="cancel"]')).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(page.locator('[data-sb-opens="app-dlg-delete"]')).toBeFocused();
  await page.keyboard.press("Enter");
  await page.keyboard.press("Tab");
  await expect(dialog.locator('button[value="confirm"]')).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.locator("main h1")).toHaveText("Einträge");
  await expect(page.locator("main")).not.toContainText("Fenster putzen");
});

test("the final step that deletes nothing asks like a deletion and closes the entry", async ({ page }) => {
  await open(page, "#/eintrag/2");
  await tabTo(page, '[data-sb-opens="app-dlg-finish"]');
  await expect(page.locator('[data-sb-opens="app-dlg-finish"] svg')).toHaveCount(0); // no trash (FOR-04)
  await page.keyboard.press("Enter");
  await page.keyboard.press("Tab");
  await page.keyboard.press("Enter");
  await expect(page.locator("main")).toContainText("abgeschlossen");
  await expect(page.locator("[data-app-toggle]")).toHaveCount(0);
});

test("unsaved changes ask „Abbrechen“ · „Verwerfen“ · „Sichern“, Sichern last", async ({ page }) => {
  await open(page, "#/neu");
  await page.locator("#app-f-title").focus();
  await page.keyboard.type("Keller aufräumen");
  await tabTo(page, "[data-app-cancel]");
  await page.keyboard.press("Enter");
  const actions = page.locator("#app-dlg-unsaved .sb-dialog__actions button");
  await expect(actions).toHaveText(["Abbrechen", "Verwerfen", "Sichern"]);
  await expect(page.locator("#app-dlg-unsaved .sb-danger-action")).toHaveText("Verwerfen");
  await page.keyboard.press("Escape");
  await expect(page.locator("[data-app-cancel]")).toBeFocused();
  await page.keyboard.press("Enter");
  await page.keyboard.press("Tab");
  await page.keyboard.press("Enter"); // Verwerfen
  await expect(page.locator("main h1")).toHaveText("Einträge");
});

test("mark as done shows a toast; „Rückgängig“ by keyboard takes it back", async ({ page }) => {
  await open(page, "#/eintrag/1");
  await tabTo(page, "[data-app-toggle]");
  await page.keyboard.press("Enter");
  const toast = page.locator("#app-toast");
  await expect(toast).toBeVisible();
  await expect(toast.locator("p")).toHaveText("„Wasser trinken“ erledigt");
  await expect(page.locator("main dl")).toContainText("erledigt");
  await tabTo(page, "#app-toast .sb-toast__action");
  await page.keyboard.press("Enter");
  await expect(toast).toBeHidden();
  await expect(page.locator("main dl")).toContainText("offen");
});

test("„Hell oder Dunkel“ by keyboard switches and announces", async ({ page }) => {
  await open(page, "#/");
  await tabTo(page, ".sb-theme-button");
  await page.keyboard.press("Enter");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("[data-sb-theme-status]")).toHaveText("Dunkel ist an.");
  await page.keyboard.press("Enter");
  await expect(page.locator("html")).not.toHaveAttribute("data-theme", /./);
});

test("open a claim row (evidence) by keyboard", async ({ page }) => {
  await open(page, "#/daten");
  const toggle = page.locator('.sb-claim-row__toggle[aria-controls="app-n-bild"]');
  await tabTo(page, '.sb-claim-row__toggle[aria-controls="app-n-bild"]');
  await page.keyboard.press("Enter");
  await expect(toggle).toHaveAttribute("aria-expanded", "true");
  await expect(page.locator("#app-n-bild")).toBeVisible();
});

test("search, filter chips and the empty state", async ({ page }) => {
  await open(page, "#/");
  await page.locator("#app-search").focus();
  await page.keyboard.type("zzz");
  await expect(page.locator("#app-results")).toContainText("Kein Eintrag passt");
  await tabTo(page, "[data-app-reset-filter]");
  await page.keyboard.press("Enter");
  await expect(page.locator("#app-search")).toHaveValue("");
  await expect(page.locator("#app-search")).toBeFocused();
  await tabTo(page, '[data-app-filter="done"]');
  await page.keyboard.press("Enter");
  await expect(page.locator("#app-results .sb-list-row")).toHaveCount(1);
});

test("DE / EN swaps every word without a reload and keeps the choice", async ({ page }) => {
  await open(page, "#/");
  await page.evaluate(() => ((window as unknown as { marker: number }).marker = 1));
  await tabTo(page, '[data-sb-language-choice] input[value="de"]');
  await page.keyboard.press("ArrowRight");
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page.locator("main h1")).toHaveText("Entries");
  await expect(page.locator(".sb-site-nav a")).toHaveText("Settings");
  await expect(page.locator('[data-sb-language-choice] input[value="en"]')).toBeFocused();
  expect(await page.evaluate(() => (window as unknown as { marker?: number }).marker)).toBe(1);
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page.locator(".sb-theme-button")).toHaveText("Light or dark");
});

test("only sebaro's classes (that exist) and the app's own app-* classes", async ({ page }) => {
  // every class the export itself names (its CSS, scripts and inline brand files) …
  const root = new URL("../public/sebaro/", import.meta.url);
  const known = readdirSync(root, { recursive: true, encoding: "utf8" })
    .filter((f) => /\.(css|js|svg)$/.test(f))
    .map((f) => readFileSync(new URL(f, root), "utf8"))
    .join("\n");
  // … and the classes the guide's Bauteile markup writes although no rule of sebaro.css styles them (hooks)
  const FROM_BAUTEILE = ["sb-danger-action--outlined", "sb-diff__code"];
  const routes = ["#/", "#/eintrag/2", "#/neu", "#/einstellungen", "#/daten", "#/impressum", "#/gibt-es-nicht"];
  const bad = new Set<string>();
  for (const r of routes) {
    await open(page, r);
    const classes = await page.evaluate(() => [...new Set([...document.querySelectorAll("[class]")].flatMap((e) => [...e.classList]))]);
    for (const c of classes) {
      if (c.startsWith("app-")) continue;
      if (FROM_BAUTEILE.includes(c)) continue;
      if (!c.startsWith("sb-") || !new RegExp(`${c}(?![\\w-])`).test(known)) bad.add(`${r} ${c}`);
    }
  }
  expect([...bad]).toEqual([]);
});
