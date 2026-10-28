// Every visible word comes from src/strings.mjs (TEC-10, D87; README): no page and no layout writes a word into its
// markup; the words come in through {…} expressions. Read by tests/visible-text.ts (the template part of each .astro
// file, after its frontmatter).
import { readdirSync } from "node:fs";
import { test, expect } from "@playwright/test";
import { literalWords } from "./visible-text";

const root = new URL("../src/", import.meta.url).pathname;

test("no literal word in the markup of a page or the layout", () => {
  const files = readdirSync(root, { recursive: true, encoding: "utf8" }).filter((f) => f.endsWith(".astro"));
  expect(files.length).toBeGreaterThan(5);
  expect(files.flatMap((f) => literalWords(root + f, `src/${f}`))).toEqual([]);
});
