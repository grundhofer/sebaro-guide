// theme-button.js: the labelled button „Hell oder Dunkel“ (D36; behaviour spec/03 §6.2, code spec/09 §6).
// Toggles to the other mode of what is shown. Storing the system's own mode would mean "follow the system", so the
// choice is removed instead: two presses always return to the system mode. The label never changes; a visually
// hidden role="status" element ([data-sb-theme-status]) announces the result after a press. Classic script, no
// modules (pages open from file://), CSP-safe.
(function () {
  var root = document.documentElement;
  var system = window.matchMedia("(prefers-color-scheme: dark)");
  function shown() { return root.dataset.theme || (system.matches ? "dark" : "light"); }
  document.addEventListener("click", function (event) {
    var button = event.target.closest(".sb-theme-button");
    if (!button) return;
    var next = shown() === "dark" ? "light" : "dark";
    try {
      if (next === (system.matches ? "dark" : "light")) { delete root.dataset.theme; localStorage.removeItem("sb-theme"); }
      else { root.dataset.theme = next; localStorage.setItem("sb-theme", next); }
    } catch (e) { root.dataset.theme = next; }
    var status = document.querySelector("[data-sb-theme-status]");
    if (status) status.textContent = next === "dark" ? "Dunkel ist an." : "Hell ist an.";
    document.dispatchEvent(new CustomEvent("sb-theme-change", { detail: { theme: next } }));
  });
})();
