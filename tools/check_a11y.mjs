// check_a11y.mjs: axe-core (WCAG 2.0/2.1/2.2 A + AA) on every guide page in headless Chromium, light and dark,
// at 390 and 1440 px, plus horizontal overflow and console errors. Exit 1 on any violation that is not waived.
// Then each page once more at 200 % text on 1024 and 1280 px, light and dark (LARGE): the page must not scroll
// sideways and no frame with overflow hidden or clip may cut a text (D100 (5), ZUG-09). The browser's default font
// size is doubled by CDP Page.setFontSizes before the page loads, as a reader sets it, so rem and em grow and px
// stays: the widths where the guide's layout once switched by px while the text was twice as large. The phone widths
// at 200 % stay with the workshop's check_demo.py (OVF3, OVF4, OVF6 at 320, 360, 390 px). COUNT: an area's count in
// the contents of regeln.html stands on the line of its word, in every run.
//
//   node tools/check_a11y.mjs                 # all docs/*.html
//   node tools/check_a11y.mjs docs/app.html   # some pages
//
// Inside a .g-ex--dont specimen (not its label or note) axe color-contrast is skipped; every other rule runs there.
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
// deliberate "Nicht so" specimens: only axe color-contrast skips them (their label and note stay checked); names,
// roles, keyboard and every other rule still run there (guide.css, section "deliberate Nicht so specimens")
const DONT = ".g-ex--dont > :not(.g-ex__label):not(.g-ex__note)";
const RUNS = [
  { width: 1440, height: 900, scheme: "light" }, { width: 1440, height: 900, scheme: "dark" },
  { width: 390, height: 844, scheme: "light" }, { width: 390, height: 844, scheme: "dark" },
];

// the 200 % pass (LARGE): widths in px, the scale of the default font size (standard 16, fixed 13)
const LARGE = { widths: [1024, 1280], schemes: ["light", "dark"], scale: 2 };

// text cut by a frame, as the workshop's OVF4 reads it: each visible text node is followed up its ancestors; an
// ancestor with overflow hidden or clip must hold the text's line boxes in that axis (1 px of tolerance). Each axis
// on its own: a box that scrolls in one axis can still cut in the other, and in its scrolling axis its content is
// reached by scrolling, so from there up that axis measures the text as far as it lies in the scroll box, which an
// outer frame may cut too;
// not counted: the visually hidden pattern (a cutting box of at most 2 px) and, in the inline axis, a deliberate
// ellipsis (text-overflow: ellipsis with data-sb-truncate on it or above)
function collectCut() {
  const out = [];
  const seen = new Set();
  const path = (el) => {
    const parts = [];
    for (let e = el; e && e !== document.body && parts.length < 4; e = e.parentElement) {
      parts.unshift(e.id ? `${e.localName}#${e.id}` : e.localName + (e.classList[0] ? "." + e.classList[0] : ""));
      if (e.id) break;
    }
    return parts.join(" > ");
  };
  const range = document.createRange();
  const tw = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n; (n = tw.nextNode());) {
    if (!n.data.trim()) continue;
    const el = n.parentElement;
    if (!el || el.closest("script, style, template, noscript, select") || !el.checkVisibility({ visibilityProperty: true })) continue;
    range.selectNodeContents(n);
    const rects = [...range.getClientRects()].filter((r) => r.width > 0.5 && r.height > 0.5);
    if (!rects.length) continue;
    let xs = rects.map((rc) => [rc.left, rc.right]), ys = rects.map((rc) => [rc.top, rc.bottom]);
    for (let a = el; a && a !== document.documentElement; a = a.parentElement) {
      const cs = getComputedStyle(a);
      const sx = /auto|scroll/.test(cs.overflowX), sy = /auto|scroll/.test(cs.overflowY);
      const hx = /hidden|clip/.test(cs.overflowX), hy = /hidden|clip/.test(cs.overflowY);
      if (!hx && !hy && !sx && !sy) continue;
      const b = a.getBoundingClientRect();
      if ((hx || hy) && (b.width <= 2 || b.height <= 2)) break;
      const l = b.left + a.clientLeft, t = b.top + a.clientTop, r = l + a.clientWidth, btm = t + a.clientHeight;
      let over = 0;
      if (hx && !(cs.textOverflow === "ellipsis" && a.closest("[data-sb-truncate]"))) for (const [x0, x1] of xs) over = Math.max(over, x1 - r, l - x0);
      if (hy) for (const [y0, y1] of ys) over = Math.max(over, y1 - btm, t - y0);
      if (over > 1) {
        const text = n.data.replace(/\s+/g, " ").trim().slice(0, 40);
        const key = path(el) + "|" + text;
        if (!seen.has(key)) { seen.add(key); out.push({ text, at: path(el), frame: path(a), over: Math.round(over), case: el.closest("section[data-case]")?.id }); }
        break;
      }
      // from here up only the part this box shows counts: what it scrolls to, what its exempt ellipsis hides
      if (sx || hx) xs = xs.map(([x0, x1]) => [Math.max(x0, l), Math.min(x1, r)]);
      if (sy || hy) ys = ys.map(([y0, y1]) => [Math.max(y0, t), Math.min(y1, btm)]);
    }
  }
  return out;
}

