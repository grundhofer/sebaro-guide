// sb-window.js: behaviour of the sebaro desktop window (spec/02 §4.12–§4.18; D67, D72, D75, D81, D84). Tauri windows
// and web apps with a window. Classic script (pages open from file://), CSP-safe: no inline handlers, no eval, no
// inline styles. Progressive enhancement: the markup already carries every state (aria-expanded on the pane toggles,
// hidden on hidden panes, aria-selected / aria-current on rows, aria-checked on check items, the macOS form of every
// shortcut); without this script the window shows that state and only loses the interaction.
//   .sb-keys[data-sb-keys]        shortcut text per platform and language: „⌘K“ on macOS, „Strg+K“ / „Ctrl+K“ on
//                                 Windows and Linux (D84, spec/01 §2.1), plus the spoken form for screen readers;
//                                 aria-keyshortcuts="Meta+…" becomes "Control+…" off macOS
//   [data-sb-window-toggle]       shows / hides the pane named by aria-controls (sidebar, inspector; D81) and keeps
//                                 aria-expanded (aria-checked on a menuitemcheckbox in „Darstellung“); a pane that no longer fits beside the content (480 px) becomes an
//                                 overlay (CSS container query) and is closed here; opened again it lies over the
//                                 content edge, Escape or a click outside closes it and focus returns to the toggle
//   .sb-listbox[role="listbox"]   ↑ ↓ Home End move and choose; with aria-multiselectable: ⇧ + arrow / click extends,
//                                 ⌘ / Strg + click toggles, Space toggles, ⌘A / Strg+A chooses all, Escape keeps only
//                                 the current row (D67 (8)); data-sb-selection-status="<id>" names the state sentence
//                                 that says „3 ausgewählt“ while two or more are chosen (D72); fires "sb-selection-change"
//   [data-sb-theme-choice]        „Wie das System“ / „Hell“ / „Dunkel“ (system | light | dark) in the menu „Darstellung“
//                                 and in the palette (D75); stores sb-theme like theme-button.js, read by theme-init.js;
//                                 keeps aria-checked on every choice; fires "sb-theme-change" on document
//   .sb-command-palette           dialog.sb-command-palette opens with ⌘K (macOS) / Strg+K (Windows, Linux) and with
//                                 [data-sb-palette-open="<id>"]; typing filters (name, data-sb-keywords, group head),
//                                 ↑ ↓ move the active option, Enter runs it, Escape closes, focus returns (D67 (4),
//                                 D84). Running an option: data-sb-theme-choice is applied, data-sb-palette-click="<id>"
//                                 clicks that control (one code path for the tool and the palette), and "sb-command"
//                                 (bubbles, detail.command = data-sb-command) is fired on the option. Check marks of
//                                 setting options follow their control (aria-expanded / aria-pressed / aria-checked)
// Tool tooltips („Name Kürzel“) are the system tooltip of sb-tooltip.js (aria-describedby + popover="manual").
// Platform: <html data-sb-platform="mac|windows|linux"> (a Tauri app sets it from its OS), else the user agent.
// Messages follow the language of the element (closest [lang], else <html lang>): German default, English built in;
// window.sbMessages = { "sb-window": { fr: { … } } } before this script adds one (D87, spec/09 §6.1).
(function () {
  "use strict";
  var MESSAGES = {
    de: {
      selected: "{n} ausgewählt",
      noMatch: "Kein Befehl passt zu „{q}“.",
      // visible key words off macOS, spoken names (screen readers); macOS shows the font's key glyphs (D68)
      keyWords: { Mod: "Strg", Ctrl: "Strg", Shift: "Umschalt", Alt: "Alt", Enter: "Eingabe", Escape: "Esc", Backspace: "Rücktaste", Delete: "Entf", Tab: "Tab", Space: "Leertaste" },
      keySpoken: { Mod: "Befehl", Ctrl: "Control", Shift: "Umschalt", Alt: "Wahl", Enter: "Eingabe", Escape: "Escape", Backspace: "Rückschritt", Delete: "Entfernen", Tab: "Tabulator", Space: "Leertaste", Up: "Pfeil nach oben", Down: "Pfeil nach unten", Left: "Pfeil nach links", Right: "Pfeil nach rechts", Comma: "Komma", Period: "Punkt", Plus: "Plus", Minus: "Minus", Backslash: "Backslash", Slash: "Schrägstrich" },
      keySpokenOther: { Mod: "Steuerung", Ctrl: "Steuerung", Alt: "Alt" }
    },
    en: {
      selected: "{n} selected",
      noMatch: "No command matches “{q}”.",
      keyWords: { Mod: "Ctrl", Ctrl: "Ctrl", Shift: "Shift", Alt: "Alt", Enter: "Enter", Escape: "Esc", Backspace: "Backspace", Delete: "Del", Tab: "Tab", Space: "Space" },
      keySpoken: { Mod: "Command", Ctrl: "Control", Shift: "Shift", Alt: "Option", Enter: "Return", Escape: "Escape", Backspace: "Delete", Delete: "Forward delete", Tab: "Tab", Space: "Space", Up: "Up arrow", Down: "Down arrow", Left: "Left arrow", Right: "Right arrow", Comma: "Comma", Period: "Period", Plus: "Plus", Minus: "Minus", Backslash: "Backslash", Slash: "Slash" },
      keySpokenOther: { Mod: "Control", Ctrl: "Control", Alt: "Alt" }
    }
  };
  var extra = window.sbMessages && window.sbMessages["sb-window"];
  if (extra) Object.keys(extra).forEach(function (l) { MESSAGES[l.toLowerCase()] = extra[l]; });
  function table(el) {
    var holder = el && el.closest && el.closest("[lang]");
    var lang = ((holder || document.documentElement).getAttribute("lang") || "de").toLowerCase();
    return { lang: lang, m: MESSAGES[lang] || MESSAGES[lang.split("-")[0]] || MESSAGES.de };
  }
  function t(el, key, values) {
    var tb = table(el), s = tb.m[key] != null ? tb.m[key] : MESSAGES.de[key];
    if (typeof s !== "string") return s;
    return s.replace(/\{(\w+)\}/g, function (_, k) {
      var v = values && values[k];
      if (typeof v === "number") { try { return new Intl.NumberFormat(tb.lang).format(v); } catch (e) { return String(v); } }
      return v == null ? "" : String(v);
    });
  }
  function closestIn(event, selector) { return event.target instanceof Element ? event.target.closest(selector) : null; }
  var root = document.documentElement;

  // ------------------------------------------------------------------ platform and shortcuts
  function isMac() {
    var p = root.getAttribute("data-sb-platform");
    if (p) return p === "mac";
    var ua = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || navigator.userAgent || "";
    return /mac|iphone|ipad|ipod/i.test(ua);
  }
  function modKey(event) { return isMac() ? event.metaKey && !event.ctrlKey : event.ctrlKey && !event.metaKey; }
  var GLYPHS = { Mod: "⌘", Ctrl: "⌃", Shift: "⇧", Alt: "⌥", Enter: "↩", Escape: "⎋", Backspace: "⌫", Delete: "⌦", Tab: "⇥",
                 Up: "↑", Down: "↓", Left: "←", Right: "→", Comma: ",", Period: ".", Plus: "+", Minus: "-", Backslash: "\\", Slash: "/" };
  var ARROWS = { Up: "↑", Down: "↓", Left: "←", Right: "→", Comma: ",", Period: ".", Plus: "+", Minus: "-", Backslash: "\\", Slash: "/" };
  var MAC_ORDER = ["Ctrl", "Alt", "Shift", "Mod"], OTHER_ORDER = ["Mod", "Ctrl", "Alt", "Shift"];
  // "Shift+Mod+P" → one chord; "Up Down" → two keys shown side by side („↑↓“)
  function keyText(spec, el) {
    var m = table(el).m, mac = isMac();
    var words = m.keyWords || MESSAGES.de.keyWords, spoken = m.keySpoken || MESSAGES.de.keySpoken;
    var spokenOther = m.keySpokenOther || MESSAGES.de.keySpokenOther;
    var shown = [], said = [];
    spec.trim().split(/\s+/).forEach(function (chord) {
      var parts = chord.split("+").filter(Boolean);
      var mods = parts.filter(function (p) { return MAC_ORDER.indexOf(p) >= 0; });
      var keys = parts.filter(function (p) { return MAC_ORDER.indexOf(p) < 0; });
      mods.sort(function (a, b) { var o = mac ? MAC_ORDER : OTHER_ORDER; return o.indexOf(a) - o.indexOf(b); });
      var all = mods.concat(keys);
      if (mac) shown.push(all.map(function (k) { return GLYPHS[k] || words[k] || k.toUpperCase(); }).join(""));
      else shown.push(all.map(function (k) { return ARROWS[k] || words[k] || k.toUpperCase(); }).join("+"));
      said.push(all.map(function (k) {
        return (!mac && spokenOther[k]) || spoken[k] || (k.length === 1 ? k.toUpperCase() : k);
      }).join(" "));
    });
    return { shown: shown.join(""), said: said.join(", ") };
  }
  function renderKeys(scope) {
    (scope || document).querySelectorAll(".sb-keys[data-sb-keys]").forEach(function (box) {
      var txt = keyText(box.getAttribute("data-sb-keys"), box);
      var vis = box.querySelector("[aria-hidden='true']"), sr = box.querySelector(".sb-visually-hidden");
      if (!vis) { vis = document.createElement("span"); vis.setAttribute("aria-hidden", "true"); box.textContent = ""; box.appendChild(vis); }
      if (!sr) { sr = document.createElement("span"); sr.className = "sb-visually-hidden"; box.appendChild(sr); }
      vis.textContent = txt.shown;
      sr.textContent = txt.said;
    });
    if (!isMac()) {
      (scope || document).querySelectorAll("[aria-keyshortcuts*='Meta']").forEach(function (el) {
        el.setAttribute("aria-keyshortcuts", el.getAttribute("aria-keyshortcuts").replace(/\bMeta\b/g, "Control"));
      });
    }
  }

  // ------------------------------------------------------------------ panes (D81)
  var panes = {};   // pane id → { pane, toggles, want, overlay }
  function paneState(id) {
    var pane = document.getElementById(id);
    if (!pane) return null;
    var s = panes[id];
    if (!s || s.pane !== pane) {
      s = panes[id] = { pane: pane, want: !pane.hidden, overlay: false };
      s.overlay = isOverlay(pane);
    }
    s.toggles = Array.prototype.slice.call(document.querySelectorAll("[data-sb-window-toggle][aria-controls='" + id + "']"));
    return s;
  }
  function isOverlay(pane) { return getComputedStyle(pane).position === "absolute"; }
  function focusInto(pane) {
    var el = pane.querySelector("[role='treeitem'][tabindex='0'], [role='option'][tabindex='0'], [aria-current]:not([aria-current='false']), a[href], button:not([disabled]), input:not([disabled]), [tabindex='0']");
    if (el) el.focus({ preventScroll: true });
  }
  function setPane(s, open, how) {
    s.pane.hidden = !open;
    s.toggles.forEach(function (b) { b.setAttribute(b.getAttribute("role") === "menuitemcheckbox" ? "aria-checked" : "aria-expanded", String(open)); });
    if (how === "user" && !s.overlay) s.want = open;
    if (open && s.overlay && how === "user") {
      s.pane.classList.remove("sb-enter"); void s.pane.offsetWidth; s.pane.classList.add("sb-enter");
      focusInto(s.pane);
    }
  }
  function closeOverlay(s, focusToggle) {
    setPane(s, false, "auto");
    var back = s.toggles.filter(function (b) { return b.hasAttribute("aria-expanded"); })[0];
    if (focusToggle && back) back.focus({ preventScroll: true });
  }
  function relayout(win) {
    win.querySelectorAll("[data-sb-window-toggle][aria-controls]").forEach(function (b) {
      var s = paneState(b.getAttribute("aria-controls"));
      if (!s) return;
      var now = isOverlay(s.pane);
      if (now === s.overlay && s.seen) return;
      s.seen = true;
      if (now && !s.overlay) setPane(s, false, "auto");        // no room beside the content: the side part goes first
      else if (now && !s.pane.hidden) setPane(s, false, "auto"); // first look: an overlay never starts open
      else if (!now && s.overlay) setPane(s, s.want, "auto");   // room again: the pane comes back as the user left it
      s.overlay = now;
    });
  }
  document.addEventListener("animationend", function (event) {
    if (event.target instanceof Element && event.target.matches(".sb-window__sidebar, .sb-window__inspector")) event.target.classList.remove("sb-enter");
  });

  // ------------------------------------------------------------------ list selection (D67 (8), D72)
  function options(lb) {
    return Array.prototype.slice.call(lb.querySelectorAll("[role='option']")).filter(function (o) { return !o.hidden; });
  }
  function multi(lb) { return lb.getAttribute("aria-multiselectable") === "true"; }
  function chosen(lb) { return options(lb).filter(function (o) { return o.getAttribute("aria-selected") === "true"; }); }
  function setCurrent(lb, opt) {
    options(lb).forEach(function (o) {
      o.tabIndex = o === opt ? 0 : -1;
      if (multi(lb)) { if (o === opt) o.setAttribute("aria-current", "true"); else o.removeAttribute("aria-current"); }
    });
    if (opt) opt.focus();
  }
  function choose(lb, list, keepOthers) {
    options(lb).forEach(function (o) {
      if (list.indexOf(o) >= 0) o.setAttribute("aria-selected", "true");
      else if (!keepOthers) o.setAttribute("aria-selected", "false");
    });
    announce(lb);
  }
  function range(lb, a, b) {
    var all = options(lb), i = all.indexOf(a), j = all.indexOf(b);
    if (i < 0) i = j;
    return all.slice(Math.min(i, j), Math.max(i, j) + 1);
  }
  function announce(lb) {
    var status = document.getElementById(lb.getAttribute("data-sb-selection-status") || "");
    var n = chosen(lb).length;
    if (status) {
      if (!status.hasAttribute("data-sb-text")) status.setAttribute("data-sb-text", status.textContent);
      status.textContent = multi(lb) && n > 1 ? t(status, "selected", { n: n }) : status.getAttribute("data-sb-text");
    }
    lb.dispatchEvent(new CustomEvent("sb-selection-change", { bubbles: true, detail: { count: n } }));
  }
  function listKey(event, lb, opt) {
    var all = options(lb), i = all.indexOf(opt), next = null, m = multi(lb);
    switch (event.key) {
      case "ArrowDown": next = all[Math.min(i + 1, all.length - 1)]; break;
      case "ArrowUp": next = all[Math.max(i - 1, 0)]; break;
      case "Home": next = all[0]; break;
      case "End": next = all[all.length - 1]; break;
      case " ":
        if (m) choose(lb, opt.getAttribute("aria-selected") === "true" ? chosen(lb).filter(function (o) { return o !== opt; }) : chosen(lb).concat(opt));
        else choose(lb, [opt]);
        event.preventDefault(); return;
      case "Escape":
        if (m && chosen(lb).length > 1) { choose(lb, [opt]); lb._sbAnchor = opt; event.preventDefault(); }
        return;
      default:
        if (m && (event.key === "a" || event.key === "A") && modKey(event)) { choose(lb, all); event.preventDefault(); }
        return;
    }
    event.preventDefault();
    if (!next) return;
    if (m && event.shiftKey) choose(lb, range(lb, lb._sbAnchor || opt, next));
    else { choose(lb, [next]); lb._sbAnchor = next; }
    setCurrent(lb, next);
  }
  function listClick(event, lb, opt) {
    var m = multi(lb);
    if (m && modKey(event)) {
      var on = opt.getAttribute("aria-selected") === "true";
      choose(lb, on ? chosen(lb).filter(function (o) { return o !== opt; }) : chosen(lb).concat(opt));
      lb._sbAnchor = opt;
    } else if (m && event.shiftKey) choose(lb, range(lb, lb._sbAnchor || opt, opt));
    else { choose(lb, [opt]); lb._sbAnchor = opt; }
    setCurrent(lb, opt);
  }

  // ------------------------------------------------------------------ Hell oder Dunkel in the menu „Darstellung“ (D75)
  function themeChoice() { return root.dataset.theme === "light" || root.dataset.theme === "dark" ? root.dataset.theme : "system"; }
  function syncTheme() {
    var c = themeChoice();
    document.querySelectorAll("[data-sb-theme-choice]").forEach(function (el) {
      el.setAttribute("aria-checked", String(el.getAttribute("data-sb-theme-choice") === c));
    });
  }
  function applyTheme(choice) {
    try {
      if (choice === "light" || choice === "dark") { root.dataset.theme = choice; localStorage.setItem("sb-theme", choice); }
      else { delete root.dataset.theme; localStorage.removeItem("sb-theme"); }
    } catch (e) { if (choice === "light" || choice === "dark") root.dataset.theme = choice; else delete root.dataset.theme; }
    syncTheme();
    var shown = root.dataset.theme || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    document.dispatchEvent(new CustomEvent("sb-theme-change", { detail: { theme: shown, choice: themeChoice() } }));
  }
  document.addEventListener("sb-theme-change", syncTheme);

  // ------------------------------------------------------------------ command palette (D67 (4), D84)
  function norm(s) { return (s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, ""); }
  function paletteInput(pal) { return pal.querySelector(".sb-command-palette__search input"); }
  function paletteOptions(pal) { return Array.prototype.slice.call(pal.querySelectorAll("[role='option']")); }
  function syncChecks(pal) {
    var c = themeChoice();
    paletteOptions(pal).forEach(function (o) {
      if (!o.hasAttribute("aria-checked")) return;
      if (o.hasAttribute("data-sb-theme-choice")) { o.setAttribute("aria-checked", String(o.getAttribute("data-sb-theme-choice") === c)); return; }
      var target = document.getElementById(o.getAttribute("data-sb-palette-click") || "");
      if (!target) return;
      var state = target.getAttribute("aria-expanded") || target.getAttribute("aria-pressed") || target.getAttribute("aria-checked");
      if (state) o.setAttribute("aria-checked", String(state === "true"));
    });
  }
  function activate(pal, opt) {
    var input = paletteInput(pal);
    paletteOptions(pal).forEach(function (o) { o.setAttribute("aria-selected", String(o === opt)); });
    if (input) { if (opt) input.setAttribute("aria-activedescendant", opt.id); else input.removeAttribute("aria-activedescendant"); }
    if (opt && opt.scrollIntoView) opt.scrollIntoView({ block: "nearest" });
  }
  function filter(pal, query) {
    var words = norm(query).split(/\s+/).filter(Boolean), first = null, byName = null, count = 0;
    pal.querySelectorAll(".sb-command-palette__section").forEach(function (sec) {
      var head = sec.querySelector(".sb-command-palette__group"), any = false;
      sec.querySelectorAll("[role='option']").forEach(function (o) {
        var name = o.querySelector(".sb-row__name"), own = norm(name ? name.textContent : o.textContent);
        var hay = own + " " + norm((o.getAttribute("data-sb-keywords") || "") + " " + (head ? head.textContent : ""));
        var ok = words.every(function (w) { return hay.indexOf(w) >= 0; });
        o.hidden = !ok;
        if (ok) {
          any = true; count++;
          if (!first) first = o;
          if (!byName && words.length && words.every(function (w) { return own.indexOf(w) >= 0; })) byName = o;
        }
      });
      sec.hidden = !any;
    });
    var empty = pal.querySelector(".sb-command-palette__empty");
    if (empty) empty.textContent = count ? "" : t(empty, "noMatch", { q: query.trim() });
    activate(pal, byName || first);   // a match in the name goes before a match in keywords or the group head
  }
  function wirePalette(dlg) {
    if (dlg._sbWired) return;
    dlg._sbWired = true;
    dlg.addEventListener("close", function () {
      var from = dlg._sbFrom, active = document.activeElement;
      if (from && document.contains(from) && (!active || active === document.body || dlg.contains(active))) from.focus({ preventScroll: true });
    });
    dlg.addEventListener("click", function (event) { if (event.target === dlg) dlg.close(); });   // the backdrop
  }
  function openPalette(dlg, from) {
    if (!dlg || typeof dlg.showModal !== "function") return;
    wirePalette(dlg);
    dlg._sbFrom = from && from !== document.body ? from : null;
    var input = paletteInput(dlg);
    if (input) input.value = "";
    syncChecks(dlg);
    renderKeys(dlg);
    filter(dlg, "");
    if (!dlg.open) dlg.showModal();
    if (input) input.focus();
  }
  function runOption(pal, opt) {
    if (!opt) return;
    if (pal.tagName === "DIALOG" && pal.open) pal.close();
    if (opt.hasAttribute("data-sb-theme-choice")) applyTheme(opt.getAttribute("data-sb-theme-choice"));
    var target = document.getElementById(opt.getAttribute("data-sb-palette-click") || "");
    if (target) target.click();
    opt.dispatchEvent(new CustomEvent("sb-command", { bubbles: true, detail: { command: opt.getAttribute("data-sb-command") || "", option: opt } }));
    syncChecks(pal);
  }
  function paletteKey(event, pal) {
    var list = paletteOptions(pal).filter(function (o) { return !o.hidden; });
    var cur = list.filter(function (o) { return o.getAttribute("aria-selected") === "true"; })[0];
    var i = list.indexOf(cur);
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      if (!list.length) return;
      var step = event.key === "ArrowDown" ? 1 : -1;
      activate(pal, list[(i + step + list.length) % list.length]);
      event.preventDefault();
    } else if (event.key === "Enter") {
      runOption(pal, cur);
      event.preventDefault();
    }
  }

  // ------------------------------------------------------------------ events
  document.addEventListener("click", function (event) {
    var opener = closestIn(event, "[data-sb-palette-open]");
    if (opener) {
      var id = opener.getAttribute("data-sb-palette-open");
      openPalette(id ? document.getElementById(id) : document.querySelector("dialog.sb-command-palette"), opener);
      return;
    }
    var palOpt = closestIn(event, ".sb-command-palette [role='option']");
    if (palOpt) { runOption(palOpt.closest(".sb-command-palette"), palOpt); return; }
    var toggle = closestIn(event, "[data-sb-window-toggle][aria-controls]");
    if (toggle) {
      var s = paneState(toggle.getAttribute("aria-controls"));
      if (s) { s.overlay = isOverlay(s.pane); setPane(s, s.pane.hidden, "user"); }
      return;
    }
    var opt = closestIn(event, ".sb-listbox [role='option']");
    if (opt) { listClick(event, opt.closest("[role='listbox']"), opt); return; }
    var theme = closestIn(event, "[data-sb-theme-choice]");
    if (theme) applyTheme(theme.getAttribute("data-sb-theme-choice"));
  });
  // Shift / ⌘ + click must not select text in a list
  document.addEventListener("mousedown", function (event) {
    if ((event.shiftKey || modKey(event)) && closestIn(event, ".sb-listbox[aria-multiselectable='true'] [role='option']")) event.preventDefault();
  });
  document.addEventListener("pointerdown", function (event) {
    Object.keys(panes).forEach(function (id) {
      var s = panes[id];
      if (!s.overlay || s.pane.hidden || !(event.target instanceof Node)) return;
      if (s.pane.contains(event.target) || s.toggles.some(function (b) { return b.contains(event.target); })) return;
      closeOverlay(s, false);
    });
  });
  document.addEventListener("keydown", function (event) {
    if (event.defaultPrevented || event.isComposing) return;
    // ⌘K / Strg+K opens (or closes) the palette everywhere in the app (D84)
    if ((event.key === "k" || event.key === "K") && modKey(event) && !event.altKey && !event.shiftKey) {
      var dlg = document.querySelector("dialog.sb-command-palette");
      if (dlg) {
        event.preventDefault();
        if (dlg.open) dlg.close(); else openPalette(dlg, document.activeElement);
        return;
      }
    }
    var pal = closestIn(event, ".sb-command-palette");
    if (pal && event.target.matches(".sb-command-palette__search input")) { paletteKey(event, pal); return; }
    var opt = closestIn(event, ".sb-listbox [role='option']");
    if (opt && event.target === opt) { listKey(event, opt.closest("[role='listbox']"), opt); return; }
    if (event.key === "Escape") {
      Object.keys(panes).forEach(function (id) {
        var s = panes[id];
        if (!s.overlay || s.pane.hidden || !(event.target instanceof Node)) return;
        if (s.pane.contains(event.target) || s.toggles.some(function (b) { return b.contains(event.target); })) { closeOverlay(s, true); event.preventDefault(); }
      });
    }
  });
  document.addEventListener("input", function (event) {
    var pal = closestIn(event, ".sb-command-palette");
    if (pal && event.target.matches(".sb-command-palette__search input")) filter(pal, event.target.value);
  });

  function init() {
    renderKeys(document);
    syncTheme();
    document.querySelectorAll(".sb-command-palette").forEach(function (pal) {
      if (pal.tagName === "DIALOG") wirePalette(pal);
      syncChecks(pal);
      if (pal.tagName !== "DIALOG") {
        var active = pal.querySelector("[role='option'][aria-selected='true']"), input = paletteInput(pal);
        if (active && input) input.setAttribute("aria-activedescendant", active.id);
      }
    });
    document.querySelectorAll(".sb-listbox[role='listbox']").forEach(function (lb) {
      var all = options(lb), cur = all.filter(function (o) { return o.getAttribute("aria-current") === "true"; })[0] || chosen(lb)[0] || all[0];
      all.forEach(function (o) { o.tabIndex = o === cur ? 0 : -1; });
      lb._sbAnchor = cur;
      var status = document.getElementById(lb.getAttribute("data-sb-selection-status") || "");
      if (status && !status.hasAttribute("data-sb-text") && !(multi(lb) && chosen(lb).length > 1)) status.setAttribute("data-sb-text", status.textContent);
    });
    document.querySelectorAll(".sb-window").forEach(function (win) {
      relayout(win);
      if (typeof ResizeObserver === "function") new ResizeObserver(function () { relayout(win); }).observe(win);
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
})();
