#!/usr/bin/env node
// og.mjs: share images and their head tags in the site's own build (WEB-09, D96 (a)).
// Writes one page list per language from src/strings.mjs (format: public/sebaro/brand/og/pages.schema.json), then
// runs the export's brand/og/render.mjs on it: PNGs to public/og/, head snippets to build/og-head/<id>.head.html,
// which src/layouts/Base.astro puts into each page's <head>. The look comes from the export's one template
// brand/og/template.html; never copy or edit it. render.mjs fails loud (exit 1, page id named) when a title needs more
// than three lines: then shorten the page's title in src/strings.mjs, never the image's.
// Needs Playwright with Chromium (npx playwright install chromium). Run by `npm run build`; alone: `npm run og`.
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { SITE, PAGES, strings } from "../src/strings.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const render = path.join(root, "public", "sebaro", "brand", "og", "render.mjs");
const work = path.join(root, "build");
fs.mkdirSync(work, { recursive: true });

function entry(page) {
  const s = strings[page.lang];
  const own = s.pages[page.key];
  const e = { id: page.id, url: page.url, title: own.title, description: own.description };
  if (page.type) e.type = page.type;
  if (page.nav && page.key !== page.nav) e.path = [SITE.name, s.nav[page.nav], own.crumb ?? own.title];
  if (own.readingMinutes) e.readingMinutes = own.readingMinutes;
  if (own.date) e.date = own.date;
  return e;
}

let status = 0;
for (const lang of Object.keys(strings)) {
  const pages = PAGES.filter((p) => p.lang === lang).map(entry);
  if (!pages.length) continue;
  const list = {
    $schema: "../public/sebaro/brand/og/pages.schema.json",
    site: { product: SITE.product, name: SITE.name, origin: SITE.origin, lang },
    pages,
  };
  const file = path.join(work, `og-pages.${lang}.json`);
  fs.writeFileSync(file, JSON.stringify(list, null, 2) + "\n");
  const run = spawnSync(process.execPath, [render, "--pages", file, "--out", path.join(root, "public", "og"),
    "--head", path.join(work, "og-head")], { stdio: "inherit" });
  if (run.status !== 0) status = run.status ?? 1;
}
process.exit(status);