// controls for collectCut, run before the pages at the same 200 % root: each "cut" case must be reported, each
// "fine" case must not, so the check can never go blind or noisy unnoticed (a FAIL here is a fault of this tool)
const CUT_CONTROLS = `<style>body { margin: 0; font: 16px/1.5 sans-serif; } section { margin: 0 0 8px; } p { margin: 0; }</style>
<section data-case="cut" id="y-in-x-scroller"><div style="width:120px; height:28px; line-height:40px; overflow-x:auto; overflow-y:hidden"><p>Ein Satz, der in drei Zeilen umbricht und unten abgeschnitten wird</p></div></section>
<section data-case="cut" id="outer-cuts-scroller"><div style="width:200px; overflow:hidden"><div style="width:400px; overflow-x:auto"><p style="white-space:nowrap">Dieser Satz steht weit rechts außerhalb des Rahmens</p></div></div></section>
<section data-case="cut" id="plain-hidden"><div style="width:120px; overflow:hidden"><p style="white-space:nowrap">Ein langer Satz ohne Umbruch im Rahmen</p></div></section>
<section data-case="fine" id="reach-by-scroll"><div style="width:120px; overflow-x:auto"><p style="white-space:nowrap">Ein langer Satz, den man seitlich scrollt</p></div></section>
<section data-case="fine" id="short-in-wide-scroller"><div style="width:200px; overflow:hidden"><div style="width:400px; overflow-x:auto"><p>Kurz</p></div></div></section>
<section data-case="fine" id="ellipsis-in-row"><div style="width:200px; overflow:hidden"><div data-sb-truncate style="width:120px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap">Ein bewusst gekürzter Name in einer Zeile</div></div></section>
<section data-case="fine" id="fits"><div style="width:600px; overflow:hidden"><p>Kurz</p></div></section>
<section data-case="fine" id="visually-hidden"><span style="position:absolute; width:1px; height:1px; overflow:hidden; clip-path:inset(50%); white-space:nowrap">Nur für Screenreader gedacht</span></section>
<section data-case="fine" id="ellipsis"><div data-sb-truncate style="width:120px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap">Ein bewusst gekürzter Name einer Zeile</div></section>`;
async function checkCutControls(browser) {
  const ctx = await browser.newContext({ viewport: { width: 1024, height: 900 } });
  const tab = await ctx.newPage();
  const cdp = await ctx.newCDPSession(tab);
  await cdp.send("Page.setFontSizes", { fontSizes: { standard: Math.round(16 * LARGE.scale), fixed: Math.round(13 * LARGE.scale) } });
  await tab.setContent(CUT_CONTROLS);
  const found = new Set((await tab.evaluate(collectCut)).map((c) => c.case));
  const cases = await tab.evaluate(() => [...document.querySelectorAll("section[data-case]")].map((s) => [s.id, s.dataset.case]));
  await ctx.close();
  let bad = 0;
  for (const [id, kind] of cases) {
    if (kind === "cut" && !found.has(id)) { console.log(`error: LARGE control ${id}: cut text not reported`); bad++; }
    if (kind === "fine" && found.has(id)) { console.log(`error: LARGE control ${id}: reported, but nothing is cut`); bad++; }
  }
  return bad;
}

