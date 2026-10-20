// check_a11y.mjs: axe-core (WCAG 2.0/2.1/2.2 A + AA) on every guide page in headless Chromium, light and dark,
// at 390 and 1440 px, plus horizontal overflow and console errors. Exit 1 on any violation that is not waived.
//
//   node tools/check_a11y.mjs                 # all docs/*.html
//   node tools/check_a11y.mjs docs/app.html   # some pages
//
// Waivers live in tools/a11y-waivers.json: {"waivers": [{"page", "rule", "target", "reason"}]}; "target" is a
// substring of the axe node target. A waiver without a reason is an error. Deliberate "Nicht so" specimens that axe
// cannot judge go there with their rule id, never as a blanket waiver.
import { chromium } from "playwright";
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { join, resolve, basename, extname } from "node:path";

const ROOT = resolve(new URL("..", import.meta.url).pathname);
const DOCS = join(ROOT, "docs");
const require = createRequire(import.meta.url);
const AXE = readFileSync(require.resolve("axe-core/axe.min.js"), "utf8");
const TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const RUNS = [
  { width: 1440, height: 900, scheme: "light" }, { width: 1440, height: 900, scheme: "dark" },
  { width: 390, height: 844, scheme: "light" }, { width: 390, height: 844, scheme: "dark" },
];

const waiverFile = JSON.parse(readFileSync(join(ROOT, "tools", "a11y-waivers.json"), "utf8"));
const waivers = waiverFile.waivers || [];
let failed = 0;
for (const w of waivers) {
  if (!w.reason || !w.page || !w.rule || !w.target) { console.log(`error: waiver without page/rule/target/reason: ${JSON.stringify(w)}`); failed++; }
}
const used = new Set();

const args = process.argv.slice(2);
const pages = args.length ? args.map((p) => resolve(p))
  : readdirSync(DOCS).filter((f) => f.endsWith(".html")).sort().map((f) => join(DOCS, f));

// serve docs/ over http like GitHub Pages does (axe reads stylesheets; file:// blocks that)
const TYPES = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".json": "application/json",
  ".svg": "image/svg+xml", ".png": "image/png", ".webp": "image/webp", ".woff2": "font/woff2", ".ico": "image/x-icon",
  ".txt": "text/plain", ".webmanifest": "application/manifest+json" };
const server = createServer((req, res) => {
  const path = join(DOCS, decodeURIComponent(new URL(req.url, "http://x").pathname));
  if (!path.startsWith(DOCS) || !existsSync(path) || statSync(path).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "content-type": TYPES[extname(path)] || "application/octet-stream" });
  res.end(readFileSync(path));
});
await new Promise((ok) => server.listen(0, "127.0.0.1", ok));
const BASE = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch();
for (const file of pages) {
  const page = basename(file);
  for (const run of RUNS) {
    const ctx = await browser.newContext({ viewport: { width: run.width, height: run.height }, colorScheme: run.scheme });
    const tab = await ctx.newPage();
    const errors = [];
    tab.on("pageerror", (e) => errors.push(String(e)));
    tab.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
    await tab.goto(BASE + page, { waitUntil: "load" });
    await tab.waitForTimeout(300);
    await tab.addScriptTag({ content: AXE });
    const result = await tab.evaluate(async (tags) => {
      // eslint-disable-next-line no-undef
      const r = await axe.run(document, { runOnly: { type: "tag", values: tags }, resultTypes: ["violations"] });
      return r.violations.map((v) => ({ id: v.id, help: v.help, nodes: v.nodes.map((n) => n.target.join(" ")) }));
    }, TAGS);
    const overflow = await tab.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    const label = `${page} ${run.width}/${run.scheme}`;
    for (const v of result) {
      for (const target of v.nodes) {
        const w = waivers.find((x) => x.page === page && x.rule === v.id && target.includes(x.target));
        if (w) { used.add(w); continue; }
        console.log(`error: AXE ${label}: ${v.id} (${v.help}) at ${target}`);
        failed++;
      }
    }
    if (overflow > 1) { console.log(`error: OVERFLOW ${label}: page scrolls sideways by ${overflow} px`); failed++; }
    for (const e of errors) { console.log(`error: CONSOLE ${label}: ${e}`); failed++; }
    await ctx.close();
  }
  console.log(`checked ${page}`);
}
await browser.close();
server.close();
for (const w of waivers) if (!used.has(w)) console.log(`warning: unused waiver ${w.page} ${w.rule} ${w.target}`);
console.log(`check_a11y: ${pages.length} pages x ${RUNS.length} runs, ${failed} errors -> ${failed ? "FAIL" : "PASS"}`);
process.exit(failed ? 1 : 0);
