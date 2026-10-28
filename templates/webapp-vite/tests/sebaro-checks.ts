// sebaro-checks.ts: the screen checks every sebaro template runs in Chromium (Playwright).
// For each screen, in light and dark, at each width, at 100 % and at real 200 % text:
//   - the text size really took (200 %: the root is 32 px, set with CDP Page.setFontSizes BEFORE navigation, as a
//     reader sets it in the browser; full-page screenshots lose that setting, so the shots are viewport shots)
//   - the page does not scroll sideways (ZUG-09)
//   - no text is cut by a frame with overflow hidden or clip (ZUG-09; the same reading as the guide's
//     tools/check_a11y.mjs and the workshop's OVF4: a deliberate ellipsis with data-sb-truncate is exempt)
//   - axe-core: 0 violations of WCAG 2.0 / 2.1 / 2.2 A and AA (ZUG-01, ZUG-08)
//   - no console error, no page error and no Content-Security-Policy violation
// A viewport screenshot of each run lands in test-results/screens/ (uploaded by CI).
import path from "node:path";
import { test, expect, type Page } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

export type Screen = {
  /** short name, used in test titles and screenshot names */
  name: string;
  /** path relative to the server root, e.g. "/" or "/#/liste" */
  path: string;
  /** optional steps after loading, e.g. open a dialog; must leave the page in the state to check */
  prepare?: (page: Page) => Promise<void>;
};

export type Options = {
  widths?: number[];
  schemes?: Array<"light" | "dark">;
  scales?: number[];
};

const AXE_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22a", "wcag22aa"];

// Text cut by a frame, ported from tools/check_a11y.mjs (collectCut) of the sebaro guide: each visible text node is
// followed up its ancestors; an ancestor with overflow hidden or clip must hold the text's line boxes in that axis
// (1 px tolerance), each axis on its own; in a scrolling axis only the part the scroll box shows counts further up.
// Not counted: the visually hidden pattern (a cutting box of at most 2 px) and, in the inline axis, a deliberate
// ellipsis (text-overflow: ellipsis with data-sb-truncate on it or above).
function collectCut() {
  const out: Array<{ text: string; at: string; frame: string; over: number }> = [];
  const seen = new Set<string>();
  const path = (el: Element) => {
    const parts: string[] = [];
    for (let e: Element | null = el; e && e !== document.body && parts.length < 4; e = e.parentElement) {
      parts.unshift(e.id ? `${e.localName}#${e.id}` : e.localName + (e.classList[0] ? "." + e.classList[0] : ""));
      if (e.id) break;
    }
    return parts.join(" > ");
  };
  const range = document.createRange();
  const tw = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n: Node | null; (n = tw.nextNode()); ) {
    const textNode = n as Text;
    if (!textNode.data.trim()) continue;
    const el = textNode.parentElement;
    if (!el || el.closest("script, style, template, noscript, select") || !el.checkVisibility({ visibilityProperty: true })) continue;
    range.selectNodeContents(textNode);
    const rects = [...range.getClientRects()].filter((r) => r.width > 0.5 && r.height > 0.5);
    if (!rects.length) continue;
    let xs = rects.map((rc) => [rc.left, rc.right]);
    let ys = rects.map((rc) => [rc.top, rc.bottom]);
    for (let a: Element | null = el; a && a !== document.documentElement; a = a.parentElement) {
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
        const text = textNode.data.replace(/\s+/g, " ").trim().slice(0, 40);
        const key = path(el) + "|" + text;
        if (!seen.has(key)) { seen.add(key); out.push({ text, at: path(el), frame: path(a), over: Math.round(over) }); }
        break;
      }
      if (sx || hx) xs = xs.map(([x0, x1]) => [Math.max(x0, l), Math.min(x1, r)]);
      if (sy || hy) ys = ys.map(([y0, y1]) => [Math.max(y0, t), Math.min(y1, btm)]);
    }
  }
  return out;
}

/** Registers one test per screen, scheme, width and text size. */
export function checkScreens(screens: Screen[], options: Options = {}) {
  const widths = options.widths ?? [320, 390, 1440];
  const schemes = options.schemes ?? ["light", "dark"];
  const scales = options.scales ?? [1, 2];
  for (const screen of screens) {
    for (const scheme of schemes) {
      for (const width of widths) {
        for (const scale of scales) {
          const label = `${screen.name} ${scheme} ${width}px ${scale * 100}%`;
          test(label, async ({ browser }) => {
            const context = await browser.newContext({
              viewport: { width, height: width < 640 ? 844 : 900 },
              colorScheme: scheme,
              reducedMotion: "reduce",
            });
            const page = await context.newPage();
            const problems: string[] = [];
            page.on("console", (m) => { if (m.type() === "error") problems.push(`console: ${m.text()}`); });
            page.on("pageerror", (e) => problems.push(`page error: ${e.message}`));
            await page.addInitScript(() => {
              document.addEventListener("securitypolicyviolation", (e) => {
                console.error(`CSP violation: ${e.violatedDirective} ${e.blockedURI || "inline"}`);
              });
            });
            if (scale !== 1) {
              const cdp = await context.newCDPSession(page);
              await cdp.send("Page.setFontSizes", { fontSizes: { standard: Math.round(16 * scale), fixed: Math.round(13 * scale) } });
            }
            await page.goto(screen.path);
            await page.waitForLoadState("networkidle");
            await page.evaluate(() => document.fonts.ready.then(() => true));
            if (screen.prepare) await screen.prepare(page);
            // an opened overlay fades in for 200 ms even under reduced motion (BEW-04); check it once it stands (endless
            // animations such as a spinner do not count)
            await page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running" || a.effect?.getTiming().iterations === Infinity));
            // let sb-fit.js and layout settle after fonts and any prepared state
            await page.evaluate(() => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(() => r(true)))));

            const root = await page.evaluate(() => parseFloat(getComputedStyle(document.documentElement).fontSize));
            expect(root, "root text size").toBeGreaterThanOrEqual(16 * scale - 0.5);

            const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
            expect(overflow, "page scrolls sideways (px)").toBeLessThanOrEqual(1);

            const cut = await page.evaluate(collectCut);
            expect(cut, "text cut by a frame").toEqual([]);

            const axe = await new AxeBuilder({ page }).withTags(AXE_TAGS).analyze();
            const violations = axe.violations.map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(" ")).join(", ")}`);
            expect(violations, "axe violations").toEqual([]);

            await page.screenshot({ path: path.join(test.info().project.outputDir, "screens", `${screen.name}-${scheme}-${width}-${scale * 100}.png`) });
            expect(problems, "console, page errors and CSP violations").toEqual([]);
            await context.close();
          });
        }
      }
    }
  }
}
