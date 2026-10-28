// Sizes come from sebaro's tokens (TEC-01): a length written in the app's own CSS needs the comment „no sebaro token“
// (saying why) on its line or above it in the same block of lines (up to the last empty line), and a media or container
// query steps in rem or em, so it follows the reader's text size. 0 needs no unit and passes.
import { readFileSync } from "node:fs";
import { test, expect } from "@playwright/test";

const CSS_FILES = ["public/css/site.css"];

const LENGTH = /(?<![\w-])\d*\.?\d+(px|rem|em|ch|vw|vh|vi|vb|vmin|vmax|cqi|cqw)\b/;

function untokenedLengths(file: string): string[] {
  const found: string[] = [];
  let inComment = false, said = "";
  readFileSync(file, "utf8").split("\n").forEach((line, n) => {
    if (!line.trim()) { said = ""; return; }
    let code = "";
    for (let i = 0; i < line.length; i++) {
      if (!inComment && line.startsWith("/*", i)) { inComment = true; i++; continue; }
      if (inComment && line.startsWith("*/", i)) { inComment = false; i++; continue; }
      if (inComment) said += line[i]; else code += line[i];
    }
    if (!LENGTH.test(code)) return;
    const where = `${file.split("/").slice(-2).join("/")}:${n + 1}: ${code.trim()}`;
    if (/@(media|container)/.test(code) && /\d(px|ch|vw|vh)\b/.test(code)) found.push(`${where} (a query steps in rem or em)`);
    else if (!/no sebaro token/.test(said)) found.push(where);
  });
  return found;
}

test("every length in the app's own CSS is a token or says why not; queries step in rem or em", () => {
  expect(CSS_FILES.flatMap((f) => untokenedLengths(new URL(`../${f}`, import.meta.url).pathname))).toEqual([]);
});
