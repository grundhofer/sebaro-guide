// sb-print.js: paper is always light (D91 W8a; spec/09 §18.3). Classic script, CSP-safe, writes no words.
// Before printing it sets html[data-theme="light"], whatever the screen shows (the system's dark mode or the stored
// „Hell oder Dunkel“ choice), and opens every closed <details> outside navigation (frequent questions, a closed table
// of contents row is navigation and stays off paper); after printing it puts both back. It never touches the stored
// choice (sb-theme) and fires no sb-theme-change. The print rules of css/sebaro.css hide navigation and action zones.
// Since 2026-10-22 tokens.css carries a generated @media print block with the light values (TOKEN-CONTRACT 1.9), so the
// theme part of this script is redundant; it goes once that is checked on the demo pages (spec/09 §18.3). The
// <details> part stays.
(function () {
  var root = document.documentElement;
  var saved = null;
  var opened = [];
  window.addEventListener("beforeprint", function () {
    if (saved) return;
    saved = { theme: root.getAttribute("data-theme") };
    root.setAttribute("data-theme", "light");
    document.querySelectorAll("details:not([open])").forEach(function (d) {
      if (d.closest("nav")) return;
      d.open = true;
      opened.push(d);
    });
  });
  window.addEventListener("afterprint", function () {
    if (!saved) return;
    if (saved.theme === null) root.removeAttribute("data-theme"); else root.setAttribute("data-theme", saved.theme);
    opened.forEach(function (d) { d.open = false; });
    opened = [];
    saved = null;
  });
})();
