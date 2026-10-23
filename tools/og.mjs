#!/usr/bin/env node
// og.mjs: the guide's share images (D96 (a), WEB-09), rendered from the guide's own page list with the exported
// docs/sebaro/brand/og/render.mjs. The template and the script come only from the export; this file never copies,
// fills or edits the template, it only calls the script and moves its output into place.
//
//   python3 tools/build.py            # writes src/og/pages.json from the pages (h1, meta description)
//   node tools/og.mjs                 # renders docs/og/<id>.png and src/og/head/<id>.head.html + head.json
//   python3 tools/build.py            # copies the snippets into each page's guide:og block
//   node tools/og.mjs --check         # CI: renders again into a temporary folder and compares (below)
//   node tools/og.mjs --check --png-bytes   # also on the PNG bytes (only on the machine that rendered them)
//
// Render: render.mjs writes into a temporary folder first; only when it exits 0 for every page are docs/og/ and
// src/og/head/ replaced (stale images of removed pages go with them), and src/og/head/inputs.json records the sha256
// of every input (the page list, template, script, schema, tokens, fonts, sprite, tile and lockups), which
// tools/check_site.py compares (OG, a warning when an input changed since the render). A failing page (title too long,
// a character sebaro Sans lacks, a ground that is not color.bg light ...) leaves everything as it was: exit 1.
//
// Check: the fresh render must pass render.mjs' own checks on this machine (exit 0); every head snippet and head.json
// must equal the committed ones byte for byte (they are text and do not depend on fonts); docs/og/ must hold exactly
// the pages' PNGs. inputs.json is compared but only reported (note): an input that changed without changing a snippet
// (a synced token or font) is check_site.py's OG warning, so a sync PR is not blocked. The PNG bytes are compared and
// reported, but they fail the check only with --png-bytes: Linux and macOS draw the same fonts with slightly
// different pixels, so CI never fails on them.
// Exit codes: 0 ok · 1 render failed or something differs · 2 usage error or missing file. Needs Node 20+ and Playwright
// with Chromium (npm ci, then npx playwright install chromium), Chromium only (D96 (b)).
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SEBARO = path.join(ROOT, "docs", "sebaro");
const RENDER = path.join(SEBARO, "brand", "og", "render.mjs");
const PAGES = path.join(ROOT, "src", "og", "pages.json");
const OUT = path.join(ROOT, "docs", "og");
const HEAD = path.join(ROOT, "src", "og", "head");
const STAMP = "inputs.json";

const rel = (p) => path.relative(ROOT, p).split(path.sep).join("/");
const sha = (p) => createHash("sha256").update(readFileSync(p)).digest("hex");
const list = (dir, ext) => (existsSync(dir) ? readdirSync(dir).filter((n) => n.endsWith(ext)).sort() : []);

// every file the images and snippets are made from (render.mjs finds them relative to itself, spec/09 §18.1)
function inputs() {
  const files = [PAGES, RENDER, path.join(SEBARO, "brand", "og", "template.html"),
    path.join(SEBARO, "brand", "og", "pages.schema.json"), path.join(SEBARO, "tokens.css"),
    path.join(SEBARO, "fonts", "fonts.css"), ...list(path.join(SEBARO, "fonts", "web"), ".woff2").map((n) => path.join(SEBARO, "fonts", "web", n)),
    path.join(SEBARO, "icons", "sprite.svg"), path.join(SEBARO, "icons", "sprite.css"),
    path.join(SEBARO, "brand", "inline", "tile-studio.svg"), path.join(SEBARO, "brand", "inline", "lockup-horizontal.svg"),
    path.join(SEBARO, "brand", "inline", "lockup-horizontal-large.svg")];
  const missing = files.filter((f) => !existsSync(f));
  if (missing.length) { console.error(`error: missing ${missing.map(rel).join(", ")} (python3 tools/build.py; tools/sync_from_design.py)`); process.exit(2); }
  return { $comment: "written by tools/og.mjs after a successful render; tools/check_site.py compares it (OG); do not edit",
    render: readFileSync(RENDER, "utf8").match(/export const VERSION = "([^"]+)"/)?.[1] ?? "?",
    inputs: Object.fromEntries(files.map((f) => [rel(f), sha(f)])) };
}

