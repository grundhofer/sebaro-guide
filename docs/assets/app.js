// app.js: behaviour of app.html that the system scripts do not cover. Classic script, deferred, no network,
// no inline handlers (pages also open from file://).
// 1) [data-g-app-replay-reduced="<frame id>"] replays the start inside that frame as with reduced motion: it sets
//    html[data-sb-motion="reduce"] for the length of one run (sb-start.js reads it), then restores the previous
//    state. Nothing is stored; the stored setting „Bewegung immer reduzieren“ (sb-motion) always wins.
// 2) the radios input[name="set-theme"] (value system | light | dark) in the settings screen choose Hell oder Dunkel for
//    this page, as a phone app does in its settings (MOB-04, D75): they store sb-theme like theme-button.js (read by
//    theme-init.js) and follow the stored choice, also after a press on the page's own button. A product uses its platform's setting instead.
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

(function () {
  var root = document.documentElement;
  var radios = Array.prototype.slice.call(document.querySelectorAll('input[name="set-theme"]'));
  if (!radios.length) return;
  // the stored choice, as theme-init.js reads it (nothing stored = „Wie das System“)
  function current() { var v = null; try { v = localStorage.getItem("sb-theme"); } catch (e) {} return v === "light" || v === "dark" ? v : "system"; }
  function sync() { var c = current(); radios.forEach(function (r) { r.checked = r.value === c; }); }
  radios.forEach(function (r) {
    r.addEventListener("change", function () {
      if (!r.checked) return;
      try {
        if (r.value === "system") { delete root.dataset.theme; localStorage.removeItem("sb-theme"); }
        else { root.dataset.theme = r.value; localStorage.setItem("sb-theme", r.value); }
      } catch (e) { if (r.value === "system") delete root.dataset.theme; else root.dataset.theme = r.value; }
    });
  });
  // the page's own button changes the stored choice too
  document.addEventListener("click", function (event) {
    if (event.target instanceof Element && event.target.closest("[data-sb-theme-button]")) setTimeout(sync, 0);
  });
  window.addEventListener("storage", sync);
  sync();
})();
