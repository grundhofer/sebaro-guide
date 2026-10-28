// Every visible word comes from src/strings.ts (TEC-10, D87): index.html writes no word into its markup, it holds
// {{key}} markers that vite.config.ts fills from the table. src/main.ts writes its words at run time with t() and the
// demo notes from strings.ts; tests/visible-text.ts does not read DOM calls, so main.ts is checked by review only.
import { test, expect } from "@playwright/test";
import { literalWords } from "./visible-text";

test("no literal word in the markup of index.html", () => {
  expect(literalWords(new URL("../index.html", import.meta.url).pathname, "index.html")).toEqual([]);
});
