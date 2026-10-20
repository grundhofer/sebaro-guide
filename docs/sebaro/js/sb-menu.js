// sb-menu.js: the menu button of spec/02 §4.10 (ARIA menu button pattern, D80 „Skripte für Bedienung“).
// Classic script (pages open from file://), CSP-safe: no inline handlers, no eval, position only through the CSSOM.
// Progressive enhancement over markup that already works without it, through the Popover API:
//   <button class="sb-icon-button" type="button" aria-label="Mehr" aria-haspopup="menu" aria-expanded="false"
//           popovertarget="m1">…</button>
// (popovertarget already ties the button to the menu for assistive technology; aria-controls is optional and only
// needed on a button without popovertarget, where this script toggles the menu itself. axe cannot decide an
// aria-controls that points into a closed popover and reports it as "needs review".)
//   <ul class="sb-menu" role="menu" id="m1" aria-label="Mehr" popover>
//     <li role="none"><button class="sb-menu__item" type="button" role="menuitem" tabindex="-1">…</button></li> …
// Without this script the browser already opens and closes the menu (click, Escape, click outside). The script adds:
//   - aria-expanded on the button follows the menu; the menu sits under the button, its end on the button's end
//     (above it when there is no room below), and follows on scroll and resize;
//   - opening by click, Enter or Space focuses the first item, ArrowDown the first, ArrowUp the last;
//   - ArrowDown / ArrowUp move through the items and wrap, Home / End jump, typing letters jumps to the next item that
//     starts with them (typeahead, 500 ms);
//   - Escape closes and returns focus to the button; Tab (focus leaving the menu) closes and lets focus move on;
//     a click outside closes;
//   - choosing an item closes the menu and puts focus back on the button before the item's own click handlers run,
//     so an item that opens a dialog (data-sb-opens, sb-controls.js) hands focus back to the button when it closes.
// Disabled items (disabled or aria-disabled="true") are skipped. Motion: the menu enters through the
// .sb-menu:popover-open rule of sebaro.css (an answer to the press, D80); it closes without motion.
// The script writes no words, so it has no message table (D87).
(function () {
  if (typeof HTMLElement.prototype.showPopover !== "function") return;   // the menu stays a static list
  var ITEM = "[role='menuitem'], [role='menuitemcheckbox'], [role='menuitemradio']";
  var TYPEAHEAD_MS = 500;
  var state = new WeakMap();                                              // menu -> { focus, noReturn, focusInside, typed, typedAt }

  function menuOf(button) {
    var id = button.getAttribute("aria-controls") || button.getAttribute("popovertarget");
    var menu = id ? document.getElementById(id) : null;
    return menu && menu.classList.contains("sb-menu") ? menu : null;
  }
  function buttonOf(menu) {
    if (!menu.id) return null;
    var id = CSS.escape(menu.id);
    return document.querySelector("[aria-haspopup='menu'][aria-controls='" + id + "'], [aria-haspopup='menu'][popovertarget='" + id + "']");
  }
  function s(menu) { var x = state.get(menu); if (!x) { x = { focus: "first", noReturn: false, focusInside: false, typed: "", typedAt: 0 }; state.set(menu, x); } return x; }
  function items(menu) {
    return Array.prototype.filter.call(menu.querySelectorAll(ITEM), function (i) { return !i.disabled && i.getAttribute("aria-disabled") !== "true"; });
  }
  function focusItem(menu, which) {
    var list = items(menu);
    if (!list.length) return;
    var i = which === "last" ? list.length - 1 : 0;
    list[i].focus();
  }

  // Place the menu under the button with its end on the button's end; above when the room below is too small.
  function place(menu, button, estimate) {
    var b = button.getBoundingClientRect();
    var gap = 4, edge = 8;
    var vw = document.documentElement.clientWidth, vh = window.innerHeight;
    var h = estimate ? items(menu).length * 48 + 16 : menu.getBoundingClientRect().height;
    var w = estimate ? 0 : menu.getBoundingClientRect().width;
    var rtl = getComputedStyle(button).direction === "rtl";
    var below = vh - b.bottom - gap - edge, above = b.top - gap - edge;
    menu.style.top = ""; menu.style.bottom = ""; menu.style.left = ""; menu.style.right = "";
    if (h <= below || below >= above) menu.style.top = Math.round(b.bottom + gap) + "px";
    else menu.style.bottom = Math.round(vh - b.top + gap) + "px";
    var start = rtl ? b.left : b.right - w;                                // the menu's left edge
    if (estimate) {
      if (rtl) menu.style.left = Math.round(Math.max(edge, b.left)) + "px";
      else menu.style.right = Math.round(Math.max(edge, vw - b.right)) + "px";
      return;
    }
    menu.style.left = Math.round(Math.min(Math.max(edge, start), Math.max(edge, vw - w - edge))) + "px";
  }

  // The browser shows and hides the popover (popovertarget, Escape, click outside); these two events keep the rest in step.
  document.addEventListener("beforetoggle", function (event) {
    var menu = event.target;
    if (!(menu instanceof Element) || !menu.classList.contains("sb-menu")) return;
    var button = buttonOf(menu);
    if (event.newState === "open") { if (button) place(menu, button, true); return; }
    var x = s(menu);
    x.focusInside = !x.noReturn && menu.contains(document.activeElement);
  }, true);
  document.addEventListener("toggle", function (event) {
    var menu = event.target;
    if (!(menu instanceof Element) || !menu.classList.contains("sb-menu")) return;
    var button = buttonOf(menu), x = s(menu);
    var open = event.newState === "open";
    if (button) button.setAttribute("aria-expanded", String(open));
    if (open) {
      items(menu).forEach(function (i) { i.tabIndex = -1; });
      if (button) place(menu, button, false);
      focusItem(menu, x.focus);
      x.focus = "first"; x.noReturn = false;
      return;
    }
    if (x.focusInside && button) button.focus({ preventScroll: true });
    x.focusInside = false; x.noReturn = false;
  }, true);

  // A button without popovertarget: the script toggles the menu itself, naming the button as the source so that a
  // press on it is not also a click outside (where the browser cannot take a source, the state before the press counts).
  var openAtPress = new WeakMap();
  document.addEventListener("pointerdown", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[aria-haspopup='menu']:not([popovertarget])") : null;
    var menu = button && menuOf(button);
    if (menu) openAtPress.set(button, menu.matches(":popover-open"));
  }, true);
  document.addEventListener("click", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[aria-haspopup='menu']") : null;
    if (!button || button.hasAttribute("popovertarget")) return;
    var menu = menuOf(button);
    if (!menu) return;
    var wasOpen = openAtPress.has(button) ? openAtPress.get(button) : menu.matches(":popover-open");
    openAtPress.delete(button);
    if (wasOpen) { if (menu.matches(":popover-open")) menu.hidePopover(); return; }
    if (!menu.matches(":popover-open")) {
      try { menu.showPopover({ source: button }); } catch (e) { menu.showPopover(); }
    }
  });

  // Choosing an item: close and give focus back first (capture phase, before the item's own handlers).
  document.addEventListener("click", function (event) {
    var item = event.target instanceof Element ? event.target.closest(".sb-menu " + ITEM) : null;
    if (!item) return;
    var menu = item.closest(".sb-menu"), button = buttonOf(menu);
    if (!menu.matches(":popover-open")) return;
    s(menu).noReturn = true;
    menu.hidePopover();
    if (button) button.focus({ preventScroll: true });
  }, true);

  document.addEventListener("keydown", function (event) {
    if (!(event.target instanceof Element)) return;
    var button = event.target.closest("[aria-haspopup='menu']");
    if (button && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
      var m = menuOf(button);
      if (!m) return;
      event.preventDefault();
      var which = event.key === "ArrowUp" ? "last" : "first";
      if (m.matches(":popover-open")) { focusItem(m, which); return; }
      s(m).focus = which;
      if (button.hasAttribute("popovertarget")) button.click();                         // keeps the native invoker link
      else { try { m.showPopover({ source: button }); } catch (e) { m.showPopover(); } }
      return;
    }
    var menu = event.target.closest(".sb-menu");
    if (!menu || !menu.matches(":popover-open")) return;
    var list = items(menu), at = list.indexOf(document.activeElement), next = -1;
    switch (event.key) {
      case "ArrowDown": next = at < 0 || at === list.length - 1 ? 0 : at + 1; break;
      case "ArrowUp": next = at <= 0 ? list.length - 1 : at - 1; break;
      case "Home": case "PageUp": next = 0; break;
      case "End": case "PageDown": next = list.length - 1; break;
      default:
        if (event.key.length !== 1 || event.ctrlKey || event.metaKey || event.altKey) return;
        var x = s(menu), now = Date.now();
        x.typed = (now - x.typedAt > TYPEAHEAD_MS ? "" : x.typed) + event.key.toLowerCase();
        x.typedAt = now;
        // one letter, or the same letter again („gg“), moves to the next item with it; a word searches from here
        var same = x.typed.split("").every(function (c) { return c === x.typed[0]; });
        var key = same ? x.typed[0] : x.typed, from = same ? at + 1 : Math.max(at, 0);
        for (var k = 0; k < list.length; k++) {
          var i = (from + k) % list.length;
          if (list[i].textContent.trim().toLowerCase().indexOf(key) === 0) { next = i; break; }
        }
        if (next < 0) return;
    }
    if (next < 0 || !list.length) return;
    event.preventDefault();
    list[next].focus();
  });

  // Tab (or any other way focus leaves the open menu) closes it and lets focus go where it went.
  document.addEventListener("focusout", function (event) {
    var menu = event.target instanceof Element ? event.target.closest(".sb-menu") : null;
    if (!menu || !menu.matches(":popover-open")) return;
    var to = event.relatedTarget;
    if (to instanceof Node && (menu.contains(to) || to === buttonOf(menu))) return;   // a press on the button toggles it
    s(menu).noReturn = true;
    menu.hidePopover();
  });

  function follow() {
    document.querySelectorAll(".sb-menu:popover-open").forEach(function (menu) { var b = buttonOf(menu); if (b) place(menu, b, false); });
  }
  window.addEventListener("resize", follow);
  window.addEventListener("scroll", follow, { passive: true, capture: true });
})();
