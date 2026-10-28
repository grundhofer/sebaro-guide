// Negative controls for the control checks of sebaro-checks.ts: small fixture pages (tests/fixtures/, not sebaro
// pages) with cuts the helper must find and parts it must leave alone. A fixture is loaded with setContent, so no
// server and no sebaro file is involved.
import { readFileSync } from "node:fs";
import { test, expect, type Page } from "@playwright/test";
import { collectControlCuts } from "./sebaro-checks";

const load = async (page: Page, name: string) => {
  await page.setViewportSize({ width: 600, height: 600 });
  await page.setContent(readFileSync(new URL(`fixtures/${name}`, import.meta.url), "utf8"));
  return page.evaluate(collectControlCuts);
};

test("a frame cuts a field whose own text D110 / D111 allows", async ({ page }) => {
  const { cut, allowed } = await load(page, "control-frame.html");
  // the field itself may scroll or end in „…“ (counted), the frame around it may not cut it
  expect(allowed.map((line) => line.replace(/\d+ px/, "N px"))).toEqual([
    "#suche placeholder ends in „…“ beside its label (D111 (3))",
    "#titel runs on N px inside its field (D110, D111 (4))",
    "#frei placeholder ends in „…“ beside its label (D111 (3))",
  ]);
  expect(cut.map((c) => [c.at, c.kind])).toEqual([
    ["#suche", "placeholder cut by the frame div.frame"],
    ["#titel", "value cut by the frame div.frame"],
  ]);
});

test("a textarea value is cut by the textarea and by a frame, not where it scrolls", async ({ page }) => {
  const { cut, allowed } = await load(page, "textarea.html");
  expect(allowed).toEqual([]);
  expect(cut.map((c) => [c.at, c.kind])).toEqual([
    ["#eng", "textarea value"],
    ["#gerahmt", "textarea value cut by the frame div.frame"],
  ]);
  expect(cut.every((c) => c.over > 1)).toBe(true);
});
