// grundlagen.js: behaviour of grundlagen.html that the system scripts do not cover. Classic script, loaded with
// defer, no network, no inline handlers. The page works without it; only the two demos below need it.
// 1) [data-g-grundlagen-enter="<li id>"]: shows the hidden row, or plays its entry again (.sb-enter, BEW-02).
// 2) [data-g-grundlagen-motion-state]: says in words which motion rule is active right now (BEW-04).
// 3) input[name="g-pa-state"]: puts the one primary action of the states section into a frozen state (specimen hooks).
(function () {
  document.addEventListener("click", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[data-g-grundlagen-enter]") : null;
    if (!button) return;
    var row = document.getElementById(button.getAttribute("data-g-grundlagen-enter"));
    if (!row) return;
    row.hidden = false;
    row.classList.remove("sb-enter");
    void row.offsetWidth; // restart the animation
    row.classList.add("sb-enter");
    button.textContent = button.getAttribute("data-g-grundlagen-again") || button.textContent;
  });
})();

(function () {
  var out = document.querySelector("[data-g-grundlagen-motion-state]");
  if (!out) return;
  var system = window.matchMedia("(prefers-reduced-motion: reduce)");
  function say() {
    var setting = document.documentElement.getAttribute("data-sb-motion") === "reduce";
    if (setting) out.textContent = "Gerade gilt: nur Einblenden, weil „Bewegung immer reduzieren“ an ist.";
    else if (system.matches) out.textContent = "Gerade gilt: nur Einblenden, weil dein System Bewegung reduziert.";
    else out.textContent = "Gerade gilt: Neues kommt 8 px von unten, in 200 ms.";
  }
  say();
  if (system.addEventListener) system.addEventListener("change", say);
  // sb-controls.js sets html[data-sb-motion] when the switch is pressed; follow the attribute itself
  if (window.MutationObserver) new MutationObserver(say).observe(document.documentElement, { attributes: true, attributeFilter: ["data-sb-motion"] });
})();

(function () {
  var radios = document.querySelectorAll('input[name="g-pa-state"]');
  var button = document.getElementById("g-pa-button");
  if (!radios.length || !button) return;
  function apply(value) {
    button.classList.remove("is-hover", "is-pressed", "is-focus");
    button.disabled = value === "disabled";
    if (value === "hover" || value === "pressed" || value === "focus") button.classList.add("is-" + value);
  }
  radios.forEach(function (r) {
    r.addEventListener("change", function () { if (r.checked) apply(r.value); });
    if (r.checked) apply(r.value);
  });
})();