function renderTo(dir) {
  const r = spawnSync(process.execPath, [RENDER, "--pages", PAGES, "--out", path.join(dir, "og"), "--head", path.join(dir, "head")],
    { cwd: ROOT, encoding: "utf8" });
  for (const line of `${r.stdout}${r.stderr}`.split("\n")) if (line.trim()) console.log(`  ${line.replace(dir, "<tmp>")}`);
  return r.status ?? 1;
}

const args = process.argv.slice(2);
const check = args.includes("--check"), pngBytes = args.includes("--png-bytes");
const unknown = args.filter((a) => !["--check", "--png-bytes"].includes(a));
if (unknown.length || (pngBytes && !check)) { console.error("usage: node tools/og.mjs [--check [--png-bytes]]"); process.exit(2); }
const stamp = JSON.stringify(inputs(), null, 2) + "\n";
const wanted = JSON.parse(readFileSync(PAGES, "utf8")).pages.map((p) => p.output ?? p.id);
const tmp = mkdtempSync(path.join(tmpdir(), "guide-og-"));
let code = 0;
try {
  const status = renderTo(tmp);
  if (status !== 0) {
    console.log(`og: render.mjs exit ${status}; ${check ? "check failed" : "docs/og/ and src/og/head/ left as they were"}`);
    code = status === 2 ? 2 : 1;
  } else if (!check) {
    rmSync(OUT, { recursive: true, force: true }); rmSync(HEAD, { recursive: true, force: true });
    mkdirSync(path.dirname(HEAD), { recursive: true });
    cpSync(path.join(tmp, "og"), OUT, { recursive: true }); cpSync(path.join(tmp, "head"), HEAD, { recursive: true });
    writeFileSync(path.join(HEAD, STAMP), stamp);
    console.log(`og: ${wanted.length} image(s) in ${rel(OUT)}/, snippets in ${rel(HEAD)}/; now run python3 tools/build.py`);
  } else {
    const problems = [], notes = [];
    const fresh = list(path.join(tmp, "head"), ""), committed = list(HEAD, "").filter((n) => n !== STAMP);
    const stampPath = path.join(HEAD, STAMP);
    if (!existsSync(stampPath) || readFileSync(stampPath, "utf8") !== stamp)
      notes.push(`src/og/head/${STAMP}: an input changed since the last render (check_site.py OG warns; render again: node tools/og.mjs, then tools/build.py)`);
    for (const n of new Set([...fresh, ...committed])) {
      const a = path.join(tmp, "head", n), b = path.join(HEAD, n);
      if (!existsSync(b)) problems.push(`src/og/head/${n} missing`);
      else if (!existsSync(a)) problems.push(`src/og/head/${n} is not written by a fresh render`);
      else if (!readFileSync(a).equals(readFileSync(b))) problems.push(`src/og/head/${n} differs from a fresh render`);
    }
    const pngs = list(OUT, ".png"), files = existsSync(OUT) ? readdirSync(OUT).sort() : [];
    for (const n of files) if (!wanted.includes(n.replace(/\.png$/, "")) || !n.endsWith(".png")) problems.push(`docs/og/${n} belongs to no page`);
    let same = 0;
    for (const id of wanted) {
      const b = path.join(OUT, `${id}.png`);
      if (!existsSync(b)) { problems.push(`docs/og/${id}.png missing`); continue; }
      if (readFileSync(path.join(tmp, "og", `${id}.png`)).equals(readFileSync(b))) same++;
      else (pngBytes ? problems : notes).push(`docs/og/${id}.png: other bytes than a fresh render on this machine`);
    }
    for (const n of notes) console.log(`note: ${n}`);
    for (const p of problems) console.log(`error: ${p}`);
    console.log(`og --check: ${wanted.length} page(s), fresh render ok, ${problems.length} problem(s) with snippets and files, ` +
                `PNG bytes equal ${same} / ${pngs.length}${pngBytes ? "" : " (reported, not checked)"} -> ${problems.length ? "FAIL" : "PASS"}`);
    code = problems.length ? 1 : 0;
  }
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
process.exitCode = code;
