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
