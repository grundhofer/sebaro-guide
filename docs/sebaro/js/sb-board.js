// sb-board.js: the swipe layout of the board on narrow screens, spec/02 §3.16 (D91 B2b).
// Classic script (pages open from file://), CSP-safe: no inline handlers, no eval.
// Markup (the board works without this script: below 640 px of its width the columns sit side by side and are
// swiped, the start of the next column stays in view, every column is a named region with heading and count):
//   <div class="sb-board" id="retro-board">
//     <div class="sb-board__columns">
//       <section class="sb-board__column" aria-labelledby="c1-h">
//         <div class="sb-board__head"><h3 class="sb-board__title" id="c1-h"><span class="sb-board__name">Gut gelaufen</span>
//           <span class="sb-board__count">2<span class="sb-visually-hidden"> Karten</span></span></h3> …„Mehr“… </div>
//         <ul class="sb-board__cards">…</ul></section> …
// What the script adds, so that in the swipe layout you always know where you are and can get anywhere without
// swiping (the swipe can collide with the system's back gesture at the screen edge):
//   - the position bar .sb-board__nav before the columns (built when the markup has none): „Vorige Spalte“, the
//     position „Spalte 2 von 3: Verbessern“ (announced politely when it changes), „Nächste Spalte“; a step button at
//     either end is aria-disabled. sebaro.css shows the bar only in the swipe layout;
//   - the step buttons scroll the next / previous column into place (smooth only without reduced motion: system
//     setting, html[data-sb-motion="reduce"] or data-sb-motion="reduce" around the board);
//   - every element with data-sb-board-name="<board id>" (e.g. a span in the label „Neue Karte in „…““) shows the name
//     of the column in place, so the primary action says where a new card goes;
//   - an element with data-sb-board-target="<board id>" (written hidden: „ in „<name>““ after „Neue Karte“ in a
//     window, whose wide board names no column) is shown only while the board is in the swipe layout;
//   - the event "sb-board-column" (detail: { index, column }) on the board when the column in place changes;
//     window.sbBoard.current(board) returns that column.
// Tab moves through the cards and „Mehr“ buttons column by column; the browser scrolls a focused element into view and
// the scroll snap settles on its column. Messages follow the language of the board (closest [lang], else
// <html lang>): German default, English built in; more via window.sbMessages["sb-board"] (spec/09 §6.1, D87).
(function () {
  var MESSAGES = {
    de: { prev: "Vorige Spalte", next: "Nächste Spalte", position: "Spalte {n} von {m}: {name}" },
    en: { prev: "Previous column", next: "Next column", position: "Column {n} of {m}: {name}" }
  };
  var extra = window.sbMessages && window.sbMessages["sb-board"];
  if (extra) Object.keys(extra).forEach(function (l) { MESSAGES[l.toLowerCase()] = extra[l]; });
  function t(el, key, vars) {
    var holder = el && el.closest("[lang]");
    var lang = ((holder || document.documentElement).getAttribute("lang") || "de").toLowerCase();
    var table = MESSAGES[lang] || MESSAGES[lang.split("-")[0]] || MESSAGES.de;
    var text = table[key] != null ? table[key] : MESSAGES.de[key];
    return text.replace(/\{(\w+)\}/g, function (m, k) { return vars && vars[k] != null ? vars[k] : m; });
  }
  function reduced(el) {
    return !!el.closest('[data-sb-motion="reduce"]') || window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
  function columnsOf(scroller) {
    return Array.prototype.filter.call(scroller.children, function (c) { return c.classList.contains("sb-board__column"); });
  }
  function nameOf(column) {
    var name = column.querySelector(".sb-board__name") || column.querySelector(".sb-board__title");
    return name ? name.textContent.trim() : "";
  }
  function spriteBase(board) {
    var use = board.querySelector("use");
    var href = use ? (use.getAttribute("href") || "") : "";
    return href.indexOf("#") > 0 ? href.slice(0, href.indexOf("#")) : "";
  }
  function stepButton(board, step) {
    var NS = "http://www.w3.org/2000/svg";
    var button = document.createElement("button");
    button.className = "sb-icon-button";
    button.type = "button";
    button.setAttribute("data-sb-board-step", String(step));
    button.setAttribute("aria-label", t(board, step < 0 ? "prev" : "next"));
    var svg = document.createElementNS(NS, "svg"), use = document.createElementNS(NS, "use");
    svg.setAttribute("class", "sb-icon"); svg.setAttribute("aria-hidden", "true"); svg.setAttribute("focusable", "false");
    use.setAttribute("href", spriteBase(board) + (step < 0 ? "#chevron-left" : "#chevron-right"));
    svg.appendChild(use); button.appendChild(svg);
    return button;
  }
  function buildNav(board, scroller) {
    var nav = document.createElement("div");
    nav.className = "sb-board__nav";
    var position = document.createElement("p");
    position.className = "sb-board__position";
    nav.appendChild(stepButton(board, -1));
    nav.appendChild(position);
    nav.appendChild(stepButton(board, 1));
    board.insertBefore(nav, scroller);
    return nav;
  }

  function setup(board) {
    if (board.__sbBoard) return;
    var scroller = board.querySelector(".sb-board__columns");
    if (!scroller) return;
    var nav = board.querySelector(".sb-board__nav") || buildNav(board, scroller);
    var position = nav.querySelector(".sb-board__position");
    var prev = nav.querySelector('[data-sb-board-step="-1"]'), next = nav.querySelector('[data-sb-board-step="1"]');
    var state = { board: board, scroller: scroller, current: -1, column: null };
    board.__sbBoard = state;

    function inPlace(cols) {
      var box = scroller.getBoundingClientRect(), cs = getComputedStyle(scroller), rtl = cs.direction === "rtl";
      var pad = parseFloat(rtl ? cs.paddingRight : cs.paddingLeft) || 0;
      var edge = rtl ? box.right - pad : box.left + pad, best = 0, bestDistance = Infinity;
      cols.forEach(function (c, i) {
        var r = c.getBoundingClientRect(), d = Math.abs((rtl ? r.right : r.left) - edge);
        if (d < bestDistance) { bestDistance = d; best = i; }
      });
      var max = scroller.scrollWidth - scroller.clientWidth;
      if (max > 1 && Math.abs(scroller.scrollLeft) >= max - 1) best = cols.length - 1;
      return best;
    }
    function update() {
      var cols = columnsOf(scroller);
      if (!cols.length) return;
      var i = inPlace(cols), name = nameOf(cols[i]);
      if (board.id) {   // a window's label names the column only while its board swipes (§3.16, B2b weak point 3)
        var swiping = getComputedStyle(nav).display !== "none";
        document.querySelectorAll('[data-sb-board-target="' + board.id + '"]').forEach(function (el) { el.hidden = !swiping; });
      }
      var text = t(board, "position", { n: i + 1, m: cols.length, name: name });
      if (i === state.current && text === position.textContent) return;   // nothing new: no announcement
      state.current = i; state.column = cols[i];
      position.textContent = text;
      if (!position.hasAttribute("aria-live")) position.setAttribute("aria-live", "polite");
      if (prev) prev.setAttribute("aria-disabled", String(i === 0));
      if (next) next.setAttribute("aria-disabled", String(i === cols.length - 1));
      if (board.id) {
        document.querySelectorAll('[data-sb-board-name="' + board.id + '"]').forEach(function (el) { el.textContent = name; });
      }
      board.dispatchEvent(new CustomEvent("sb-board-column", { bubbles: true, detail: { index: i, column: cols[i] } }));
    }
    var frame = 0;
    scroller.addEventListener("scroll", function () {
      if (!frame) frame = requestAnimationFrame(function () { frame = 0; update(); });
    }, { passive: true });
    nav.addEventListener("click", function (event) {
      var button = event.target instanceof Element ? event.target.closest("[data-sb-board-step]") : null;
      if (!button || button.getAttribute("aria-disabled") === "true") return;
      var cols = columnsOf(scroller);
      var i = Math.max(0, Math.min(cols.length - 1, state.current + Number(button.getAttribute("data-sb-board-step"))));
      cols[i].scrollIntoView({ behavior: reduced(board) ? "auto" : "smooth", block: "nearest", inline: "start" });
    });
    if ("ResizeObserver" in window) new ResizeObserver(function () { update(); }).observe(scroller);
    update();
    nav.hidden = false;
  }
  function init() { document.querySelectorAll(".sb-board").forEach(setup); }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
  window.sbBoard = {
    setup: setup,
    current: function (board) { return board && board.__sbBoard ? board.__sbBoard.column : null; }
  };
})();
