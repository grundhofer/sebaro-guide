// sebaro-checks.ts: the screen checks every sebaro template runs in Chromium (Playwright).
// For each screen, in light and dark, at each width, at 100 % and at real 200 % text:
//   - the screen is the one asked for: the page's HTTP status, the text of its one visible h1, its view (a selector it
//     must hold) and exactly the overlays that must be open (dialogs, popovers, toasts; none when the case says null)
//   - the text size really took (200 %: the root is 32 px, set with CDP Page.setFontSizes BEFORE navigation, as a
//     reader sets it in the browser; full-page screenshots lose that setting, so the shots are viewport shots)
//   - the page does not scroll sideways (ZUG-09)
//   - no text is cut by a frame with overflow hidden or clip (ZUG-09; the same reading as the guide's
//     tools/check_a11y.mjs and the workshop's OVF4: a deliberate ellipsis with data-sb-truncate is exempt)
//   - no value of a select, no placeholder and no value of a read-only field is cut by its control at the current text
//     size, and no icon or suffix covers the text; a value typed into an editable one-line field may run on sideways
//     inside it (D110: „as in every text field“, the caret shows the place), it is counted in an annotation. Not seen:
//     date and time fields (the browser draws their parts) and the open list of a select (drawn by the system)
//   - axe-core: 0 violations of WCAG 2.0 / 2.1 / 2.2 A and AA (ZUG-01, ZUG-08)
//   - no console error, no page error and no Content-Security-Policy violation
// A viewport screenshot of each run lands in test-results/screens/ (uploaded by CI).
import path from "node:path";
import { test, expect, type ConsoleMessage, type Page } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

export type Screen = {
  /** short name, used in test titles and screenshot names */
  name: string;
  /** path relative to the server root, e.g. "/" or "/#/liste" */
  path: string;
  /** optional steps after loading, e.g. open a dialog; must leave the page in the state to check */
  prepare?: (page: Page) => Promise<void>;
  /** the text of the screen's one visible h1; null: the screen has none (said on purpose, e.g. a window with no
   *  document open) */
  heading: string | RegExp | null;
  /** a selector the screen must hold once, e.g. its view id `[data-sb-view="liste"]` */
  view?: string;
  /** the id of the one overlay that must be open (dialog, popover, toast), several for nested menus, null for none;
   *  a function where it depends on the screen's width and text size (e.g. a popover only on a narrow screen) */
  overlay: Overlay | ((width: number, scale: number) => Overlay);
  /** HTTP status of the page itself, 200 when not given */
  status?: number;
  /** control cuts of this screen that sebaro's own CSS causes (see ControlWaiver) */
  controlWaivers?: ControlWaiver[];
};

/** A control cut that sebaro's own CSS causes and the template cannot change (the export is never edited): the control,
 *  its text, the text size and, if only there, the width where it happens, and why. Reported as an annotation on every
 *  run, never silent; each one is a workshop request named in the pull request of this template. */
export type ControlWaiver = { at: string; text: string; scale: number; width?: number; reason: string };

type Overlay = string | string[] | null;

