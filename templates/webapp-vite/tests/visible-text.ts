// visible-text.ts: finds words written straight into markup instead of coming from the strings module (TEC-10, D87).
// Read are the parts that become visible markup: html`…` templates in .ts files (nested ones too), the template of an
// .astro file (after its frontmatter) and an index.html; what an expression puts in (${…}, {…}, {{key}}) is left out.
// Reported: a text between two tags and a value of aria-label, title, placeholder or alt that holds a letter. Numbers
// and signs alone (08:12, ±0, ·) pass: they are formatted values, not words. Not read: strings that code passes to the
// DOM itself (textContent, el(…)); those files take their words from t() and are named in each template's test.
import { readFileSync } from "node:fs";

const LETTER = /[A-Za-zÀ-ÖØ-öø-ÿß]/;
const HOLE = "\u0000";

/** The literal parts of every html`…` template in TypeScript source, an expression replaced by HOLE. */
function htmlTemplates(src: string): string[] {
  const out: string[] = [];
  // returns the index after the code that ends at an unmatched "}" (or the end), collecting templates on the way
  const code = (i: number): number => {
    let depth = 0;
    while (i < src.length) {
      const c = src[i];
      if (c === "/" && src[i + 1] === "/") { i = src.indexOf("\n", i); if (i < 0) return src.length; continue; }
      if (c === "/" && src[i + 1] === "*") { i = src.indexOf("*/", i) + 2; continue; }
      if (c === '"' || c === "'") { i++; while (i < src.length && src[i] !== c) i += src[i] === "\\" ? 2 : 1; i++; continue; }
      if (c === "`") { const tagged = /\bhtml$/.test(src.slice(Math.max(0, i - 4), i)); i = template(i + 1, tagged); continue; }
      if (c === "{") depth++;
      if (c === "}") { if (depth === 0) return i + 1; depth--; }
      i++;
    }
    return i;
  };
  const template = (i: number, keep: boolean): number => {
    let text = "";
    while (i < src.length && src[i] !== "`") {
      if (src[i] === "\\") { text += src.slice(i, i + 2); i += 2; continue; }
      if (src[i] === "$" && src[i + 1] === "{") { text += HOLE; i = code(i + 2); continue; }
      text += src[i++];
    }
    if (keep) out.push(text);
    return i + 1;
  };
  code(0);
  return out;
}

/** The template of an .astro file with every {…} expression replaced by HOLE. */
function astroTemplate(src: string): string {
  const body = src.replace(/^---[\s\S]*?\n---/, "").replace(/<!--[\s\S]*?-->/g, "").replace(/<(script|style)\b[\s\S]*?<\/\1>/g, "");
  let out = "", depth = 0;
  for (const c of body) {
    if (c === "{") { if (depth++ === 0) out += HOLE; continue; }
    if (c === "}") { depth--; continue; }
    if (depth === 0) out += c;
  }
  return out;
}

/** "name: kind "text"" for every literal word in the visible markup of `file` (`name`: how to call it, e.g. relative). */
export function literalWords(file: string, name = file): string[] {
  const src = readFileSync(file, "utf8");
  let parts: string[];
  if (file.endsWith(".ts")) parts = htmlTemplates(src);
  else if (file.endsWith(".astro")) parts = [astroTemplate(src)];
  else parts = [src.replace(/<!--[\s\S]*?-->/g, "").replace(/<(script|style|svg)\b[\s\S]*?<\/\1>/g, "").replace(/\{\{[^}]*\}\}/g, HOLE)];
  const found: string[] = [];
  for (const part of parts) {
    for (const m of part.matchAll(/>([^<>]*)</g)) {
      const text = m[1].split(HOLE).join(" ").trim();
      if (LETTER.test(text)) found.push(`${name}: text ${JSON.stringify(text)}`);
    }
    for (const m of part.matchAll(/\s(aria-label|title|placeholder|alt)="([^"]*)"/g)) {
      const value = m[2].split(HOLE).join(" ");
      if (LETTER.test(value)) found.push(`${name}: ${m[1]} ${JSON.stringify(value)}`);
    }
  }
  return found;
}
