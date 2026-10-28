// Every visible word comes from src/strings.ts (TEC-10, D87; README „every word in src/strings.ts“): no view, no shell
// and no index.html writes a word into its markup, and the store holds no example text of its own (the examples'
// words are `samples` in strings.ts). Read by tests/visible-text.ts; its header names what it does not read.
import { readdirSync, readFileSync } from "node:fs";
import { test, expect } from "@playwright/test";
import { literalWords } from "./visible-text";

const here = (p: string) => new URL(`../${p}`, import.meta.url).pathname;

test("no literal word in the markup of a view, the shell or index.html", () => {
  const files = ["src/main.ts", "index.html", ...readdirSync(here("src/views")).map((f) => `src/views/${f}`)];
  expect(files.flatMap((f) => literalWords(here(f), f))).toEqual([]);
});

test("the store holds only codes, keys and dates, no example text", () => {
  const literals = [...readFileSync(here("src/store.ts"), "utf8").matchAll(/"([^"\n]*)"/g)].map((m) => m[1]);
  expect(literals.filter((l) => !/^([a-z./-]*|\d{4}-\d\d-\d\d)$/.test(l))).toEqual([]);
});
