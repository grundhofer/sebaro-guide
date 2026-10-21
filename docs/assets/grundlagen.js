// grundlagen.js: behaviour of grundlagen.html that the system scripts do not cover. Classic script, loaded with
// defer, no network, no inline handlers. The page works without it; only the two demos below need it.
// 1) [data-g-grundlagen-enter="<li id>"]: shows the hidden row, or plays its entry again (.sb-enter, BEW-02).
// 2) [data-g-grundlagen-motion-state]: says in words which motion rule is active right now (BEW-04).
// 3) input[name="g-pa-state"]: puts the one primary action of the states section into a frozen state (specimen hooks).
// 4) [data-g-tone-sample="cool|warm"]: the two colour tones side by side (FAR-15), see the block below.
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

// 4) Colour tone samples. tokens.css switches the tone only on the root (html[data-sb-tone="warm"]), so a part of the
//    page cannot show the other tone by itself. This copies the grey roles of each tone, in the mode shown now, from the
//    rules of tokens.css onto its sample as custom properties: no value is typed in here, the page cannot drift. The
//    role names are the ones the warm rule replaces. The samples stay hidden when the rules cannot be read.
//    The live values on this page ([data-g-token], filled by guide.js) are read again when the tone changes.
(function () {
  var box = document.querySelector("[data-g-tone-samples]");
  var root = document.documentElement;
  var dark = window.matchMedia("(prefers-color-scheme: dark)");
  var WARM = ':root[data-sb-tone="warm"]';

  function tokenRules() {
    var out = [];
    function walk(list) {
      Array.prototype.forEach.call(list, function (rule) {
        if (rule.selectorText) out.push(rule);
        else if (rule.cssRules) walk(rule.cssRules);
      });
    }
    Array.prototype.forEach.call(document.styleSheets, function (sheet) {
      if (!sheet.href || !/\/sebaro\/tokens\.css$/.test(sheet.href)) return;
      try { walk(sheet.cssRules); } catch (e) { /* unreadable sheet: samples stay hidden */ }
    });
    return out;
  }
  function selectors(rule) { return rule.selectorText.split(",").map(function (s) { return s.trim(); }); }
  function find(rules, test) {
    for (var i = 0; i < rules.length; i++) if (test(selectors(rules[i]))) return rules[i];
    return null;
  }
  function mode() {
    var t = root.getAttribute("data-theme");
    return t === "light" || t === "dark" ? t : (dark.matches ? "dark" : "light");
  }

  function apply() {
    if (!box) return;
    var rules = tokenRules();
    var src = {
      cool: { light: find(rules, function (s) { return s.indexOf(":root") >= 0 && s.indexOf('[data-theme="light"]') >= 0; }),
              dark: find(rules, function (s) { return s.length === 1 && s[0] === '[data-theme="dark"]'; }) },
      warm: { light: find(rules, function (s) { return s.indexOf(WARM) >= 0; }),
              dark: find(rules, function (s) { return s.indexOf(WARM + '[data-theme="dark"]') >= 0; }) }
    };
    var m = mode();
    var names = src.warm.light ? Array.prototype.slice.call(src.warm.light.style).filter(function (n) { return n.indexOf("--sb-") === 0; }) : [];
    var fallback = document.querySelector("[data-g-tone-fallback]");
    if (!names.length || !src.cool[m] || !src.warm[m]) { box.hidden = true; if (fallback) fallback.hidden = false; return; }
    box.querySelectorAll("[data-g-tone-sample]").forEach(function (sample) {
      var rule = src[sample.getAttribute("data-g-tone-sample")][m];
      if (!rule) return;
      sample.setAttribute("data-theme", m);          // re-declares the derived tokens of tokens.css on the sample
      names.forEach(function (n) { sample.style.setProperty(n, rule.style.getPropertyValue(n).trim()); });
      var cs = getComputedStyle(sample);
      sample.querySelectorAll("[data-g-tone-value]").forEach(function (el) {
        var v = cs.getPropertyValue(el.getAttribute("data-g-tone-value")).trim();
        el.textContent = /^#[0-9a-f]{6,8}$/i.test(v) ? v.toUpperCase() : v;
      });
    });
    box.hidden = false;
    if (fallback) fallback.hidden = true;
  }

  function refreshTokens() {
    var cs = getComputedStyle(root);
    document.querySelectorAll("[data-g-token]").forEach(function (el) {
      var v = cs.getPropertyValue(el.getAttribute("data-g-token")).trim();
      el.textContent = /^#[0-9a-f]{6,8}$/i.test(v) ? v.toUpperCase() : v;
    });
  }

  apply();
  if (dark.addEventListener) dark.addEventListener("change", apply);
  if (window.MutationObserver) new MutationObserver(function (records) {
    apply();
    if (records.some(function (r) { return r.attributeName === "data-sb-tone"; })) refreshTokens();
  }).observe(root, { attributes: true, attributeFilter: ["data-theme", "data-sb-tone"] });
})();
