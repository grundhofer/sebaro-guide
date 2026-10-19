// sb-colour-count.js: the colour count per view (spec/03 §1.4), a port of sketch A's live check
// (concepts/runde-2/colour-is-function/skizze.js checkFrame). Not a gate: a review aid for demos and app stand-ins.
// Every view root carries data-sb-view="<name>" (and data-sb-primary-expected="0" where the view has no primary
// action). The line is written into the element [data-sb-colour-count="<name>"], e.g.
// „Farbprüfung: Hauptaktion 1 · Ort 4 · Status 3 · App-Zeichen 1 · Farben ohne Rolle 0 · Text auf Farbfläche 0 · bestanden“.
// Sign tiles (.sb-sign-tile) count as „App-Zeichen“, not as colours. Dataviz colours are a local job inside
// .sb-chart only (spec/01 §8); anywhere else they count as colours without a role.
// Known gaps (as in the sketch): pseudo-element paints (checkbox marks, chip frames, slider handles) and focus outlines
// are not read.
function sbColourCount(view) {
  var ROLES = {
    neutral: ["bg", "surface", "surface-raised", "surface-sunken", "text", "text-muted", "text-subtle", "border",
      "border-strong", "scrim", "on-accent", "on-primary-action"],
    place: ["accent", "link", "link-visited", "focus", "selection"],
    primary: ["primary-action", "primary-action-hover", "primary-action-pressed", "primary-action-outline"],
    status: ["success", "warning", "danger", "info"],
    unused: ["accent-hover", "accent-pressed", "accent-subtle", "text-on-accent-subtle", "on-success", "on-warning",
      "on-danger", "on-info", "success-subtle", "warning-subtle", "danger-subtle", "info-subtle",
      "text-on-success-subtle", "text-on-warning-subtle", "text-on-danger-subtle", "text-on-info-subtle"]
  };
  var DATAVIZ = ["1", "2", "3", "4", "5", "6"];
  var map = {}, probe = document.createElement("span");
  view.appendChild(probe);                                   // resolves every role in the view's own mode
  Object.keys(ROLES).forEach(function (group) {
    ROLES[group].forEach(function (role) {
      probe.style.color = "var(--sb-color-" + role + ")";
      var c = getComputedStyle(probe).color;
      if (!(c in map)) map[c] = group;                       // equal values: the first group wins (neutral first)
    });
  });
  DATAVIZ.forEach(function (i) {
    probe.style.color = "var(--sb-dataviz-categorical-" + i + ")";
    var c = getComputedStyle(probe).color;
    if (!(c in map)) map[c] = "dataviz";
  });
  view.removeChild(probe);
  function clear(c) { return !c || c === "none" || c === "transparent" || /, 0\)$/.test(c); }
  function ownText(e) {
    return Array.prototype.some.call(e.childNodes, function (t) { return t.nodeType === 3 && /\S/.test(t.nodeValue); });
  }
  var SHAPES = /^(path|circle|rect|polygon|polyline|ellipse|line)$/i;
  var n = { primary: 0, place: 0, status: 0, signs: view.querySelectorAll(".sb-sign-tile").length, unknown: {}, textOnColour: 0 };
  view.querySelectorAll("*").forEach(function (e) {
    if (e.closest(".sb-sign-tile") || !e.getClientRects().length) return;
    var cs = getComputedStyle(e);
    if (cs.visibility === "hidden") return;
    var paints = [];
    if (!clear(cs.backgroundColor)) paints.push(["fill", cs.backgroundColor]);
    ["Top", "Right", "Bottom", "Left"].forEach(function (side) {
      if (parseFloat(cs["border" + side + "Width"]) > 0 && cs["border" + side + "Style"] !== "none") paints.push(["line", cs["border" + side + "Color"]]);
    });
    if (ownText(e)) paints.push(["text", cs.color]);
    if (SHAPES.test(e.tagName)) {
      if (!clear(cs.fill)) paints.push(["shape", cs.fill]);
      if (!clear(cs.stroke) && parseFloat(cs.strokeWidth) > 0) paints.push(["shape", cs.stroke]);
    }
    if (/^use$/i.test(e.tagName)) paints.push(["shape", cs.color]);   // sprite icons paint in currentColor inside <use>
    paints.forEach(function (p) {
      if (clear(p[1])) return;
      var group = map[p[1]];
      if (group === "dataviz" && e.closest(".sb-chart")) return;
      if (!group || group === "unused" || group === "dataviz") { n.unknown[p[1]] = 1; return; }
      if (group === "primary" && p[0] === "fill") n.primary++;
      else if (group === "place") n.place++;
      else if (group === "status") n.status++;
    });
    if (ownText(e)) {                                         // the nearest painted ground behind this text
      var a = e;
      while (a && a !== view.parentElement && clear(getComputedStyle(a).backgroundColor)) a = a.parentElement;
      var g = a && a !== view.parentElement ? map[getComputedStyle(a).backgroundColor] : "neutral";
      if (g !== "neutral" && g !== "primary") n.textOnColour++;
    }
  });
  var expected = view.hasAttribute("data-sb-primary-expected") ? +view.getAttribute("data-sb-primary-expected") : 1;
  var unknown = Object.keys(n.unknown);
  n.pass = n.primary === expected && unknown.length === 0 && n.textOnColour === 0;
  n.line = "Farbprüfung: Hauptaktion " + n.primary + " · Ort " + n.place + " · Status " + n.status + " · App-Zeichen " +
    n.signs + " · Farben ohne Rolle " + unknown.length + " · Text auf Farbfläche " + n.textOnColour + " · " +
    (n.pass ? "bestanden" : "nicht bestanden");
  n.unknown = unknown;
  return n;
}

(function () {
  function run() {
    document.querySelectorAll("[data-sb-view]").forEach(function (view) {
      var out = document.querySelector('[data-sb-colour-count="' + view.getAttribute("data-sb-view") + '"]');
      if (out) out.textContent = sbColourCount(view).line;
    });
  }
  // After a mode change the colour transitions (--sb-motion-duration-short) are still running: count once they end,
  // otherwise a half-way colour reads as a colour without a role.
  function runSettled() {
    requestAnimationFrame(function () {
      var running = document.getAnimations ? document.getAnimations().map(function (a) { return a.finished.catch(function () {}); }) : [];
      Promise.race([Promise.all(running), new Promise(function (r) { setTimeout(r, 1000); })]).then(run);
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", run); else run();
  document.addEventListener("sb-theme-change", runSettled);
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", runSettled);
})();