// COUNT: an area's count in the contents (regeln.html) stands on the line of its word, not on a line of its own
const countsAlone = () => [...document.querySelectorAll(".demo-toc li > a + .g-toc__count")].filter((c) => {
  const a = c.previousElementSibling.getBoundingClientRect(), b = c.getBoundingClientRect();
  return b.width > 0 && (b.top >= a.bottom - 1 || b.bottom <= a.top + 1);
}).map((c) => c.previousElementSibling.textContent.trim());

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
failed += await checkCutControls(browser);
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
    const result = await tab.evaluate(async ({ tags, dont }) => {
      const map = (r) => r.violations.map((v) => ({ id: v.id, help: v.help, nodes: v.nodes.map((n) => n.target.join(" ")) }));
      // every rule except color-contrast on the whole page, then color-contrast without the deliberate specimens
      // eslint-disable-next-line no-undef
      const all = await axe.run(document, { runOnly: { type: "tag", values: tags }, rules: { "color-contrast": { enabled: false } }, resultTypes: ["violations"] });
      const ctx = document.querySelector(dont) ? { include: [document], exclude: [[dont]] } : document;
      // eslint-disable-next-line no-undef
      const contrast = await axe.run(ctx, { runOnly: { type: "rule", values: ["color-contrast"] }, resultTypes: ["violations"] });
      return map(all).concat(map(contrast));
    }, { tags: TAGS, dont: DONT });
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
    for (const w of await tab.evaluate(countsAlone)) { console.log(`error: COUNT ${label}: the count of „${w}“ stands on a line of its own`); failed++; }
    for (const e of errors) { console.log(`error: CONSOLE ${label}: ${e}`); failed++; }
    await ctx.close();
  }
  for (const width of LARGE.widths) {
    for (const scheme of LARGE.schemes) {
      const ctx = await browser.newContext({ viewport: { width, height: 900 }, colorScheme: scheme });
      const tab = await ctx.newPage();
      const cdp = await ctx.newCDPSession(tab);
      await cdp.send("Page.setFontSizes", { fontSizes: { standard: Math.round(16 * LARGE.scale), fixed: Math.round(13 * LARGE.scale) } });
      await tab.goto(BASE + page, { waitUntil: "load" });
      await tab.evaluate(async () => { if (document.fonts) await document.fonts.ready; });
      await tab.waitForTimeout(300);
      const label = `${page} ${width}/${scheme}/${LARGE.scale * 100}%`;
      const root = await tab.evaluate(() => parseFloat(getComputedStyle(document.documentElement).fontSize));
      if (root < 16 * LARGE.scale - 0.5) { console.log(`error: LARGE ${label}: the text size did not take (root ${root} px)`); failed++; }
      const overflow = await tab.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
      if (overflow > 1) { console.log(`error: LARGE ${label}: page scrolls sideways by ${overflow} px`); failed++; }
      for (const w of await tab.evaluate(countsAlone)) { console.log(`error: COUNT ${label}: the count of „${w}“ stands on a line of its own`); failed++; }
      for (const c of await tab.evaluate(collectCut)) {
        console.log(`error: LARGE ${label}: "${c.text}" (${c.at}) runs ${c.over} px past ${c.frame}, which cuts it`);
        failed++;
      }
      await ctx.close();
    }
  }
  console.log(`checked ${page}`);
}
await browser.close();
server.close();
for (const w of waivers) if (!used.has(w)) console.log(`warning: unused waiver ${w.page} ${w.rule} ${w.target}`);
console.log(`check_a11y: ${pages.length} pages x (${RUNS.length} runs + ${LARGE.widths.length * LARGE.schemes.length} at ${LARGE.scale * 100} % text), ${failed} errors -> ${failed ? "FAIL" : "PASS"}`);
process.exit(failed ? 1 : 0);
