// sb-window.js: behaviour of the sebaro desktop window (spec/02 §4.12–§4.24; D67, D72, D75, D81, D84, D91 F1–F14).
// Tauri windows and web apps with a window. Classic script (pages open from file://), CSP-safe: no inline handlers, no
// eval, no style attributes in markup (widths of dragged panes are set through the CSSOM, like sb-menu.js places its
// menu). Progressive enhancement: the markup already carries every state (aria-expanded on the pane toggles,
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
//                                 and in the palette (D75), and as radio inputs in the settings view (F10a); stores
//                                 sb-theme like theme-button.js, read by theme-init.js; keeps aria-checked (checked on
//                                 a radio) on every choice; fires "sb-theme-change" on document
//   .sb-command-palette           dialog.sb-command-palette opens with ⌘K (macOS) / Strg+K (Windows, Linux) and with
//                                 [data-sb-palette-open="<id>"]; typing filters (name, data-sb-keywords, group head),
//                                 ↑ ↓ move the active option, Enter runs it, Escape closes, focus returns (D67 (4),
//                                 D84). Running an option: data-sb-theme-choice is applied, data-sb-palette-click="<id>"
//                                 clicks that control (one code path for the tool and the palette), and "sb-command"
//                                 (bubbles, detail.command = data-sb-command) is fired on the option. Check marks of
//                                 setting options follow their control (aria-expanded / aria-pressed / aria-checked)
//   fixed shortcuts (F5a)         the window shortcuts of spec/02 §4.19 press the visible control of the window that
//                                 announces them in aria-keyshortcuts (⌘, Einstellungen, ⌘N the area's primary
//                                 action, ⌘O, ⌘F (focuses a search field), ⌃⌘S / Strg+Alt+S Seitenleiste, ⌥⌘I /
//                                 Strg+Alt+I Inspektor, ⇧⌘N, ⌘⌫ / Entf (not inside a text field), ⌘+ / ⌘−); ⌘K, F6,
//                                 ⌃⇥ and ⌘W are handled here; undo, redo and the clipboard stay with the text fields
//   F6 / ⇧F6 (F6a)                focus moves through the window's areas: title bar, sidebar, content, inspector,
//                                 action zone; hidden areas are skipped; each area gets back the element that had
//                                 focus there last (else its first control, else the area itself)
//   .sb-window__divider (F3a)     role="separator" between sidebar / inspector and content: drag with limits
//                                 (aria-valuemin / -max; the content keeps 480 px), ← → 8 px, ⇧ + arrow 32 px,
//                                 Home / End smallest / largest, Enter collapses and restores, double click restores
//                                 the start width; dragging under the smallest width collapses; widths are stored per
//                                 window (sb-pane:<window id>:<pane id>) and give way when the window narrows
//   [data-sb-pane-width]          the way without dragging (WCAG 2.5.7): „Schmal · Normal · Breit“ in the menu
//                                 „Darstellung“ (menuitemradio, aria-controls = the pane; "min" | "start" | "max")
//                                 set the width through the divider of that pane, store it like a drag and keep
//                                 aria-checked on the width that is shown (none while a dragged width is between)
//   F10, a lone Alt (F4b)         open the window menu behind „Menü“ (.sb-menu--window) on its first item, like a
//                                 menu bar; again (or Escape) closes it and focus goes back to where it was. Alt
//                                 only off macOS (on a Mac ⌥ types characters); not while a dialog has the keyboard
//   .sb-doc-tabs (F7a)            document tabs: click or ← → Home End choose, ⌃⇥ / ⌃⇧⇥ next / previous, Entf or ⌘W
//                                 / Strg+W close the tab (the cross is a pointer shortcut, aria-hidden), middle click
//                                 closes; "sb-doc-tab-close" (cancelable) is fired on the tab before it goes
//   [data-sb-drag] rows (F8a)     drag with the pointer (pointer events, not HTML drag and drop: Tauri's file drop
//                                 would swallow it on Windows): the dragged row keeps an ink frame, a folder target
//                                 gets the cobalt frame, between rows a cobalt line; [data-sb-drop="none"] refuses
//                                 (no frame, the forbidden cursor); Escape cancels. "sb-move" (cancelable) is fired
//                                 on the row; by default the row moves in the tree. The same move runs from
//                                 dialog[data-sb-move-dialog] („Verschieben nach …“, the way without a pointer)
//   [data-sb-escape]              Escape in the window (when nothing else took it) presses this control, e.g.
//                                 „Zurück zu Wochenplan“ in the settings view (F10a)
//   html[data-sb-window-active]   "false" while the window is not in front (the path recedes, F9a)
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
      width: "{n} Pixel",
      collapsed: "zugeklappt",
      moved: "Nach „{target}“ verschoben.",
      // visible key words off macOS, spoken names (screen readers); macOS shows the font's key glyphs (D68)
      keyWords: { Mod: "Strg", Ctrl: "Strg", Shift: "Umschalt", Alt: "Alt", Enter: "Eingabe", Escape: "Esc", Backspace: "Rücktaste", Delete: "Entf", Tab: "Tab", Space: "Leertaste" },
      keySpoken: { Mod: "Befehl", Ctrl: "Control", Shift: "Umschalt", Alt: "Wahl", Enter: "Eingabe", Escape: "Escape", Backspace: "Rückschritt", Delete: "Entfernen", Tab: "Tabulator", Space: "Leertaste", Up: "Pfeil nach oben", Down: "Pfeil nach unten", Left: "Pfeil nach links", Right: "Pfeil nach rechts", Comma: "Komma", Period: "Punkt", Plus: "Plus", Minus: "Minus", Backslash: "Backslash", Slash: "Schrägstrich" },
      keySpokenOther: { Mod: "Steuerung", Ctrl: "Steuerung", Alt: "Alt" }
    },
    en: {
      selected: "{n} selected",
      noMatch: "No command matches “{q}”.",
      width: "{n} pixels",
      collapsed: "collapsed",
      moved: "Moved to “{target}”.",
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
  // chords whose Windows / Linux form is not the macOS form with Strg for ⌘ (spec/02 §4.19): ⌘⌫ is Entf, ⇧⌘Z is Strg+Y
  var OTHER_KEYS = { "Mod+Backspace": "Delete", "Shift+Mod+Z": "Mod+Y" };
  var OTHER_ARIA = { "Meta+Backspace": "Delete", "Shift+Meta+Z": "Control+Y Control+Shift+Z" };
  // aria-keyshortcuts: the markup carries the macOS chord; elsewhere Meta becomes Control, ⌃⌘ becomes Control+Alt
  function otherAria(list) {
    return list.trim().split(/\s+/).map(function (chord) {
      if (OTHER_ARIA[chord]) return OTHER_ARIA[chord];
      var parts = chord.split("+");
      if (parts.indexOf("Meta") < 0) return chord;
      var hadCtrl = parts.indexOf("Control") >= 0, key = parts[parts.length - 1];
      var mods = parts.slice(0, -1).filter(function (p) { return p !== "Meta" && p !== "Control"; });
      if (hadCtrl && mods.indexOf("Alt") < 0) mods.unshift("Alt");
      return ["Control"].concat(mods).concat([key]).join("+");
    }).join(" ");
  }
  // "Shift+Mod+P" → one chord; "Up Down" → two keys shown side by side („↑↓“)
  function keyText(spec, el) {
    var m = table(el).m, mac = isMac();
    var words = m.keyWords || MESSAGES.de.keyWords, spoken = m.keySpoken || MESSAGES.de.keySpoken;
    var spokenOther = m.keySpokenOther || MESSAGES.de.keySpokenOther;
    var shown = [], said = [];
    spec.trim().split(/\s+/).forEach(function (chord) {
      if (!mac && OTHER_KEYS[chord]) chord = OTHER_KEYS[chord];
      var parts = chord.split("+").filter(Boolean);
      // off macOS ⌃⌘ becomes Strg+Alt (⌃⌘S → Strg+Alt+S): Strg already stands for ⌘ there (spec/02 §4.19)
      if (!mac && parts.indexOf("Mod") >= 0 && parts.indexOf("Ctrl") >= 0) parts = parts.map(function (p) { return p === "Ctrl" ? "Alt" : p; });
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
        el.setAttribute("aria-keyshortcuts", otherAria(el.getAttribute("aria-keyshortcuts")));
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
    updateDividers(s.pane);   // F3a: the dividers say „zugeklappt“ or the width, the open panes share the room again
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
      var on = el.getAttribute("data-sb-theme-choice") === c;
      if (el.tagName === "INPUT") el.checked = on;   // the radios of the settings view (F10a) carry no aria-checked
      else el.setAttribute("aria-checked", String(on));
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

  // ------------------------------------------------------------------ the window and its areas (F6a, F9a, F10a)
  function shown(el) { return !!el && !el.hidden && el.getClientRects().length > 0; }
  function windowOf(el) {
    var win = el instanceof Element ? el.closest(".sb-window") : null;
    if (win) return win;
    var fill = document.querySelectorAll(".sb-window--fill");   // focus on the page itself: the product's one window
    return fill.length === 1 ? fill[0] : null;
  }
  function isTextField(el) {
    return el instanceof Element && (el.isContentEditable ||
      el.matches("input:not([type='checkbox']):not([type='radio']):not([type='button']):not([type='submit']):not([type='range']), textarea, select"));
  }
  var AREA = ".sb-window__titlebar, .sb-window__sidebar, .sb-window__content, .sb-window__inspector, .sb-window > .sb-bottom-block";
  var TABBABLE = "a[href], button:not([disabled]), input:not([disabled]):not([type='hidden']), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])";
  function areas(win) {
    var list = [win.querySelector(":scope > .sb-window__titlebar")];
    var body = win.querySelector(":scope > .sb-window__body");
    if (body) list = list.concat(Array.prototype.slice.call(body.querySelectorAll(":scope > .sb-window__sidebar, :scope > .sb-window__content, :scope > .sb-window__inspector")));
    list.push(win.querySelector(":scope > .sb-bottom-block"));
    return list.filter(shown);
  }
  function firstTabbable(area) {
    var all = area.querySelectorAll(TABBABLE);
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      if (!shown(el)) continue;
      if (el.type === "radio" && !el.checked && el.name && el.form !== undefined) {   // a radio group is entered on its chosen radio
        var group = (el.form || document).querySelectorAll("input[type='radio'][name='" + CSS.escape(el.name) + "']");
        if (Array.prototype.some.call(group, function (r) { return r.checked; })) continue;
      }
      return el;
    }
    return null;
  }
  // F6 / ⇧F6: area by area, back to where focus was in each (spec/02 §4.20)
  function moveArea(win, back) {
    var list = areas(win);
    if (!list.length) return;
    var at = -1;
    list.forEach(function (a, i) { if (a.contains(document.activeElement)) at = i; });
    var next = list[at < 0 ? (back ? list.length - 1 : 0) : (at + (back ? -1 : 1) + list.length) % list.length];
    var target = next._sbLast && next.contains(next._sbLast) && shown(next._sbLast) && next._sbLast.matches(TABBABLE + ", [tabindex='-1']") ? next._sbLast : firstTabbable(next);
    if (!target) {   // an area with nothing to press (a text): the area itself takes focus and shows the ring
      if (!next.hasAttribute("tabindex")) next.setAttribute("tabindex", "-1");
      target = next;
    }
    target.focus();
  }
  document.addEventListener("focusin", function (event) {
    var el = event.target;
    if (!(el instanceof Element)) return;
    var area = el.closest(AREA);
    if (area && el !== area && !el.closest(".sb-menu[popover], .sb-tooltip")) area._sbLast = el;
  });
  // F9a: a window that is not in front lets its path recede (sebaro.css); the attribute is absent while in front
  window.addEventListener("blur", function () { root.setAttribute("data-sb-window-active", "false"); });
  window.addEventListener("focus", function () { root.removeAttribute("data-sb-window-active"); });

  // ------------------------------------------------------------------ fixed shortcuts (F5a; spec/02 §4.19)
  // The chords the script presses through the control that announces them (aria-keyshortcuts, macOS form in the
  // markup). ⌘K, F6, ⌃⇥ and ⌘W have their own code; ⌘Z, ⇧⌘Z and the clipboard belong to the text fields.
  var PRESSED = ["Meta+,", "Meta+N", "Meta+O", "Meta+F", "Control+Meta+S", "Alt+Meta+I", "Shift+Meta+N", "Meta+Backspace", "Meta+Plus", "Meta+Minus"];
  var KEY_NAMES = { ",": "Comma", "+": "Plus", "=": "Plus", "-": "Minus", "−": "Minus", "Del": "Delete", "Esc": "Escape", " ": "Space", "Spacebar": "Space" };
  var ARIA_MODS = ["Control", "Alt", "Shift", "Meta"];
  function canon(chord) {
    var parts = chord.split("+"), key = parts.pop();
    if (key === "") { key = "+"; parts = parts.filter(Boolean); }   // "Meta++"
    key = KEY_NAMES[key] || (key.length === 1 ? key.toUpperCase() : key);
    var mods = ARIA_MODS.filter(function (m) { return parts.indexOf(m) >= 0; });
    if (key === "Plus" || key === "Minus") mods = mods.filter(function (m) { return m !== "Shift"; });   // „+“ needs ⇧ on some layouts
    return mods.concat([key]).join("+");
  }
  function eventChord(event) {
    var key = event.key;
    // ⌥ on macOS turns letters into other characters (⌥⌘I gives „ˆ“): take the letter from the key's position then
    if (event.altKey && /^Key[A-Z]$/.test(event.code || "") && !/^[a-z]$/i.test(key)) key = event.code.slice(3);
    var mods = [];
    if (event.ctrlKey) mods.push("Control");
    if (event.altKey) mods.push("Alt");
    if (event.shiftKey) mods.push("Shift");
    if (event.metaKey) mods.push("Meta");
    return canon(mods.concat([key]).join("+"));
  }
  function pressFixed(event, win) {
    var chord = eventChord(event), mac = isMac();
    var fixed = PRESSED.some(function (c) { return (mac ? [c] : otherAria(c).split(" ")).some(function (x) { return canon(x) === chord; }); });
    if (!fixed) return false;
    if (isTextField(event.target) && (chord === "Delete" || chord === "Meta+Backspace")) return false;   // the field's own key
    // a tab announces the keys that act on it while it has focus (Entf, ⌘W): those are not window keys
    var found = Array.prototype.filter.call(win.querySelectorAll("[aria-keyshortcuts]:not([role='tab'])"), function (el) {
      return !el.disabled && el.getAttribute("aria-disabled") !== "true" &&
        el.getAttribute("aria-keyshortcuts").trim().split(/\s+/).some(function (x) { return canon(x) === chord; });
    });
    var el = found.filter(shown)[0] || found[0];   // the visible tool first, else the item of the closed „Menü“
    if (!el) return false;
    event.preventDefault();
    if (el.matches("input, textarea")) { el.focus(); if (typeof el.select === "function") el.select(); }
    else el.click();
    return true;
  }

  // ------------------------------------------------------------------ dividers between window parts (F3a, F2a, D81)
  var CONTENT_MIN = 480, STEP = 8, STEP_BIG = 32, COLLAPSE_AT = 48;   // dragging 48 px under the smallest width collapses
  function dividerPane(d) { return document.getElementById(d.getAttribute("aria-controls") || ""); }
  function atEnd(d) { var p = dividerPane(d); return !!p && !!(d.compareDocumentPosition(p) & Node.DOCUMENT_POSITION_FOLLOWING); }
  function attrNum(el, name, fallback) { var v = parseInt(el.getAttribute(name), 10); return isFinite(v) ? v : fallback; }
  function dState(d) {
    if (!d._sb) {
      var min = attrNum(d, "aria-valuemin", 200), max = Math.max(min, attrNum(d, "aria-valuemax", 400));
      var start = Math.min(max, Math.max(min, attrNum(d, "aria-valuenow", min)));
      d._sb = { min: min, max: max, start: start, width: start };
    }
    return d._sb;
  }
  function clampW(s, w) { return Math.round(Math.min(s.max, Math.max(s.min, w))); }
  function storeKey(d) {
    var win = d.closest(".sb-window");
    return "sb-pane:" + ((win && (win.getAttribute("data-sb-window-id") || win.id)) || "") + ":" + d.getAttribute("aria-controls");
  }
  function loadWidth(d) { try { var v = parseInt(localStorage.getItem(storeKey(d)), 10); return isFinite(v) ? v : null; } catch (e) { return null; } }
  function saveWidth(d) { try { localStorage.setItem(storeKey(d), String(dState(d).width)); } catch (e) { /* not stored: the width holds until reload */ } }
  function dividersOf(win) {
    var body = win && win.querySelector(":scope > .sb-window__body");
    return body ? Array.prototype.slice.call(body.querySelectorAll(":scope > .sb-window__divider")) : [];
  }
  function showWidth(d, w) {
    var p = dividerPane(d);
    if (p) p.style.inlineSize = w + "px";
    d.setAttribute("aria-valuenow", String(w));
    d.setAttribute("aria-valuetext", t(d, "width", { n: w }));
    checkWidths(d);
  }
  // „Schmal · Normal · Breit“ (F3a, WCAG 2.5.7): the item of the pane's own width carries the check (the width the
  // user chose, also while the pane gives way to a narrow window); none while a dragged width lies between
  function widthOf(d, which) { var s = dState(d); return which === "min" ? s.min : which === "max" ? s.max : s.start; }
  function checkWidths(d) {
    var id = d.getAttribute("aria-controls"), w = dState(d).width;
    if (!id) return;
    document.querySelectorAll("[data-sb-pane-width][aria-controls='" + CSS.escape(id) + "']").forEach(function (el) {
      el.setAttribute("aria-checked", String(widthOf(d, el.getAttribute("data-sb-pane-width")) === w));
    });
  }
  function dividerFor(paneId) { return paneId ? document.querySelector(".sb-window__divider[aria-controls='" + CSS.escape(paneId) + "']") : null; }
  // The content keeps 480 px: the user's widths hold while they fit; otherwise the end pane (inspector) gives way
  // first, then the start pane (sidebar), each down to its smallest width. Below that the container steps of
  // sebaro.css take the pane out of the row (overlay), so the stored width is never lost.
  function fit(win) {
    var ds = dividersOf(win);
    if (!ds.length) return;
    var body = ds[0].parentElement, room = body.clientWidth - CONTENT_MIN;
    var docked = ds.filter(shown);
    docked.forEach(function (d) { room -= d.offsetWidth; });
    var open = docked.filter(function (d) { var p = dividerPane(d); return p && !p.hidden; });
    var want = open.map(function (d) { return dState(d).width; });
    var total = want.reduce(function (a, b) { return a + b; }, 0);
    open.map(function (d, i) { return i; }).sort(function (a, b) { return atEnd(open[b]) - atEnd(open[a]); }).forEach(function (i) {
      if (total <= room) return;
      var cut = Math.min(want[i] - dState(open[i]).min, total - room);
      want[i] -= cut; total -= cut;
    });
    open.forEach(function (d, i) { showWidth(d, want[i]); });
    ds.forEach(function (d) {
      var p = dividerPane(d);
      if (p && p.hidden) { d.setAttribute("aria-valuenow", String(dState(d).min)); d.setAttribute("aria-valuetext", t(d, "collapsed")); }
      else if (open.indexOf(d) < 0) showWidth(d, dState(d).width);   // an overlay pane keeps the user's width
    });
  }
  function roomFor(d) {   // the widest this pane may be now, beside the content's 480 px and the other docked pane
    var body = d.parentElement, room = body.clientWidth - CONTENT_MIN;
    dividersOf(d.closest(".sb-window")).forEach(function (x) {
      if (!shown(x)) return;
      room -= x.offsetWidth;
      var p = dividerPane(x);
      if (x !== d && p && !p.hidden) room -= p.offsetWidth;
    });
    return room;
  }
  function paneOpen(d, open) {
    var p = dividerPane(d), s = p && paneState(p.id);
    if (s && (p.hidden === open)) { s.overlay = isOverlay(p); setPane(s, open, "user"); }
  }
  function setWidth(d, w, how) {   // how: "drag" may collapse under the smallest width, "key" stops at it
    var s = dState(d), max = Math.min(s.max, roomFor(d));
    if (how === "drag" && w < s.min - COLLAPSE_AT) { paneOpen(d, false); return; }
    if (max < s.min) return;   // no room for this pane beside the content: it stays as it is
    s.width = Math.round(Math.min(max, Math.max(s.min, w)));
    paneOpen(d, true);
    showWidth(d, s.width);
  }
  function dividerKey(event, d) {
    var s = dState(d), p = dividerPane(d);
    if (!p) return false;
    var rtl = getComputedStyle(d).direction === "rtl", grow = (atEnd(d) ? -1 : 1) * (rtl ? -1 : 1);
    var now = p.hidden ? s.min : s.width, step = event.shiftKey ? STEP_BIG : STEP;
    switch (event.key) {
      case "ArrowRight": setWidth(d, now + grow * step, "key"); break;
      case "ArrowLeft": setWidth(d, now - grow * step, "key"); break;
      case "Home": setWidth(d, s.min, "key"); break;
      case "End": setWidth(d, s.max, "key"); break;
      case "Enter": paneOpen(d, p.hidden); break;
      default: return false;
    }
    saveWidth(d);
    event.preventDefault();
    return true;
  }
  var resize = null;   // { d, x, from, sign }
  function startResize(event, d) {
    var p = dividerPane(d);
    if (!p || event.button !== 0) return;
    var rtl = getComputedStyle(d).direction === "rtl";
    resize = { d: d, x: event.clientX, from: p.hidden ? 0 : p.getBoundingClientRect().width, sign: (atEnd(d) ? -1 : 1) * (rtl ? -1 : 1), id: event.pointerId };
    try { d.setPointerCapture(event.pointerId); } catch (e) { /* the move still arrives while the pointer stays on the page */ }
    root.setAttribute("data-sb-dragging", "resize");
    event.preventDefault();
  }
  function endResize() {
    if (!resize) return;
    saveWidth(resize.d);
    resize = null;
    root.removeAttribute("data-sb-dragging");
  }
  function updateDividers(pane) {
    var win = pane && pane.closest(".sb-window");
    if (win && dividersOf(win).length) fit(win);
  }

  // ------------------------------------------------------------------ document tabs (F7a; spec/02 §4.21)
  function docTabs(list) { return Array.prototype.slice.call(list.querySelectorAll("[role='tab']")); }
  function docPanel(tab) { return document.getElementById(tab.getAttribute("aria-controls") || ""); }
  function selectDocTab(tab, focus) {
    var list = tab.closest("[role='tablist']"), before = document.activeElement, oldPanel = null;
    docTabs(list).forEach(function (x) {
      var on = x === tab, p = docPanel(x);
      if (x.getAttribute("aria-selected") === "true" && p && p.contains(before)) oldPanel = p;
      x.setAttribute("aria-selected", String(on));
      x.tabIndex = on ? 0 : -1;
      if (p) p.hidden = !on;
    });
    if (focus === "tab") tab.focus();
    else if (oldPanel) { var p = docPanel(tab); if (p) p.focus(); }   // ⌃⇥ from inside the text: stay in the text
  }
  function currentDocTab(win) {
    var list = Array.prototype.filter.call(win.querySelectorAll(".sb-doc-tabs[role='tablist']"), shown)[0];
    return list ? list.querySelector("[role='tab'][aria-selected='true']") : null;
  }
  function cycleDocTab(win, step) {
    var cur = currentDocTab(win);
    if (!cur) return false;
    var all = docTabs(cur.closest("[role='tablist']")), i = all.indexOf(cur);
    selectDocTab(all[(i + step + all.length) % all.length], document.activeElement === cur ? "tab" : "panel");
    return true;
  }
  function closeDocTab(tab) {
    var list = tab.closest("[role='tablist']");
    if (!tab.dispatchEvent(new CustomEvent("sb-doc-tab-close", { bubbles: true, cancelable: true, detail: { tab: tab } }))) return;
    var all = docTabs(list), i = all.indexOf(tab), next = all[i + 1] || all[i - 1] || null;
    var panel = docPanel(tab), active = document.activeElement;
    var focusHere = tab === active || (panel && panel.contains(active)) || (tab.closest(".sb-doc-tabs__item") || tab).contains(active);
    var wasSelected = tab.getAttribute("aria-selected") === "true";
    (tab.closest(".sb-doc-tabs__item") || tab).remove();
    if (panel && !list.querySelector("[aria-controls='" + CSS.escape(panel.id) + "']")) panel.remove();
    if (next) {
      if (wasSelected) selectDocTab(next, focusHere ? "tab" : null);
      else if (focusHere) next.focus();
      return;
    }
    list.hidden = true;   // an empty tab list is no tab list: the sentence after it says that nothing is open
    var none = list.parentElement && list.parentElement.querySelector(":scope > .sb-doc-tabs__none");
    if (none) { none.hidden = false; if (focusHere) { none.tabIndex = -1; none.focus(); } }
  }
  function docTabKey(event, tab) {
    var all = docTabs(tab.closest("[role='tablist']")), i = all.indexOf(tab);
    var rtl = getComputedStyle(tab).direction === "rtl", next = null;
    switch (event.key) {
      case "ArrowRight": next = all[(i + (rtl ? -1 : 1) + all.length) % all.length]; break;
      case "ArrowLeft": next = all[(i + (rtl ? 1 : -1) + all.length) % all.length]; break;
      case "Home": next = all[0]; break;
      case "End": next = all[all.length - 1]; break;
      case "Delete": closeDocTab(tab); event.preventDefault(); return true;
      default: return false;
    }
    selectDocTab(next, "tab");
    event.preventDefault();
    return true;
  }

  // ------------------------------------------------------------------ drag and drop of rows (F8a; spec/02 §4.22)
  var DRAG_START = 4, dnd = null, swallowClick = false;   // dnd: { row, x, y, id, on, hit }
  function setState(el, value) {   // data-sb-state holds other states too („done“): keep and give back what was there
    if (value) { if (!("_sbState" in el)) el._sbState = el.getAttribute("data-sb-state"); el.setAttribute("data-sb-state", value); }
    else if ("_sbState" in el) { if (el._sbState == null) el.removeAttribute("data-sb-state"); else el.setAttribute("data-sb-state", el._sbState); delete el._sbState; }
  }
  function container(row) { return row.closest("[role='tree'], [role='listbox']"); }
  function dropAt(x, y) {
    var el = document.elementFromPoint(x, y), row = el && el.closest("[role='treeitem'], [role='option']");
    if (!row || row === dnd.row || container(row) !== container(dnd.row)) return null;
    var item = dnd.row.closest("li");
    if (item && item !== dnd.row && item.contains(row)) return null;   // never into itself
    if (row.getAttribute("data-sb-drop") === "none") return { row: row, pos: "refuse" };
    var r = row.getBoundingClientRect(), into = row.hasAttribute("aria-owns") || row.getAttribute("data-sb-drop") === "into";
    if (into && y > r.top + r.height / 4 && y < r.bottom - r.height / 4) return { row: row, pos: "into" };
    return { row: row, pos: y < r.top + r.height / 2 ? "before" : "after" };
  }
  function markDrop(hit) {
    if (dnd.hit && (!hit || hit.row !== dnd.hit.row || hit.pos !== dnd.hit.pos)) setState(dnd.hit.row, null);
    dnd.hit = hit;
    if (hit) setState(hit.row, "drop-" + hit.pos);
    root.setAttribute("data-sb-dragging", hit && hit.pos === "refuse" ? "refuse" : "move");
  }
  function endDnd() {
    if (!dnd) return;
    if (dnd.hit) setState(dnd.hit.row, null);
    if (dnd.on) setState(dnd.row, null);
    root.removeAttribute("data-sb-dragging");
    dnd = null;
  }
  function levelOf(ul) {
    if (ul.getAttribute("role") !== "group") return 1;
    var owner = (ul.id && ul.closest("[role='tree']").querySelector("[aria-owns~='" + CSS.escape(ul.id) + "']")) || ul.previousElementSibling;
    return owner ? (parseInt(owner.getAttribute("aria-level"), 10) || 1) + 1 : 1;
  }
  function relevel(item) {
    var row = item.matches("[aria-level]") ? item : item.querySelector(":scope > [aria-level]");
    if (row) row.setAttribute("aria-level", String(levelOf(item.parentElement)));
    item.querySelectorAll(":scope > [role='group'] > li").forEach(relevel);
  }
  function rowName(row) { var n = row.querySelector(".sb-row__name"); return (n ? n.textContent : row.textContent).trim(); }
  function groupOf(folder) { return document.getElementById(folder.getAttribute("aria-owns") || "") || (folder.closest("li") || folder).querySelector(":scope > [role='group']"); }
  // one code path for the pointer and for „Verschieben nach …“ (D67 (6): every drag has a way without a pointer)
  function moveRow(row, target, pos, undo) {
    var item = row.closest("li"), at = target.closest("li");
    if (!item || !at) return;
    var group = pos === "into" ? groupOf(target) : null;
    if (pos === "into" && (!group || group === item.parentElement)) return;   // already there
    if (!undo && !row.dispatchEvent(new CustomEvent("sb-move", { bubbles: true, cancelable: true, detail: { item: row, target: target, position: pos } }))) return;
    var back = { parent: item.parentElement, next: item.nextElementSibling };
    var had = document.activeElement === row;
    if (pos === "into") group.appendChild(item);
    else at.parentElement.insertBefore(item, pos === "before" ? at : at.nextElementSibling);
    relevel(item);
    if (shown(row)) { if (had) row.focus(); return; }
    // the row went into a closed folder: the folder becomes the tree's stop and a toast says where it went (D78)
    var folder = pos === "into" ? target : null;
    if (row.tabIndex === 0 && folder) { row.tabIndex = -1; folder.tabIndex = 0; }
    if (had && folder) folder.focus();
    var win = row.closest(".sb-window"), toast = win && win.querySelector(".sb-toast[data-sb-move-toast]");
    if (toast && folder && !undo && window.sbToast) {
      var line = toast.querySelector("p");
      if (line) line.textContent = t(toast, "moved", { target: rowName(folder) });
      toast._sbUndo = function () {
        back.parent.insertBefore(item, back.next && back.next.parentElement === back.parent ? back.next : null);
        relevel(item);
        row.dispatchEvent(new CustomEvent("sb-move", { bubbles: true, detail: { item: row, target: null, position: "back", undo: true } }));
      };
      window.sbToast.show(toast);
    }
  }
  document.addEventListener("sb-toast-action", function (event) {
    var toast = event.target;
    if (toast instanceof Element && typeof toast._sbUndo === "function") { toast._sbUndo(); toast._sbUndo = null; }
  });
  document.addEventListener("close", function (event) {   // dialog[data-sb-move-dialog="<tree id>"], value „move“
    var dlg = event.target;
    if (!(dlg instanceof Element) || !dlg.hasAttribute("data-sb-move-dialog") || dlg.returnValue !== "move") return;
    var tree = document.getElementById(dlg.getAttribute("data-sb-move-dialog"));
    var choice = dlg.querySelector("input[type='radio']:checked"), target = choice && document.getElementById(choice.value);
    var row = tree && (tree.querySelector("[aria-selected='true']") || tree.querySelector("[tabindex='0']"));
    if (row && target && row !== target) moveRow(row, target, "into");
  }, true);

  // ------------------------------------------------------------------ events
  // the click that ends a drag is not a click on the row (capture: before sb-tree.js and the listbox choose it)
  document.addEventListener("click", function (event) {
    if (swallowClick) { swallowClick = false; event.preventDefault(); event.stopPropagation(); }
  }, true);
  document.addEventListener("click", function (event) {
    var close = closestIn(event, ".sb-doc-tabs__close");
    if (close) {
      var owner = close.closest(".sb-doc-tabs__item"), tabToClose = owner && owner.querySelector("[role='tab']");
      if (tabToClose) closeDocTab(tabToClose);
      return;
    }
    var docTab = closestIn(event, ".sb-doc-tabs [role='tab']");
    if (docTab) { selectDocTab(docTab, null); return; }
    var area = closestIn(event, "[data-sb-area]");   // „Nächster Bereich“ / „Vorheriger Bereich“ in the menu „Fenster“
    if (area) {
      var areaWin = windowOf(area);
      if (areaWin) moveArea(areaWin, area.getAttribute("data-sb-area") === "previous");
      return;
    }
    var opener = closestIn(event, "[data-sb-palette-open]");
    if (opener) {
      var id = opener.getAttribute("data-sb-palette-open");
      openPalette(id ? document.getElementById(id) : document.querySelector("dialog.sb-command-palette"), opener);
      return;
    }
    var palOpt = closestIn(event, ".sb-command-palette [role='option']");
    if (palOpt) { runOption(palOpt.closest(".sb-command-palette"), palOpt); return; }
    var paneWidth = closestIn(event, "[data-sb-pane-width][aria-controls]");
    if (paneWidth) {   // „Schmal · Normal · Breit“: the same width code as the keyboard on the divider
      var pd = dividerFor(paneWidth.getAttribute("aria-controls"));
      if (pd) {   // the chosen width is the pane's width from now on; fit() shows what the window has room for
        var ps = dState(pd);
        ps.width = clampW(ps, widthOf(pd, paneWidth.getAttribute("data-sb-pane-width")));
        saveWidth(pd);
        paneOpen(pd, true);
        fit(pd.closest(".sb-window"));
        checkWidths(pd);
      }
      return;
    }
    var toggle = closestIn(event, "[data-sb-window-toggle][aria-controls]");
    if (toggle) {
      var s = paneState(toggle.getAttribute("aria-controls"));
      if (s) { s.overlay = isOverlay(s.pane); setPane(s, s.pane.hidden, "user"); }
      return;
    }
    var opt = closestIn(event, ".sb-listbox [role='option']");
    if (opt) { listClick(event, opt.closest("[role='listbox']"), opt); return; }
    var theme = closestIn(event, "[data-sb-theme-choice]");
    if (theme && theme.tagName !== "INPUT") applyTheme(theme.getAttribute("data-sb-theme-choice"));   // radios: "change"
  });
  document.addEventListener("change", function (event) {
    var radio = event.target;
    if (radio instanceof HTMLInputElement && radio.checked && radio.hasAttribute("data-sb-theme-choice")) applyTheme(radio.getAttribute("data-sb-theme-choice"));
  });
  // Shift / ⌘ + click must not select text in a list
  document.addEventListener("mousedown", function (event) {
    if ((event.shiftKey || modKey(event)) && closestIn(event, ".sb-listbox[aria-multiselectable='true'] [role='option']")) event.preventDefault();
    // the cross of a tab keeps focus where it is; the middle button on a tab closes it instead of scrolling
    if (closestIn(event, ".sb-doc-tabs__close") || (event.button === 1 && closestIn(event, ".sb-doc-tabs__item"))) event.preventDefault();
  });
  document.addEventListener("auxclick", function (event) {
    var item = event.button === 1 && closestIn(event, ".sb-doc-tabs__item"), tab = item && item.querySelector("[role='tab']");
    if (tab) { closeDocTab(tab); event.preventDefault(); }
  });
  document.addEventListener("dblclick", function (event) {   // a double click on a divider gives back the start width
    var d = closestIn(event, ".sb-window__divider");
    if (!d) return;
    setWidth(d, dState(d).start, "key");
    saveWidth(d);
  });
  document.addEventListener("pointerdown", function (event) {
    var d = closestIn(event, ".sb-window__divider");
    if (d) { startResize(event, d); return; }
    var row = event.button === 0 && event.isPrimary && !closestIn(event, ".sb-tree__twist") ? closestIn(event, "[data-sb-drag]") : null;
    if (row) dnd = { row: row, x: event.clientX, y: event.clientY, id: event.pointerId, on: false, hit: null };
  });
  document.addEventListener("pointermove", function (event) {
    if (resize && event.pointerId === resize.id) { setWidth(resize.d, resize.from + resize.sign * (event.clientX - resize.x), "drag"); return; }
    if (!dnd || event.pointerId !== dnd.id) return;
    if (!dnd.on) {
      if (Math.abs(event.clientX - dnd.x) + Math.abs(event.clientY - dnd.y) < DRAG_START) return;
      if (!(event.buttons & 1)) { dnd = null; return; }
      dnd.on = true;
      setState(dnd.row, "dragging");
    }
    markDrop(dropAt(event.clientX, event.clientY));
  });
  document.addEventListener("pointerup", function (event) {
    if (resize && event.pointerId === resize.id) { endResize(); return; }
    if (!dnd || event.pointerId !== dnd.id) return;
    var was = dnd.on, row = dnd.row, hit = dnd.hit;
    endDnd();
    if (!was) return;
    swallowClick = true;
    setTimeout(function () { swallowClick = false; }, 0);
    if (hit && hit.pos !== "refuse") moveRow(row, hit.row, hit.pos);
  });
  document.addEventListener("pointercancel", function () { endResize(); endDnd(); });
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
    if (dnd && dnd.on) { if (event.key === "Escape") { endDnd(); event.preventDefault(); } return; }   // Escape cancels a drag
    var opt = closestIn(event, ".sb-listbox [role='option']");
    if (opt && event.target === opt) { listKey(event, opt.closest("[role='listbox']"), opt); if (event.defaultPrevented) return; }
    var divider = closestIn(event, ".sb-window__divider");
    if (divider && event.target === divider && dividerKey(event, divider)) return;
    var docTab = closestIn(event, ".sb-doc-tabs [role='tab']");
    if (docTab && event.target === docTab && docTabKey(event, docTab)) return;
    if (event.key === "Escape") {
      Object.keys(panes).forEach(function (id) {
        var s = panes[id];
        if (!s.overlay || s.pane.hidden || !(event.target instanceof Node)) return;
        if (s.pane.contains(event.target) || s.toggles.some(function (b) { return b.contains(event.target); })) { closeOverlay(s, true); event.preventDefault(); }
      });
      if (event.defaultPrevented) return;
    }
    // window keys: not while a dialog, the palette or a menu has the keyboard
    if (event.target instanceof Element && event.target.closest("dialog[open], .sb-menu:popover-open, .sb-toast")) return;
    var win = windowOf(event.target);
    if (!win) return;
    if (event.key === "Escape") {   // „Zurück zu …“ of a view such as the settings (F10a)
      var back = isTextField(event.target) ? null : win.querySelector("[data-sb-escape]");
      if (back && shown(back)) { event.preventDefault(); back.click(); }
      return;
    }
    if (event.key === "F6" && !event.ctrlKey && !event.metaKey && !event.altKey) { event.preventDefault(); moveArea(win, event.shiftKey); return; }
    if (event.key === "Tab" && event.ctrlKey && !event.metaKey && !event.altKey) { if (cycleDocTab(win, event.shiftKey ? -1 : 1)) event.preventDefault(); return; }
    if ((event.key === "w" || event.key === "W") && modKey(event) && !event.shiftKey && !event.altKey) {
      var cur = currentDocTab(win);
      if (cur) { event.preventDefault(); closeDocTab(cur); }
      return;
    }
    pressFixed(event, win);
  });
  // F4b: F10 and a lone Alt (pressed and let go with no other key; Windows and Linux) open the window menu behind
  // „Menü“ like a menu bar, on its first item; pressed again inside the menu they close it. Escape or a chosen item
  // give focus back to where it was (sb-menu.js, "sb-menu-open" with returnTo). AltGr (key "AltGraph") is not Alt.
  function windowMenuToggle(from) {
    if (!(from instanceof Element) || from.closest("dialog[open]")) return false;
    var openMenu = from.closest(".sb-menu--window:popover-open");
    if (openMenu) { openMenu.hidePopover(); return true; }   // sb-menu.js gives focus back
    var win = windowOf(from), menu = win && win.querySelector(".sb-menu--window[popover][id]");
    if (!menu) return false;
    var id = CSS.escape(menu.id);
    var button = document.querySelector("[aria-haspopup='menu'][popovertarget='" + id + "'], [aria-haspopup='menu'][aria-controls='" + id + "']");
    if (!button || !shown(button)) return false;
    var back = document.activeElement && document.activeElement !== document.body ? document.activeElement : null;
    button.dispatchEvent(new CustomEvent("sb-menu-open", { bubbles: true, detail: { returnTo: back } }));
    return true;
  }
  var altAlone = false;
  document.addEventListener("keydown", function (event) {
    if (event.key === "Alt") {
      altAlone = event.repeat ? altAlone : !(event.ctrlKey || event.metaKey || event.shiftKey);
      return;
    }
    altAlone = false;
    if (event.key !== "F10" || event.ctrlKey || event.metaKey || event.altKey || event.shiftKey || event.isComposing) return;
    if (windowMenuToggle(event.target)) event.preventDefault();   // Shift+F10 stays the context menu
  }, true);
  document.addEventListener("keyup", function (event) {
    if (event.key !== "Alt" || !altAlone) return;
    altAlone = false;
    if (isMac() || event.ctrlKey || event.metaKey || event.shiftKey) return;
    if (windowMenuToggle(event.target)) event.preventDefault();
  }, true);
  document.addEventListener("pointerdown", function () { altAlone = false; }, true);
  window.addEventListener("blur", function () { altAlone = false; });

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
    document.querySelectorAll(".sb-window__divider[role='separator']").forEach(function (d) {
      var s = dState(d), stored = loadWidth(d);
      if (stored != null) s.width = clampW(s, stored);
      if (!d.hasAttribute("tabindex")) d.tabIndex = 0;   // without this script the line is only the layer line
    });
    document.querySelectorAll(".sb-doc-tabs[role='tablist']").forEach(function (list) {
      var all = docTabs(list), cur = all.filter(function (x) { return x.getAttribute("aria-selected") === "true"; })[0] || all[0];
      all.forEach(function (x) { x.tabIndex = x === cur ? 0 : -1; });
    });
    document.querySelectorAll(".sb-window").forEach(function (win) {
      relayout(win);
      fit(win);
      if (typeof ResizeObserver === "function") new ResizeObserver(function () { relayout(win); fit(win); }).observe(win);
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
})();
