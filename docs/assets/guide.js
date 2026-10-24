// guide.js: behaviour of the guide pages that the system scripts do not cover. Classic script, no modules
// (pages also open from file://), CSP-safe, no network.
// 1) regeln.html: filter the rules by platform and status ([data-g-filter] selects, [data-g-filter-count] status).
(function () {
  var selects = document.querySelectorAll("[data-g-filter]");
  if (!selects.length) return;
  var rules = Array.prototype.slice.call(document.querySelectorAll(".g-rule"));
  var areas = Array.prototype.slice.call(document.querySelectorAll(".g-area"));
  var count = document.querySelector("[data-g-filter-count]");
  function apply() {
    var want = {};
    selects.forEach(function (s) { want[s.getAttribute("data-g-filter")] = s.value; });
    var shown = 0;
    rules.forEach(function (r) {
      var platforms = (r.getAttribute("data-platforms") || "").split(" ");
      var okPlatform = !want.platform || platforms.indexOf(want.platform) >= 0 || platforms.indexOf("alle") >= 0;
      var okStatus = !want.status || r.getAttribute("data-status") === want.status;
      r.hidden = !(okPlatform && okStatus);
      if (!r.hidden) shown += 1;
    });
    areas.forEach(function (a) { a.hidden = !a.querySelector(".g-rule:not([hidden])"); });
    if (count) count.textContent = shown === rules.length ? "Alle " + shown + " Regeln." : shown + " von " + rules.length + " Regeln.";
  }
  selects.forEach(function (s) { s.addEventListener("change", apply); });
  apply();
})();

// 2) token values: an element with data-g-token="--sb-color-accent" shows the value the page actually uses, in the
//    current mode. Values are read, never typed in by hand, so the guide cannot drift from tokens.css.
(function () {
  var els = document.querySelectorAll("[data-g-token]");
  if (!els.length) return;
  function fill() {
    var cs = getComputedStyle(document.documentElement);
    els.forEach(function (el) {
      var v = cs.getPropertyValue(el.getAttribute("data-g-token")).trim();
      el.textContent = /^#[0-9a-f]{6,8}$/i.test(v) ? v.toUpperCase() : v;
    });
  }
  fill();
  document.addEventListener("sb-theme-change", function () { requestAnimationFrame(fill); });
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", fill);
})();

// 3) the page table of contents (details inside .demo-toc) starts closed on narrow screens, so content comes first.
(function () {
  if (!window.matchMedia("(max-width: 1023.98px)").matches) return;
  document.querySelectorAll(".demo-toc > details[open]").forEach(function (d) { d.open = false; });
})();

// 4) tables with .g-table-stack restack per row in narrow places (guide.css); a display change drops the table
//    semantics in some browsers, so the explicit roles are added where the markup does not carry them already.
(function () {
  var tables = document.querySelectorAll("table.g-table-stack");
  function role(el, name) { if (!el.hasAttribute("role")) el.setAttribute("role", name); }
  Array.prototype.forEach.call(tables, function (table) {
    role(table, "table");
    Array.prototype.forEach.call(table.querySelectorAll(":scope > thead, :scope > tbody, :scope > tfoot"), function (g) { role(g, "rowgroup"); });
    Array.prototype.forEach.call(table.querySelectorAll("tr"), function (tr) { role(tr, "row"); });
    Array.prototype.forEach.call(table.querySelectorAll("th"), function (th) {
      role(th, th.getAttribute("scope") === "row" ? "rowheader" : "columnheader");
    });
    Array.prototype.forEach.call(table.querySelectorAll("td"), function (td) { role(td, "cell"); });
  });
})();

// 5) D100 (5): at large text a rule example's stage or a data specimen may scroll sideways in its own frame (a phone
//    frame keeps 320 px, a window row keeps its status word). While it scrolls, it gets tabindex="0", role="region"
//    and a name, so the keyboard reaches what lies past its edge; when it fits again, they go. A frame whose page
//    already gives it a tabindex is left alone.
(function () {
  var frames = document.querySelectorAll(".g-ex__stage, .g-daten-specimen");
  if (!frames.length) return;
  function nameOf(el) {
    var ex = el.closest(".g-ex"), rule = el.closest(".g-rule"), item = el.closest("[aria-labelledby]");
    var label = ex && ex.querySelector(".g-ex__label");
    if (label) return "Beispiel" + (rule ? " " + rule.id : "") + ": " + label.textContent.trim();
    var h = item && document.getElementById(item.getAttribute("aria-labelledby"));
    return "Beispiel: " + (h ? h.textContent.trim() : "Muster");
  }
  function check(el) {
    var mine = el.hasAttribute("data-g-scroll-focus");
    if (!mine && el.hasAttribute("tabindex")) return;
    var scrolls = el.scrollWidth > el.clientWidth + 1;
    if (scrolls && !mine) {
      el.setAttribute("tabindex", "0");
      el.setAttribute("data-g-scroll-focus", "");
      if (!el.hasAttribute("role")) { el.setAttribute("role", "region"); el.setAttribute("data-g-scroll-role", ""); }
      if (!el.hasAttribute("aria-label") && !el.hasAttribute("aria-labelledby")) { el.setAttribute("aria-label", nameOf(el)); el.setAttribute("data-g-scroll-name", ""); }
    } else if (!scrolls && mine && document.activeElement !== el) {
      el.removeAttribute("tabindex");
      el.removeAttribute("data-g-scroll-focus");
      if (el.hasAttribute("data-g-scroll-role")) { el.removeAttribute("role"); el.removeAttribute("data-g-scroll-role"); }
      if (el.hasAttribute("data-g-scroll-name")) { el.removeAttribute("aria-label"); el.removeAttribute("data-g-scroll-name"); }
    }
  }
  var pending = false;
  function all() { pending = false; Array.prototype.forEach.call(frames, check); }
  function later() { if (!pending) { pending = true; requestAnimationFrame(all); } }
  if (typeof ResizeObserver === "function") {
    var ro = new ResizeObserver(later);
    Array.prototype.forEach.call(frames, function (el) { ro.observe(el); if (el.firstElementChild) ro.observe(el.firstElementChild); });
  }
  window.addEventListener("resize", later);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(later);
  later();
})();
