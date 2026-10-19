// sb-start.js: the same start on every platform (D49, D52; spec/03 §14). The app sign tile stands in the middle of
// the ground while the page really loads, then moves to its place in the header ([data-sb-start-target]) while the
// content enters from below (D46 rule E). Only on the first call of a tab session, only on pages that opt in with
// <html data-sb-start>. Reduced motion (system, or html[data-sb-motion="reduce"]) = the tile fades out, nothing moves.
// Load it in <head> as a classic script right after theme-init.js, so the start screen is there at first paint.
// Markup: <div class="sb-start" aria-hidden="true"><span class="sb-start__tile">(inline tile svg)</span></div> as the
// first child of <body>; the header tile carries data-sb-start-target; elements to enter carry data-sb-start-enter.
// An app that loads its own data calls sbStart.hold() before and sbStart.release() after; the start waits for both
// the load event and every release. sbStart.play(scope) replays the start inside one element (component sheet).
// CSP-safe: no inline handlers, styles only through the CSSOM and the Web Animations API.
(function () {
  var root = document.documentElement;
  var holds = 0, loaded = false, done = false;

  function reduced() {
    return root.getAttribute("data-sb-motion") === "reduce" || window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
  function token(name, fallback) {
    var v = getComputedStyle(root).getPropertyValue(name).trim();
    return v || fallback;
  }
  function ms(v) { var n = parseFloat(v); return /ms$/.test(v) ? n : n * 1000; }

  // one run of the start inside scope (the document or one frame); finish() runs once at the end
  function run(scope, overlay, finish) {
    var tile = overlay.querySelector(".sb-start__tile");
    var target = scope.querySelector("[data-sb-start-target]");
    var duration = ms(token("--sb-motion-duration-long", "200ms"));
    var easing = token("--sb-motion-easing-emphasized", "ease-out");
    var enter = Array.prototype.slice.call(scope.querySelectorAll("[data-sb-start-enter]"));
    enter.forEach(function (el) { el.classList.remove("sb-enter"); void el.offsetWidth; el.classList.add("sb-enter"); });
    if (!tile || !target || reduced() || typeof tile.animate !== "function") {
      var fade = typeof overlay.animate === "function" ? overlay.animate([{ opacity: 1 }, { opacity: 0 }], { duration: duration, fill: "forwards" }) : null;
      if (fade) fade.onfinish = finish; else finish();
      return;
    }
    var from = tile.getBoundingClientRect(), to = target.getBoundingClientRect();
    var dx = to.left + to.width / 2 - (from.left + from.width / 2);
    var dy = to.top + to.height / 2 - (from.top + from.height / 2);
    var scale = to.width / from.width;
    target.style.visibility = "hidden";
    overlay.classList.add("is-moving");                       // ground turns transparent: the content shows under the tile
    var move = tile.animate([{ transform: "none" }, { transform: "translate(" + dx + "px, " + dy + "px) scale(" + scale + ")" }],
      { duration: duration, easing: easing, fill: "forwards" });
    move.onfinish = function () { target.style.visibility = ""; finish(); };
  }

  function start() {
    if (done || !loaded || holds > 0) return;
    done = true;
    var overlay = document.querySelector("body > .sb-start");
    if (!overlay) { root.classList.remove("sb-starting"); return; }
    run(document, overlay, function () { root.classList.remove("sb-starting"); overlay.classList.remove("is-moving"); });
  }

  window.sbStart = {
    hold: function () { holds++; },
    release: function () { holds = Math.max(0, holds - 1); start(); },
    // replay inside one element that holds its own .sb-start (demo frames); loadMs stands in for the real loading
    // time (default 700 ms) during which the tile stays in the middle
    play: function (scope, loadMs) {
      var overlay = scope && scope.querySelector(".sb-start");
      if (!overlay || scope.classList.contains("sb-starting")) return;
      scope.classList.add("sb-starting");
      setTimeout(function () {
        run(scope, overlay, function () {
          scope.classList.remove("sb-starting"); overlay.classList.remove("is-moving");
          overlay.getAnimations().concat(overlay.querySelector(".sb-start__tile").getAnimations()).forEach(function (a) { a.cancel(); });
        });
      }, loadMs === undefined ? 700 : loadMs);
    }
  };

  // [data-sb-start-replay="<id>"] replays the start inside that element (component sheet)
  document.addEventListener("click", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[data-sb-start-replay]") : null;
    if (button) window.sbStart.play(document.getElementById(button.getAttribute("data-sb-start-replay")));
  });

  if (!root.hasAttribute("data-sb-start")) return;
  try {
    if (sessionStorage.getItem("sb-started")) return;
    sessionStorage.setItem("sb-started", "1");
  } catch (e) { return; }                                     // no storage: no start rather than a start on every page
  root.classList.add("sb-starting");
  window.addEventListener("load", function () { loaded = true; start(); });
})();
