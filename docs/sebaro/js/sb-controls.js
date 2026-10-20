// sb-controls.js: behaviour of the interactive sebaro component classes in pages without a framework (spec/02).
// Classic script (pages open from file://), CSP-safe: no inline handlers, no eval, styles only through the CSSOM.
// Every part works on markup that already carries its ARIA state, so a page without this script still shows the
// right state; the script only makes it change.
//   .sb-claim-row__toggle   aria-expanded + hidden on the controlled note (claim rows, D40)
//   .sb-switch              aria-checked; with data-sb-motion-setting it is „Bewegung immer reduzieren“ (D46): it
//                           sets html[data-sb-motion="reduce"] and stores sb-motion (read again by theme-init.js)
//   [data-sb-demo-progress] specimen of D48: the primary action shows its own progress („ok“ or „fail“ run)
//   .sb-chip[aria-pressed]  aria-pressed; one chosen chip per [data-sb-single] group (filter "Alle")
//   [data-sb-opens="id"]    opens <dialog id> as a modal; the dialog's form method="dialog" closes it
//   .sb-range__track        keeps the accent fill between the handles (--sb-range-from / --sb-range-to, 0..1)
//   [data-sb-indeterminate] sets checkbox.indeterminate (no HTML attribute exists for it)
//   .sb-tabs [role="tab"]   aria-selected + hidden on the tab panels (not for aria-disabled="true")
//   .sb-code__copy          copies the code of its block; the label says „Kopiert“ for 2 s
//   .sb-toc[data-sb-follow] the current entry (aria-current="location") follows the reading position
//   .sb-toast               sbToast.show(toast) / sbToast.hide(toast) and [data-sb-toast-show="id"]: the toast enters
//                           (.sb-enter), stays 6 s, pauses while the pointer is over it or focus is inside, Escape
//                           closes it; .sb-toast__action fires "sb-toast-action" on the toast, then it closes (D78)
// Keyboard and pointer of menus, tabs, tooltips, sheets and search fields are sb-menu.js, sb-tabs.js, sb-tooltip.js,
// sb-sheet.js and sb-search.js; windows are sb-tree.js and sb-window.js (spec/02 §7, D80).
// State attributes (D85): ARIA where ARIA has the state (aria-busy, aria-current="step"), data-sb-state for the rest
// ("done", "retry"). Messages follow the language of the element (closest [lang], else <html lang>): German default,
// English built in; window.sbMessages = { "sb-controls": { fr: { … } } } before this script adds one (D87, spec/09 §6.1).
(function () {
  function closestIn(event, selector) { return event.target instanceof Element ? event.target.closest(selector) : null; }

  var MESSAGES = {
    de: { copied: "Kopiert", busy: "Läuft …", done: "Fertig", retry: "Noch mal versuchen", failed: "Das hat nicht geklappt." },
    en: { copied: "Copied", busy: "Working …", done: "Done", retry: "Try again", failed: "That did not work." }
  };
  var extra = window.sbMessages && window.sbMessages["sb-controls"];
  if (extra) Object.keys(extra).forEach(function (l) { MESSAGES[l.toLowerCase()] = extra[l]; });
  function t(el, key) {
    var holder = el && el.closest("[lang]");
    var lang = ((holder || document.documentElement).getAttribute("lang") || "de").toLowerCase();
    var table = MESSAGES[lang] || MESSAGES[lang.split("-")[0]] || MESSAGES.de;
    return table[key] != null ? table[key] : MESSAGES.de[key];
  }

  document.addEventListener("click", function (event) {
    var toggle = closestIn(event, ".sb-claim-row__toggle");
    if (toggle) {
      var open = toggle.getAttribute("aria-expanded") !== "true";
      toggle.setAttribute("aria-expanded", String(open));
      var note = document.getElementById(toggle.getAttribute("aria-controls") || "");
      if (note) note.hidden = !open;
      return;
    }
    var sw = closestIn(event, ".sb-switch");
    if (sw && !sw.disabled) {
      var on = sw.getAttribute("aria-checked") !== "true";
      sw.setAttribute("aria-checked", String(on));
      if (sw.hasAttribute("data-sb-motion-setting")) setMotion(on);
      return;
    }
    var demo = closestIn(event, "[data-sb-demo-progress]");
    if (demo) { demoProgress(demo); return; }

    var chip = closestIn(event, ".sb-chip[aria-pressed]");
    if (chip && !chip.disabled) {
      var group = chip.closest("[data-sb-single]");
      if (group) {
        group.querySelectorAll(".sb-chip[aria-pressed]").forEach(function (c) { c.setAttribute("aria-pressed", String(c === chip)); });
      } else {
        chip.setAttribute("aria-pressed", String(chip.getAttribute("aria-pressed") !== "true"));
      }
      return;
    }
    var opener = closestIn(event, "[data-sb-opens]");
    if (opener) {
      var dialog = document.getElementById(opener.getAttribute("data-sb-opens"));
      if (dialog && typeof dialog.showModal === "function" && !dialog.open) dialog.showModal();
      return;
    }
    var tab = closestIn(event, ".sb-tabs [role='tab']");
    if (tab && tab.getAttribute("aria-disabled") === "true") return;   // a disabled tab is never selected (spec/02 §4.4)
    if (tab) {
      var list = tab.closest("[role='tablist']");
      list.querySelectorAll("[role='tab']").forEach(function (t) {
        var on = t === tab;
        t.setAttribute("aria-selected", String(on));
        t.tabIndex = on ? 0 : -1;
        var panel = document.getElementById(t.getAttribute("aria-controls") || "");
        if (panel) panel.hidden = !on;
      });
      return;
    }
    var toastAction = closestIn(event, ".sb-toast__action");
    if (toastAction) {
      var owner = toastAction.closest(".sb-toast");
      if (owner) {
        owner.dispatchEvent(new CustomEvent("sb-toast-action", { bubbles: true, detail: { action: toastAction.value || toastAction.textContent } }));
        window.sbToast.hide(owner);
      }
      return;
    }
    var toastOpener = closestIn(event, "[data-sb-toast-show]");
    if (toastOpener) {
      var shown = document.getElementById(toastOpener.getAttribute("data-sb-toast-show"));
      if (shown) window.sbToast.show(shown);
      return;
    }
    var copy = closestIn(event, ".sb-code__copy");
    if (copy) {
      var code = copy.closest(".sb-code");
      var text = code ? (code.querySelector("pre") || code).textContent : "";
      var label = copy.querySelector(".sb-code__copy-label") || copy;
      var done = function () { var was = label.textContent; label.textContent = t(copy, "copied"); setTimeout(function () { label.textContent = was; }, 2000); };
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, function () {});
      } catch (e) { /* no clipboard in this context: nothing to do */ }
    }
  });

  function setMotion(reduce) {
    var root = document.documentElement;
    if (reduce) root.dataset.sbMotion = "reduce"; else delete root.dataset.sbMotion;
    try { if (reduce) localStorage.setItem("sb-motion", "reduce"); else localStorage.removeItem("sb-motion"); } catch (e) {}
    document.querySelectorAll(".sb-switch[data-sb-motion-setting]").forEach(function (s) { s.setAttribute("aria-checked", String(reduce)); });
  }

  function icon(href, cls) {
    var NS = "http://www.w3.org/2000/svg", svg = document.createElementNS(NS, "svg"), use = document.createElementNS(NS, "use");
    svg.setAttribute("class", cls || "sb-icon"); svg.setAttribute("aria-hidden", "true"); svg.setAttribute("focusable", "false");
    use.setAttribute("href", href); svg.appendChild(use);
    return svg;
  }

  // D48 specimen: label says what runs, the bar grows over 1.8 s, then the check icon and „<done>“ for the dwell time, or the reason in
  // the bar's message slot and the label „Noch mal versuchen“. The check is the icon, not the character (D10). An app drives the same attributes from its real work.
  function demoProgress(button) {
    if (button.getAttribute("aria-busy") === "true") return;
    var label = button.querySelector(".sb-primary-action__label");
    var bar = button.querySelector(".sb-primary-action__bar");
    var zone = button.closest(".sb-primary-action-bar");
    var message = zone && zone.querySelector(".sb-primary-action-bar__message");
    if (!label || !bar) return;
    var idle = button.getAttribute("data-sb-label") || label.textContent;
    button.setAttribute("data-sb-label", idle);
    if (message) message.textContent = "";
    button.removeAttribute("data-sb-state");
    label.textContent = button.getAttribute("data-sb-busy") || t(button, "busy");
    button.setAttribute("aria-busy", "true");
    button.style.setProperty("--sb-progress", "0");
    requestAnimationFrame(function () { requestAnimationFrame(function () {
      bar.style.transition = "transform 1800ms linear";
      button.style.setProperty("--sb-progress", "1");
    }); });
    setTimeout(function () {
      bar.style.transition = "";
      button.removeAttribute("aria-busy");
      button.style.removeProperty("--sb-progress");
      if (button.getAttribute("data-sb-demo-progress") === "fail") {
        label.textContent = t(button, "retry");
        button.setAttribute("data-sb-state", "retry");
        if (message) {
          message.appendChild(icon("#error--16", "sb-icon sb-icon--16"));
          message.appendChild(document.createTextNode(button.getAttribute("data-sb-fail") || t(button, "failed")));
        }
        button.setAttribute("data-sb-demo-progress", "ok");
        return;
      }
      label.textContent = "";
      label.appendChild(icon("#check"));
      label.appendChild(document.createTextNode(button.getAttribute("data-sb-done") || t(button, "done")));
      button.setAttribute("data-sb-state", "done");
      setTimeout(function () { label.textContent = idle; button.removeAttribute("data-sb-state"); }, 1500);
    }, 1800);
  }

  // D78: the toast's lifetime. 6 s, the same for every toast (spec/02 §4.8); never used for errors, which stay next to
  // what failed. The timer stops while the pointer is over the toast or focus is inside it and runs on with the time
  // that was left; Escape closes it; focus that was inside goes back to where it came from.
  var TOAST_MS = 6000;
  window.sbToast = {
    show: function (toast) {
      if (!toast) return;
      var s = toast._sbToast || (toast._sbToast = { timer: 0, left: 0, since: 0, hold: { pointer: false, focus: false }, from: null });
      clearTimeout(s.timer);
      s.from = document.activeElement;
      toast.hidden = false;
      toast.classList.remove("sb-enter"); void toast.offsetWidth; toast.classList.add("sb-enter");
      s.left = TOAST_MS;
      run(toast);
    },
    hide: function (toast) {
      var s = toast && toast._sbToast;
      if (s) clearTimeout(s.timer);
      if (!toast || toast.hidden) return;
      var focusInside = toast.contains(document.activeElement);
      toast.hidden = true;
      toast.classList.remove("sb-enter");
      if (focusInside && s && s.from && document.contains(s.from)) s.from.focus({ preventScroll: true });
    }
  };
  function run(toast) {
    var s = toast._sbToast;
    clearTimeout(s.timer);
    if (s.hold.pointer || s.hold.focus || toast.hidden) return;
    s.since = Date.now();
    s.timer = setTimeout(function () { window.sbToast.hide(toast); }, s.left);
  }
  function hold(toast, kind, on) {
    var s = toast._sbToast;
    if (!s || toast.hidden) return;
    if (on && !s.hold.pointer && !s.hold.focus) { clearTimeout(s.timer); s.left = Math.max(0, s.left - (Date.now() - s.since)); }
    s.hold[kind] = on;
    if (!on) run(toast);
  }
  document.addEventListener("pointerover", function (event) { var x = closestIn(event, ".sb-toast"); if (x) hold(x, "pointer", true); });
  document.addEventListener("pointerout", function (event) {
    var x = closestIn(event, ".sb-toast");
    if (x && !(event.relatedTarget instanceof Node && x.contains(event.relatedTarget))) hold(x, "pointer", false);
  });
  document.addEventListener("focusin", function (event) { var x = closestIn(event, ".sb-toast"); if (x) hold(x, "focus", true); });
  document.addEventListener("focusout", function (event) {
    var x = closestIn(event, ".sb-toast");
    if (x && !(event.relatedTarget instanceof Node && x.contains(event.relatedTarget))) hold(x, "focus", false);
  });
  document.addEventListener("keydown", function (event) {
    var x = event.key === "Escape" ? closestIn(event, ".sb-toast") : null;
    if (x && x._sbToast) window.sbToast.hide(x);
  });

  function syncRange(track) {
    var inputs = track.querySelectorAll("input[type='range']");
    if (!inputs.length) return;
    function frac(input) {
      var min = parseFloat(input.min || "0"), max = parseFloat(input.max || "100"), v = parseFloat(input.value);
      return max > min ? (v - min) / (max - min) : 0;
    }
    var from = inputs.length > 1 ? Math.min(frac(inputs[0]), frac(inputs[1])) : 0;
    var to = inputs.length > 1 ? Math.max(frac(inputs[0]), frac(inputs[1])) : frac(inputs[0]);
    track.style.setProperty("--sb-range-from", String(from));
    track.style.setProperty("--sb-range-to", String(to));
  }
  document.addEventListener("input", function (event) {
    var track = closestIn(event, ".sb-range__track");
    if (track) syncRange(track);
  });

  function followToc(toc) {
    var links = Array.prototype.slice.call(toc.querySelectorAll('a[href^="#"]'));
    var targets = links.map(function (a) { return document.getElementById(a.hash.slice(1)); });
    if (!links.length || targets.some(function (t) { return !t; })) return;
    function update() {
      var current = 0, root = document.documentElement;
      targets.forEach(function (t, i) { if (t.getBoundingClientRect().top <= 96) current = i; });
      if (window.innerHeight + window.scrollY >= root.scrollHeight - 2) current = links.length - 1;
      links.forEach(function (a, i) { if (i === current) a.setAttribute("aria-current", "location"); else a.removeAttribute("aria-current"); });
    }
    window.addEventListener("scroll", update, { passive: true });
    update();
  }

  function init() {
    document.querySelectorAll(".sb-toc[data-sb-follow]").forEach(followToc);
    document.querySelectorAll(".sb-range__track").forEach(syncRange);
    document.querySelectorAll("[data-sb-indeterminate]").forEach(function (box) { box.indeterminate = true; });
    var reduceSet = document.documentElement.getAttribute("data-sb-motion") === "reduce";
    document.querySelectorAll(".sb-switch[data-sb-motion-setting]").forEach(function (s) { s.setAttribute("aria-checked", String(reduceSet)); });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
})();