export type Options = {
  widths?: number[];
  schemes?: Array<"light" | "dark">;
  scales?: number[];
  /** control cuts on every screen that sebaro's own CSS causes (see ControlWaiver) */
  controlWaivers?: ControlWaiver[];
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

/** The ids of every open overlay: modal and non-modal dialogs, open popovers, toasts on screen. */
function openOverlays() {
  const ids = new Set<string>();
  const name = (e: Element) => e.id || `${e.localName}.${e.classList[0] ?? ""}`;
  document.querySelectorAll("dialog[open]").forEach((d) => ids.add(name(d)));
  document.querySelectorAll("[popover]").forEach((p) => { if (p.matches(":popover-open")) ids.add(name(p)); });
  document.querySelectorAll<HTMLElement>(".sb-toast").forEach((t) => { if (!t.hidden && t.checkVisibility()) ids.add(name(t)); });
  return [...ids].sort();
}

// The text of a control cut by the control itself: a select's chosen option, a placeholder, a read-only value, each
// measured in the control's own font against its text box (its width without padding), and any icon or suffix of the
// field that lies over that box. Editable values that run on sideways (D110) come back in `scrolls`, not as faults.
function collectControlCuts() {
  const cut: Array<{ at: string; kind: string; text: string; over: number }> = [];
  const scrolls: string[] = [];
  const ctx = document.createElement("canvas").getContext("2d")!;
  const TEXTLIKE = new Set(["text", "search", "email", "url", "tel", "number", "password"]);
  const where = (el: Element) => (el.id ? `#${el.id}` : `${el.localName}[name="${el.getAttribute("name") ?? ""}"]`);
  for (const el of document.querySelectorAll<HTMLInputElement | HTMLSelectElement>("input, select")) {
    const isSelect = el instanceof HTMLSelectElement;
    if (isSelect ? el.multiple || el.size > 1 : !TEXTLIKE.has(el.type)) continue;
    if (!el.checkVisibility({ visibilityProperty: true })) continue;
    const box = el.getBoundingClientRect();
    if (box.width <= 2 || box.height <= 2) continue;
    let text = "", kind = "";
    if (isSelect) [text, kind] = [el.selectedOptions[0]?.text ?? "", "select"];
    else if (el.value) [text, kind] = [el.type === "password" ? "•".repeat(el.value.length) : el.value, "value"];
    else [text, kind] = [el.placeholder, "placeholder"];
    if (!text.trim()) continue;
    const cs = getComputedStyle(el);
    ctx.font = `${cs.fontStyle} ${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`;
    ctx.letterSpacing = cs.letterSpacing === "normal" ? "0px" : cs.letterSpacing;
    const width = ctx.measureText(text).width;
    const start = box.left + el.clientLeft + parseFloat(cs.paddingLeft);
    const room = el.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
    const over = Math.round(width - room);
    // an icon or suffix in the field's frame that covers the part of the text box the text uses
    const used = [start, start + Math.min(width, room)];
    const frame = el.parentElement;
    const covered = frame ? [...frame.children].filter((k) => k !== el && k.checkVisibility()).some((k) => {
      const r = k.getBoundingClientRect();
      return r.width > 0 && r.left < used[1] - 1 && r.right > used[0] + 1 && r.top < box.bottom && r.bottom > box.top;
    }) : false;
    if (covered) cut.push({ at: where(el), kind: `${kind} covered by an icon or suffix`, text: text.slice(0, 40), over: 0 });
    if (over <= 1) continue;
    const busy = el.getAttribute("aria-busy") === "true" || !!el.closest("form[aria-busy='true']");
    if (kind === "value" && !(el as HTMLInputElement).readOnly && !el.disabled && !busy) {
      scrolls.push(`${where(el)} runs on ${over} px inside its field (D110)`);
      continue;
    }
    cut.push({ at: where(el), kind, text: text.slice(0, 40), over });
  }
  return { cut, scrolls };
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
            // a case that asks for an error status (a 404 page) gets Chromium's line for that one response, nothing else
            const ownStatusLine = (m: ConsoleMessage) => (screen.status ?? 200) !== 200 && m.text().startsWith("Failed to load resource")
              && new URL(m.location().url).pathname === new URL(screen.path, "http://x").pathname;
            page.on("console", (m) => { if (m.type() === "error" && !ownStatusLine(m)) problems.push(`console: ${m.text()}`); });
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
            const response = await page.goto(screen.path);
            expect(response?.status(), "HTTP status of the page").toBe(screen.status ?? 200);
            await page.waitForLoadState("networkidle");
            await page.evaluate(() => document.fonts.ready.then(() => true));
            if (screen.prepare) await screen.prepare(page);
            // an opened overlay fades in for 200 ms even under reduced motion (BEW-04); check it once it stands (endless
            // animations such as a spinner do not count)
            await page.waitForFunction(() => document.getAnimations().every((a) => a.playState !== "running" || a.effect?.getTiming().iterations === Infinity));
            // let sb-fit.js and layout settle after fonts and any prepared state
            await page.evaluate(() => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(() => r(true)))));

            // the screen asked for, and nothing else open
            if (screen.heading === null) await expect(page.locator("h1:visible"), "no visible h1").toHaveCount(0);
            else await expect(page.locator("h1:visible"), "the screen's one visible h1").toHaveText([screen.heading]);
            if (screen.view) await expect(page.locator(screen.view), `the view ${screen.view}`).toHaveCount(1);
            const expected = typeof screen.overlay === "function" ? screen.overlay(width, scale) : screen.overlay;
            const overlays = expected === null ? [] : [expected].flat().sort();
            expect(await page.evaluate(openOverlays), "open overlays").toEqual(overlays);

            const root = await page.evaluate(() => parseFloat(getComputedStyle(document.documentElement).fontSize));
            expect(root, "root text size").toBeGreaterThanOrEqual(16 * scale - 0.5);

            const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
            expect(overflow, "page scrolls sideways (px)").toBeLessThanOrEqual(1);

            const cut = await page.evaluate(collectCut);
            expect(cut, "text cut by a frame").toEqual([]);

            const controls = await page.evaluate(collectControlCuts);
            const waivers = [...(options.controlWaivers ?? []), ...(screen.controlWaivers ?? [])];
            const waived = (c: { at: string; text: string }) => waivers.find((w) => w.at === c.at && w.text === c.text && w.scale === scale && (w.width ?? width) === width);
            for (const c of controls.cut.filter(waived)) test.info().annotations.push({ type: "waiver", description: `${c.at} „${c.text}“ cut by ${c.over} px: ${waived(c)!.reason}` });
            expect(controls.cut.filter((c) => !waived(c)), "control text cut by its control").toEqual([]);
            for (const line of controls.scrolls) test.info().annotations.push({ type: "D110", description: line });

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
