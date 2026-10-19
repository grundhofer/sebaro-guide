// app.js: behaviour of app.html that the system scripts do not cover. Classic script, deferred, no network,
// no inline handlers (pages also open from file://).
// 1) [data-g-app-replay-reduced="<frame id>"] replays the start inside that frame as with reduced motion: it sets
//    html[data-sb-motion="reduce"] for the length of one run (sb-start.js reads it), then restores the previous
//    state. Nothing is stored; the stored setting „Bewegung immer reduzieren“ (sb-motion) always wins.
(function () {
  var root = document.documentElement;
  document.addEventListener("click", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[data-g-app-replay-reduced]") : null;
    if (!button || !window.sbStart) return;
    var frame = document.getElementById(button.getAttribute("data-g-app-replay-reduced"));
    if (!frame || frame.classList.contains("sb-starting")) return;
    var wasReduced = root.getAttribute("data-sb-motion") === "reduce";
    if (!wasReduced) root.setAttribute("data-sb-motion", "reduce");
    window.sbStart.play(frame);
    if (wasReduced) return;
    setTimeout(function () {
      var stored = null;
      try { stored = localStorage.getItem("sb-motion"); } catch (e) {}
      if (stored !== "reduce") root.removeAttribute("data-sb-motion");
    }, 1400);
  });
})();
