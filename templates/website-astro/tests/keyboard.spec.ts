// Keyboard paths of the website (ZUG-06, ZUG-08, WEB-02, FAR-15, BEL-02, BEL-07, WEB-10).
import { test, expect } from "@playwright/test";

test("the skip link comes first and leads to the content", async ({ page }) => {
  await page.goto("/");
  await page.keyboard.press("Tab");
  const skip = page.locator(".sb-skip-link");
  await expect(skip).toBeFocused();
  await expect(skip).toHaveText("Zum Inhalt");
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/#inhalt$/);
});

test("„Hell oder Dunkel“ switches by keyboard, is announced and kept, twice returns to the system", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");
  const button = page.locator(".sb-theme-button");
  await button.focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("[data-sb-theme-status]")).toHaveText("Dunkel ist an.");
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.locator(".sb-theme-button").focus();
  await page.keyboard.press("Space");
  await expect(page.locator("html")).not.toHaveAttribute("data-theme", /.+/);
  expect(await page.evaluate(() => localStorage.getItem("sb-theme"))).toBeNull();
});

test("the English start page says „Light or dark“ and links back to the German page", async ({ page }) => {
  await page.goto("/en/");
  await expect(page.locator(".sb-theme-button")).toHaveText("Light or dark");
  await expect(page.locator('.sb-language-switch a[hreflang="de"]')).toHaveAttribute("href", "/");
  await expect(page.locator('.sb-language-switch a[aria-current="true"]')).toHaveText("EN");
  // a page that exists only in German: EN is grey text, not a link
  await page.goto("/apps/");
  await expect(page.locator(".sb-language-switch a", { hasText: "EN" })).toHaveCount(0);
  await expect(page.locator(".sb-language-switch__missing")).toContainText("diese Seite gibt es nicht auf Englisch");
});

test("„Farbton: Warm“ in the footer is chosen by keyboard and kept", async ({ page }) => {
  await page.goto("/");
  const cool = page.locator('input[name="sb-tone"][value="cool"]');
  await cool.focus();
  await page.keyboard.press("ArrowRight");
  await expect(page.locator("html")).toHaveAttribute("data-sb-tone", "warm");
  await expect(page.locator("[data-sb-tone-status]")).toHaveText("Farbton Warm ist an.");
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-sb-tone", "warm");
});

test("wide: a footnote number moves focus to its note, its back link back to the number", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/projekte/liste-als-csv/");
  await page.locator("#fnref-1-2").focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("#fn-1")).toBeFocused();
  await page.locator('#fn-1 .sb-note__back[href="#fnref-1-2"]').focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("#fnref-1-2")).toBeFocused();
});

test("narrow: a footnote number opens the popover, Escape closes it and focus returns", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/projekte/liste-als-csv/");
  const ref = page.locator("#fnref-2");
  await ref.focus();
  await page.keyboard.press("Enter");
  const pop = page.locator("#sb-note-popover");
  await expect(pop).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(pop).toBeHidden();
  await expect(ref).toBeFocused();
});

test("no request leaves the site (HAL-09)", async ({ page }) => {
  const foreign: string[] = [];
  page.on("request", (r) => { if (!r.url().startsWith("http://127.0.0.1")) foreign.push(r.url()); });
  for (const path of ["/", "/en/", "/projekte/liste-als-csv/", "/kontakt/"]) await page.goto(path);
  expect(foreign).toEqual([]);
});
