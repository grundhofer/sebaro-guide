// sb-fit.js: large text on the web (D99 (1), D100 (1), (3), (5), D101 (1), (2), (8), (9), (11); spec/02 §7, spec/09 §1).
// Classic script (pages open from file://), CSP-safe: no inline handlers, no eval, styles only through classes, data
// attributes and the CSSOM. It writes no words of its own (D87): the select takes the words of the segments, the step
// line the word of the current step. Without it the words still wrap and no demo page scrolls sideways at 200 % text
// (sebaro.css: segment faces wrap, a series chart narrower than 20em takes the values form by itself, an overlong word
// breaks without a hyphen),
// but the parts keep their wide forms (no select, no short steps, no facts list, no legend for two series).
// What it does, each measured again whenever its part changes size (ResizeObserver; a larger text makes it taller),
// on a theme or tone change, once the fonts are loaded and on window.sbFit.refresh(). A change of the window's width,
// the text size, the theme or the tone decides every form afresh, as a fresh load would; the hysteresis below only
// holds while a part changes size at the same text size (a scroll bar coming and going, a neighbour growing):
//   1. Segmented control (spec/02 §2.7, D100 (3)): once one option does not fit its column the way Compose measures it
//      (its widest word at the title weight wider than the column less the 4 px sides, the 16 px check and its gap,
//      counted for every option, or the words on more than two lines), the fieldset gets data-sb-fit="select" and
//      shows a select with the same options, the legend as its label, the disabled options disabled. The radios stay
//      the form's value (hidden, still sent): a choice in the select checks its radio and fires input and change on
//      it; a radio changed with a change event, a form reset or sb-tone-change are read back, and the select reads
//      the radios again on every pass and when it gets focus, a press or a key. A script that sets checked without an event
//      calls sbFit.refresh(fieldset) to show it at once. Focus moves with the swap. While the select shows, the
//      fieldset is role="none", so the legend names only the select and is not read twice (provisional, agent).
//      Back to the segments only when the words fit 4 px narrower (hysteresis, provisional (agent)).
//      The column is measured at the width the control takes when it fills its place (a control as wide as its words
//      grows with its choice). Without the script the words wrap and an overlong word breaks.
//   2. Steps (spec/02 §3.12, D100 (1), D101 (1), (2)): once a step's word does not fit its column on two lines even
//      with hyphens (at the title weight for every step, so the form does not change with the current step), the list
//      gets data-sb-fit="short": every bar stays, done steps keep their check, the words are visually hidden (screen
//      readers still read each step with its state) and the current step's word stands once, aria-hidden, in
//      p.sb-progress__now on its own line under the bars, start-aligned. 2 to 4 steps, as Compose. Words are
//      span.sb-progress__word (the script wraps a bare word in one).
//   3. Facts line (spec/10 §4.1, D101 (11)): once one cell with its „·“ does not fit one line, data-sb-fit="list": the
//      name on its own line, under it each cell on its own line, no „·“, the same type and colours; links stay links.
//   4. Several series (spec/02 §3.7, D101 (7), (8)): while every line end „Name 90 %“ stays on one line in half the
//      plot's width and still covers the height where its line ends after ends that would touch are moved apart, the
//      names stand at the line ends; else data-sb-fit="values": the legend names the series (a two-series chart writes
//      its legend with hidden and data-sb-fit-legend; the script shows it), every end keeps only its last value. Ends
//      that would touch are moved apart in both forms (--sb-chart-shift). Slot labels under any chart that would run
//      into each other are left out from the front, so the latest stay (as Compose, D99 (2)).
//   5. Hyphens only for a word that alone does not fit its line (D101 (9), spec/07 §3): every word is first allowed to
//      break only without a hyphen (overflow-wrap: break-word, sebaro.css); a word the browser had to break inside
//      is wrapped, and only that word, in span.sb-hyphenate[data-sb-fit-word] (hyphens: auto, by the page's lang),
//      like Compose's SbWrapText; every other word of the paragraph, heading or button keeps hyphens: manual. The span
//      adds no character; it is taken away again before each measure. Never in code, pre, kbd, samp, .sb-id (D80),
//      .sb-file-name (D101 (6)), a name marked translate="no" (a product name breaks at the line end without a hyphen,
//      D101 (10); provisional, agent), [data-sb-truncate] or a word with soft hyphens (the author's own break points,
//      SCH-06).
(function () {
  "use strict";
  var HYST = 4;   // px: a part goes back to its wide form only when it fits this much narrower (provisional, agent)
  var NO_HYPHENS = "code, pre, kbd, samp, var, textarea, input, select, option, script, style, svg, math, .sb-id, " +
    ".sb-file-name, .sb-visually-hidden, [data-sb-truncate], [translate=\"no\"], .sb-fit-probe";
  var SVGNS = "http://www.w3.org/2000/svg";
  var counter = 0;
  var fresh = true;   // this pass decides afresh (a new width, text size, theme or tone): no hysteresis
  function hyst(now) { return now && !fresh ? HYST : 0; }

  function px(v) { var n = parseFloat(v); return isFinite(n) ? n : 0; }
  function titleWeight() {
    return getComputedStyle(document.documentElement).getPropertyValue("--sb-type-title-weight").trim() || "700";
  }

  // The text laid out in `width` px inside `host` (so it inherits lang): its lines and whether a word ran past the side.
  function measure(host, text, width, from, weight, hyphens) {
    var cs = getComputedStyle(from), p = document.createElement("span");
    p.className = "sb-fit-probe";
    p.style.inlineSize = Math.max(1, width) + "px";
    p.style.fontFamily = cs.fontFamily;
    p.style.fontSize = cs.fontSize;
    p.style.lineHeight = cs.lineHeight;
    p.style.fontStyle = cs.fontStyle;
    p.style.fontWeight = weight || cs.fontWeight;
    p.style.letterSpacing = cs.letterSpacing;
    p.style.fontVariantNumeric = cs.fontVariantNumeric;
    p.style.hyphens = hyphens;
    p.style.webkitHyphens = hyphens;
    p.textContent = text;
    host.appendChild(p);
    var lh = px(getComputedStyle(p).lineHeight) || px(cs.fontSize) * 1.4;
    var r = { lines: Math.round(p.getBoundingClientRect().height / lh), over: p.scrollWidth > p.clientWidth + 0.5 };
    host.removeChild(p);
    return r;
  }
  function words(el) { return (el.textContent || "").replace(/[\s]+/g, function (s) { return s.indexOf(" ") >= 0 ? " " : " "; }).trim(); }

  // ------------------------------------------------------------------ 1 segmented control
  function segParts(fs) {
    var opts = fs.querySelector(".sb-segmented__options");
    if (!opts) return null;
    var radios = Array.prototype.slice.call(opts.querySelectorAll('input[type="radio"]'));
    return radios.length ? { opts: opts, radios: radios } : null;
  }
  function segNeedsSelect(fs, parts, narrower) {
    // the width the control gets when it fills its place: a control drawn as wide as its words (in a cell that does
    // not stretch it) grows with its choice and never needs the select while its place has room
    var was = fs.style.inlineSize;
    fs.style.inlineSize = "100%";
    var n = parts.radios.length, w = fs.clientWidth;
    fs.style.inlineSize = was;
    var faces = parts.radios.map(function (r) { return r.parentElement.querySelector(".sb-segmented__face"); });
    if (!w || !faces[0]) return null;
    var csO = getComputedStyle(parts.opts), csF = getComputedStyle(faces[0]);
    var sep = n > 1 ? px(getComputedStyle(parts.radios[1].closest(".sb-segmented__option")).borderInlineStartWidth) : 0;
    var col = (w - px(csO.borderInlineStartWidth) - px(csO.borderInlineEndWidth) - sep * (n - 1)) / n;
    var icon = faces[0].querySelector(".sb-icon");
    var room = col - px(csF.paddingInlineStart) - px(csF.paddingInlineEnd)
      - (icon ? px(getComputedStyle(icon).width) + px(csF.columnGap) : 0) - hyst(narrower);
    var weight = titleWeight();
    return faces.some(function (face) {
      if (!face) return false;
      var r = measure(fs, words(face), room, face, weight, "manual");
      return r.over || r.lines > 2;
    });
  }
  function segSelect(fs, parts) {
    var wrap = fs.querySelector(":scope > .sb-segmented__select");
    if (!wrap) {
      var legend = fs.querySelector(":scope > legend");
      if (legend && !legend.id) legend.id = "sb-fit-legend-" + (++counter);
      wrap = document.createElement("div");
      wrap.className = "sb-field__control sb-select sb-segmented__select";
      var sel = document.createElement("select");
      if (legend) sel.setAttribute("aria-labelledby", legend.id);
      // a radio may have been set by a script without an event: read the radios before the list opens
      sel.addEventListener("focus", function () { segSync(fs); });
      sel.addEventListener("pointerdown", function () { segSync(fs); });
      sel.addEventListener("keydown", function () { segSync(fs); }, true);
      sel.addEventListener("change", function () {
        var radio = segParts(fs).radios[+sel.value];
        if (!radio || radio.checked) return;
        radio.checked = true;
        radio.dispatchEvent(new Event("input", { bubbles: true }));
        radio.dispatchEvent(new Event("change", { bubbles: true }));
      });
      var icon = document.createElementNS(SVGNS, "svg");
      icon.setAttribute("class", "sb-icon");
      icon.setAttribute("aria-hidden", "true");
      icon.setAttribute("focusable", "false");
      var use = document.createElementNS(SVGNS, "use");
      use.setAttribute("href", "#chevron-down");
      icon.appendChild(use);
      wrap.appendChild(sel);
      wrap.appendChild(icon);
      parts.opts.insertAdjacentElement("afterend", wrap);
    }
    return wrap.querySelector("select");
  }
  function segSync(fs) {
    var parts = segParts(fs), sel = fs.querySelector(":scope > .sb-segmented__select > select");
    if (!parts || !sel) return;
    var chosen = -1;
    parts.radios.forEach(function (r, i) {
      var o = sel.options[i];
      if (!o) { o = document.createElement("option"); sel.appendChild(o); }
      o.value = String(i);
      o.textContent = words(r.parentElement.querySelector(".sb-segmented__face") || r.parentElement);
      o.disabled = r.disabled;
      if (r.checked) chosen = i;
    });
    while (sel.options.length > parts.radios.length) sel.remove(sel.options.length - 1);
    sel.selectedIndex = chosen;
  }
  function fitSegmented(fs) {
    var parts = segParts(fs);
    if (!parts) return;
    var now = fs.getAttribute("data-sb-fit") === "select";
    var need = segNeedsSelect(fs, parts, now);
    if (need === null || need === now) { if (now) segSync(fs); return; }
    if (need) {
      var focused = parts.opts.contains(document.activeElement);
      var sel = segSelect(fs, parts);
      segSync(fs);
      fs.setAttribute("data-sb-fit", "select");
      // the legend names the select; without a group around it the name is read once (provisional, agent)
      if (!fs.hasAttribute("data-sb-fit-role")) fs.setAttribute("data-sb-fit-role", fs.getAttribute("role") || "");
      fs.setAttribute("role", "none");
      if (focused) sel.focus();
    } else {
      var had = document.activeElement && document.activeElement === fs.querySelector(":scope > .sb-segmented__select > select");
      fs.removeAttribute("data-sb-fit");
      var role = fs.getAttribute("data-sb-fit-role");
      if (role) fs.setAttribute("role", role); else fs.removeAttribute("role");
      fs.removeAttribute("data-sb-fit-role");
      if (had) {
        var back = parts.radios.filter(function (r) { return r.checked; })[0] ||
          parts.radios.filter(function (r) { return !r.disabled; })[0];
        if (back) back.focus();
      }
    }
  }

  // ------------------------------------------------------------------ 2 steps
  function stepWord(li) {
    var w = li.querySelector(":scope > .sb-progress__word");
    if (w) return w;
    var texts = Array.prototype.filter.call(li.childNodes, function (n) { return n.nodeType === 3 && n.data.trim(); });
    if (!texts.length) return null;
    w = document.createElement("span");
    w.className = "sb-progress__word";
    li.insertBefore(w, texts[0]);
    texts.forEach(function (t) { w.appendChild(t); });
    return w;
  }
  function fitSteps(ol) {
    var steps = Array.prototype.filter.call(ol.children, function (li) { return li.classList.contains("sb-progress__step"); });
    if (steps.length < 2 || steps.length > 4 || !ol.clientWidth) return;
    var spans = steps.map(stepWord);
    var now = ol.getAttribute("data-sb-fit") === "short";
    var col = steps[0].clientWidth - px(getComputedStyle(steps[0]).paddingInlineStart) - px(getComputedStyle(steps[0]).paddingInlineEnd)
      - hyst(now);
    var weight = titleWeight();
    var need = spans.some(function (s, i) {
      if (!s) return false;
      var r = measure(steps[i], words(s), col, steps[i], weight, "auto");
      return r.over || r.lines > 2;
    });
    var line = ol.nextElementSibling && ol.nextElementSibling.classList.contains("sb-progress__now") ? ol.nextElementSibling : null;
    if (need) {
      var cur = steps.filter(function (li) { return li.getAttribute("aria-current") === "step"; })[0];
      var shown = cur || steps.filter(function (li) { return li.matches('[data-sb-state="done"], [data-state="done"]'); }).pop();
      if (!line) {
        line = document.createElement("p");
        line.className = "sb-progress__now";
        line.setAttribute("aria-hidden", "true");
        ol.insertAdjacentElement("afterend", line);
      }
      var text = shown && shown.querySelector(".sb-progress__word") ? words(shown.querySelector(".sb-progress__word")) : "";
      if (line.textContent !== text) line.textContent = text;
      if (cur) line.removeAttribute("data-sb-state"); else line.setAttribute("data-sb-state", "done");
      if (!now) ol.setAttribute("data-sb-fit", "short");
    } else if (now) {
      ol.removeAttribute("data-sb-fit");
    }
  }

  // ------------------------------------------------------------------ 3 facts line
  function fitFacts(p) {
    var cells = p.querySelectorAll(":scope > .sb-facts-line__cell");
    if (!cells.length || !p.clientWidth) return;
    var now = p.getAttribute("data-sb-fit") === "list";
    p.setAttribute("data-sb-fit", "measure");   // cells on one line each, with their „·“ (CSS)
    var w = p.clientWidth - hyst(now);
    var need = Array.prototype.some.call(cells, function (c) { return c.getBoundingClientRect().width > w + 0.5; });
    if (need) p.setAttribute("data-sb-fit", "list"); else p.removeAttribute("data-sb-fit");
  }

  // ------------------------------------------------------------------ 4 several series
  function fitSeries(fig) {
    var plot = fig.querySelector(".sb-chart__plot"), area = plot && plot.querySelector(".sb-chart__area");
    var ends = plot && Array.prototype.slice.call(plot.querySelectorAll(".sb-chart__ends > .sb-chart__end--series"));
    if (!area || !ends || ends.length < 2 || !plot.clientWidth) return;
    var legend = fig.querySelector(":scope > .sb-chart__legend");
    var now = fig.getAttribute("data-sb-fit") === "values";
    // measure the ends with their names, each on one line (sebaro.css: data-sb-fit="measure")
    fig.setAttribute("data-sb-fit", "measure");
    var half = plot.clientWidth / 2 - hyst(now), h = area.clientHeight;
    var one = ends.every(function (li) { return li.getBoundingClientRect().width <= half + 0.5 && li.getClientRects().length === 1; });
    // move ends that would touch apart: top to bottom at least one label height, then back inside the area
    function place(apply) {
      var spots = ends.map(function (li) {
        return { li: li, y: (1 - px(li.getAttribute("data-sb-y")) / 100) * h, size: li.getBoundingClientRect().height };
      }).sort(function (a, b) { return a.y - b.y; });
      var at = [];
      spots.forEach(function (s, i) { at[i] = i ? Math.max(s.y, at[i - 1] + (spots[i - 1].size + s.size) / 2) : s.y; });
      for (var i = at.length - 1; i >= 0; i--) {   // no lower than the base line, then up from there
        at[i] = Math.min(at[i], i === at.length - 1 ? h : at[i + 1] - (spots[i].size + spots[i + 1].size) / 2);
      }
      if (apply) spots.forEach(function (s, i) {
        var d = Math.round((at[i] - s.y) * 10) / 10;
        if (d) s.li.style.setProperty("--sb-chart-shift", d + "px"); else s.li.style.removeProperty("--sb-chart-shift");
      });
      return spots.every(function (s, i) { return Math.abs(at[i] - s.y) <= s.size / 2; });
    }
    var values = !(one && place(false));
    if (values) fig.setAttribute("data-sb-fit", "values"); else fig.removeAttribute("data-sb-fit");
    place(true);   // the shifts for the form now shown, with its own label heights
    if (legend && legend.hasAttribute("data-sb-fit-legend")) legend.hidden = !values;
  }

  // ------------------------------------------------------------------ 4b slot labels that would touch
  // As Compose (D99 (2), spec/08 §14.10): x labels under a chart that would run into each other are left out instead of
  // overlapping, read from the back, so the latest stay („Mo Mi Fr So“). The slots are aria-hidden (the values table and
  // the bars carry the words), so only the picture changes. data-sb-fit="hidden" on the label.
  function fitSlots(ol) {
    var items = Array.prototype.filter.call(ol.children, function (li) { return li.textContent.trim(); });
    if (items.length < 2 || !ol.clientWidth) return;
    items.forEach(function (li) { li.removeAttribute("data-sb-fit"); });
    var rtl = getComputedStyle(ol).direction === "rtl", keep = null;
    function box(li) {   // the text's own box, not the slot's
      var r = document.createRange(); r.selectNodeContents(li);
      var b = r.getBoundingClientRect();
      return b.width ? b : li.getBoundingClientRect();
    }
    for (var i = items.length - 1; i >= 0; i--) {
      var b = box(items[i]);
      if (keep && (rtl ? b.left < keep.right + 4 : b.right > keep.left - 4)) { items[i].setAttribute("data-sb-fit", "hidden"); continue; }
      keep = b;
    }
  }

  // ------------------------------------------------------------------ 5 hyphens only for an overlong word
  var BREAK_AFTER = /[^ \t\n\r\f​\-‐–—\/]+[\-‐–—\/]?/g;
  function blockWidth(el, cache) {
    if (cache.has(el)) return cache.get(el);
    var b = el;
    // only a plain inline box (or display: contents) takes its line from a parent; inline-flex, inline-grid and
    // inline-block lay out their own lines (a button's words)
    while (b && b !== document.body && /^(inline|contents)$/.test(getComputedStyle(b).display)) b = b.parentElement;
    var w = b ? b.clientWidth : 0;
    cache.set(el, w);
    return w;
  }
  // take the spans of the last pass away again, so every word is measured without hyphens: first the word spans,
  // then the carrier span a text run of a flex or grid container got (so the run stays one item, not three)
  function unwrapOne(span) {
    var parent = span.parentNode;
    if (!parent) return;
    var t = document.createTextNode(span.textContent), prev = span.previousSibling, next = span.nextSibling;
    parent.replaceChild(t, span);
    if (next && next.nodeType === 3) { t.data += next.data; parent.removeChild(next); }
    if (prev && prev.nodeType === 3) { prev.data += t.data; parent.removeChild(t); }
  }
  function unwrapWords(root) {
    Array.prototype.forEach.call(root.querySelectorAll("span[data-sb-fit-word]"), unwrapOne);
    Array.prototype.forEach.call(root.querySelectorAll("span[data-sb-fit-text]"), unwrapOne);
  }
  function hyphenPass(root) {
    root = root || document.body;
    if (!root.isConnected) return;
    while (root.matches && root.matches("span[data-sb-fit-word], span[data-sb-fit-text]")) root = root.parentElement;
    unwrapWords(root);
    var found = [], skip = new WeakMap(), widths = new WeakMap(), range = document.createRange();
    var tw = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (var n = tw.nextNode(); n; n = tw.nextNode()) {
      var el = n.parentElement;
      if (!el || !/\S{4}/.test(n.data)) continue;
      if (!skip.has(el)) skip.set(el, !!el.closest(NO_HYPHENS));
      if (skip.get(el)) continue;
      var fs = px(getComputedStyle(el).fontSize), bw = blockWidth(el, widths), m;
      BREAK_AFTER.lastIndex = 0;
      while ((m = BREAK_AFTER.exec(n.data))) {
        var word = m[0];
        if (word.length < 4 || word.indexOf("\u00ad") >= 0 || word.length * fs * 0.85 < bw) continue;
        range.setStart(n, m.index);
        range.setEnd(n, m.index + word.length);
        var tops = [];
        Array.prototype.forEach.call(range.getClientRects(), function (r) {
          if (r.width > 0 && !tops.some(function (t) { return Math.abs(t - r.top) < 2; })) tops.push(r.top);
        });
        // break-word breaks inside a word only when it alone does not fit its line: that word, and no other
        if (tops.length > 1) found.push({ node: n, start: m.index, end: m.index + word.length });
      }
    }
    // wrap from the back, so the offsets of earlier words in the same text stay right
    for (var i = found.length - 1; i >= 0; i--) {
      var f = found[i], span = document.createElement("span"), host = f.node.parentNode;
      if (host && host.nodeType === 1 && !host.hasAttribute("data-sb-fit-text") &&
          /(flex|grid)$/.test(getComputedStyle(host).display)) {
        var carrier = document.createElement("span");
        carrier.setAttribute("data-sb-fit-text", "");
        host.replaceChild(carrier, f.node);
        carrier.appendChild(f.node);
      }
      span.className = "sb-hyphenate";
      span.setAttribute("data-sb-fit-word", "");
      range.setStart(f.node, f.start);
      range.setEnd(f.node, f.end);
      range.surroundContents(span);
    }
  }

  // ------------------------------------------------------------------ scheduling
  var PARTS = [
    [".sb-segmented", fitSegmented], [".sb-progress__steps", fitSteps], [".sb-facts-line", fitFacts],
    [".sb-chart", function (fig) { if (fig.querySelector(".sb-chart__end--series")) fitSeries(fig); }],
    [".sb-chart__slots", fitSlots]
  ];
  var queue = new Set(), whole = false, frame = 0, lastKey = "";
  var ro = typeof ResizeObserver === "function" ? new ResizeObserver(function (entries) {
    entries.forEach(function (e) { if (e.target === document.body) { if (key() !== lastKey) whole = true; } else queue.add(e.target); });
    later();
  }) : null;
  function key() {
    var r = document.documentElement;
    return [window.innerWidth, getComputedStyle(r).fontSize, r.getAttribute("data-theme"), r.getAttribute("data-sb-tone"),
      matchMedia("(prefers-color-scheme: dark)").matches, document.fonts ? document.fonts.status : ""].join("|");
  }
  function later() { if (!frame) frame = requestAnimationFrame(run); }
  function run() {
    frame = 0;
    var all = whole;
    whole = false;
    fresh = all && key() !== lastKey;
    var todo = all ? null : Array.from(queue);
    queue.clear();
    PARTS.forEach(function (p) {
      Array.prototype.forEach.call(document.querySelectorAll(p[0]), function (el) {
        if (all || todo.indexOf(el) >= 0) p[1](el);
      });
    });
    if (all) { lastKey = key(); hyphenPass(document.body); }
    else todo.forEach(function (el) { if (el.isConnected) hyphenPass(el); });
  }
  function refresh(el) {
    PARTS.forEach(function (p) {
      Array.prototype.forEach.call((el || document).querySelectorAll(p[0]), function (x) { if (ro) ro.observe(x); queue.add(x); });
    });
    if (!el) whole = true; else queue.add(el);
    later();
  }
  // radios changed elsewhere: a script (sb-tone.js and its event), the user, a form reset
  function syncAll() { Array.prototype.forEach.call(document.querySelectorAll('.sb-segmented[data-sb-fit="select"]'), segSync); }
  document.addEventListener("change", function (e) {
    var t = e.target;
    if (t && t.matches && t.matches('.sb-segmented input[type="radio"]')) segSync(t.closest(".sb-segmented"));
  });
  document.addEventListener("reset", function () { setTimeout(syncAll, 0); });
  document.addEventListener("sb-tone-change", function () { syncAll(); whole = true; later(); });

  function init() {
    // the CSS fallbacks for a page without this script step aside (sebaro.css: the series chart's values form)
    document.documentElement.setAttribute("data-sb-fit-ready", "");
    if (ro) ro.observe(document.body);
    refresh();
    window.addEventListener("resize", function () { whole = true; later(); });
    new MutationObserver(function () { whole = true; later(); })
      .observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme", "data-sb-tone"] });
    var mq = matchMedia("(prefers-color-scheme: dark)");
    if (mq.addEventListener) mq.addEventListener("change", function () { whole = true; later(); });
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(function () { whole = true; later(); });
  }
  window.sbFit = { refresh: function (el) { refresh(el || null); } };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
})();
