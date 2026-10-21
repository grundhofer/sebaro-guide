// sb-menu.js: the menu button of spec/02 §4.10 (ARIA menu button pattern, D80 „Skripte für Bedienung“), with
// submenus (spec/02 §4.24, D91 F4b: „Untermenüs mit Pfeiltasten“).
// Classic script (pages open from file://), CSP-safe: no inline handlers, no eval, position only through the CSSOM.
// Progressive enhancement over markup that already works without it, through the Popover API:
//   <button class="sb-icon-button" type="button" aria-label="Mehr" aria-haspopup="menu" aria-expanded="false"
//           popovertarget="m1">…</button>
// (popovertarget already ties the button to the menu for assistive technology; aria-controls is optional and only
// needed on a button without popovertarget, where this script toggles the menu itself. axe cannot decide an
// aria-controls that points into a closed popover and reports it as "needs review".)
//   <ul class="sb-menu" role="menu" id="m1" aria-label="Mehr" popover>
//     <li role="none"><button class="sb-menu__item" type="button" role="menuitem" tabindex="-1">…</button></li> …
// A submenu is the ARIA APG form: the item that opens it and the submenu share one <li role="none">, the item carries
// aria-haspopup="menu", aria-expanded and popovertarget, the submenu is a nested popover named like its item:
//     <li role="none"><button class="sb-menu__item" type="button" role="menuitem" tabindex="-1" aria-haspopup="menu"
//         aria-expanded="false" popovertarget="m1-file">Datei<span class="sb-menu__sub" aria-hidden="true">…</span></button>
//       <ul class="sb-menu" role="menu" id="m1-file" aria-label="Datei" popover>…</ul></li>
// Without this script the browser already opens and closes the menu (click, Escape, click outside). The script adds:
//   - aria-expanded on the button follows the menu; the menu sits under the button, its end on the button's end
//     (above it when there is no room below), and follows on scroll and resize; a submenu stands beside its parent
//     menu at the height of its item, on the side its parent went to (the top menu's submenus: the reading side,
//     else the other side; never over a visible part of a menu further up), over the parent in a narrow window;
//   - opening by click, Enter or Space focuses the first item, ArrowDown the first, ArrowUp the last;
//   - ArrowDown / ArrowUp move through the items of one menu and wrap, Home / End jump, typing letters jumps to the
//     next item that starts with them (typeahead, 500 ms);
//   - on an item with a submenu, Enter, Space, a click and ArrowRight (ArrowLeft right to left) open the submenu on
//     its first item; in a submenu ArrowLeft (ArrowRight right to left) and Escape close it and go back to its item;
//   - Escape closes and returns focus to the button; Tab (focus leaving the menu) closes the menu with all its
//     submenus and lets focus move on; a click outside closes;
//   - choosing an item closes the menu with all its submenus and puts focus back on the button before the item's own
//     click handlers run, so an item that opens a dialog (data-sb-opens, sb-controls.js) hands focus back to the
//     button when it closes.
// Another script may open a menu for a key of its own (sb-window.js: F10 and a lone Alt open the window menu, F4b):
//   button.dispatchEvent(new CustomEvent("sb-menu-open", { bubbles: true, detail: { returnTo: element } }))
// opens on the first item; Escape and a chosen item then give focus back to returnTo instead of the button.
// Disabled items (disabled or aria-disabled="true") are skipped. Motion: the menu enters through the
// .sb-menu:popover-open rule of sebaro.css (an answer to the press, D80); it closes without motion.
// The script writes no words, so it has no message table (D87).
(function () {
  if (typeof HTMLElement.prototype.showPopover !== "function") return;   // the menu stays a static list
  var ITEM = "[role='menuitem'], [role='menuitemcheckbox'], [role='menuitemradio']";
  var TYPEAHEAD_MS = 500;
  var state = new WeakMap();                                              // menu -> { focus, noReturn, focusInside, returnTo, typed, typedAt, side }

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
  function parentMenu(menu) { return menu.parentElement ? menu.parentElement.closest(".sb-menu") : null; }
  function rootOf(menu) { var m = menu, p; while ((p = parentMenu(m))) m = p; return m; }
  function opensSub(item) { return item.getAttribute("aria-haspopup") === "menu" && !!menuOf(item); }
  function s(menu) { var x = state.get(menu); if (!x) { x = { focus: "first", noReturn: false, focusInside: false, returnTo: null, typed: "", typedAt: 0, side: null }; state.set(menu, x); } return x; }
  // the items of this menu, not those of its submenus
  function items(menu) {
    return Array.prototype.filter.call(menu.querySelectorAll(ITEM), function (i) {
      return i.closest(".sb-menu") === menu && !i.disabled && i.getAttribute("aria-disabled") !== "true";
    });
  }
  function focusItem(menu, which) {
    var list = items(menu);
    if (!list.length) return;
    var i = which === "last" ? list.length - 1 : 0;
    list[i].focus();
  }
  function visible(el) { return !!el && el.isConnected && el.getClientRects().length > 0; }
  // where focus goes back to when the menu closes: the element another script named (F10), else the button
  function backTo(menu, button) {
    var x = s(menu), to = x.returnTo && visible(x.returnTo) ? x.returnTo : button;
    return to;
  }
  // closes the menu that holds this one at the top, with every submenu, without the usual focus return
  function closeAll(menu) {
    for (var m = menu; m; m = parentMenu(m)) s(m).noReturn = true;
    var top = rootOf(menu);
    if (top.matches(":popover-open")) top.hidePopover();
    return top;
  }
  function openSub(item, which) {
    var sub = menuOf(item);
    if (!sub) return;
    if (sub.matches(":popover-open")) { focusItem(sub, which); return; }
    s(sub).focus = which;
    item.click();                                                          // popovertarget keeps the native nesting
  }

  // Place the menu under the button with its end on the button's end; above when the room below is too small.
  function place(menu, button, estimate) {
    if (parentMenu(menu)) { placeSub(menu, button, estimate); return; }
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
  // A submenu: beside its parent menu, its first item level with the item that opened it; the two layer lines lie
  // on each other. A submenu of a submenu keeps the direction its parent went (a parent that had to open to the left
  // has all its submenus open to the left too, as the menus of macOS and Windows do) and never turns back; a submenu
  // of the top menu tries the reading side, then the other side. A side counts only when the submenu fits into the
  // window there and covers no visible part of a menu further up. No such side (a narrow window, or the parent's
  // direction runs out of room): over the parent, moved in by 16 px from the item's start, or from its end when the
  // parent went the other way, so every submenu of one parent lies the same way; under its item, or above it when
  // the room below is too small or the menus further up stay readable only there. The item is never covered, unless
  // the window is too short for the submenu either way (then it stays inside the window).
  function placeSub(menu, item, estimate) {
    var parent = parentMenu(menu), p = parent.getBoundingClientRect(), it = item.getBoundingClientRect();
    var edge = 8, inset = 16;
    var vw = document.documentElement.clientWidth, vh = window.innerHeight;
    var cs = getComputedStyle(menu);
    var line = parseFloat(cs.borderTopWidth) || 0, pad = parseFloat(cs.paddingTop) || 0;
    var w = estimate ? (parseFloat(cs.minWidth) || 240) : menu.getBoundingClientRect().width;
    var h = estimate ? items(menu).length * it.height + 2 * (pad + line) : menu.getBoundingClientRect().height;
    var rtl = getComputedStyle(item).direction === "rtl";
    var x = { right: p.right - line, left: p.left - w + line };            // left edge on either side of the parent
    var reading = rtl ? "left" : "right", other = rtl ? "right" : "left";
    var went = s(parent).side;
    var order = went ? [went] : [reading, other];
    var above = [];                                                        // the menus above the parent stay readable
    for (var m = parentMenu(parent); m; m = parentMenu(m)) above.push(m.getBoundingClientRect());
    function clampY(t) { return Math.min(Math.max(edge, t), Math.max(edge, vh - h - edge)); }
    function cut(a, b) {
      return { left: Math.max(a.left, b.left), right: Math.min(a.right, b.right), top: Math.max(a.top, b.top), bottom: Math.min(a.bottom, b.bottom) };
    }
    function area(r) { return Math.max(0, r.right - r.left) * Math.max(0, r.bottom - r.top); }
    function covers(left, top) {                                           // what the parent already covers does not count
      var box = { left: left, right: left + w, top: top, bottom: top + h };
      return above.some(function (r) {
        var seen = cut(box, { left: r.left + line, right: r.right - line, top: r.top + line, bottom: r.bottom - line });
        return area(seen) - area(cut(seen, p)) > 0;
      });
    }
    var top = clampY(it.top - pad - line), left, side = null;
    for (var k = 0; k < order.length && side === null; k++) {
      var at = x[order[k]];
      if (at >= edge && at + w <= vw - edge && !covers(at, top)) { side = order[k]; left = at; }
    }
    if (side === null) {
      var toward = went || reading;                                        // the fallback leans the way the parent went
      left = Math.min(Math.max(edge, toward === "right" ? it.left + inset : it.right - inset - w), Math.max(edge, vw - w - edge));
      var fit = [it.bottom, it.top - h].filter(function (t) { return t >= edge && t + h <= vh - edge; });
      var free = fit.filter(function (t) { return !covers(left, t); });  // under the item, else above it, whichever
      top = free.length ? free[0] : fit.length ? fit[0] : clampY(it.bottom);  // keeps the menus further up readable
    }
    s(menu).side = side;
    left = Math.min(Math.max(edge, left), Math.max(edge, vw - w - edge));
    menu.style.right = ""; menu.style.bottom = "";
    menu.style.left = Math.round(left) + "px";
    menu.style.top = Math.round(top) + "px";
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
    // focus was in the menu (Escape, ArrowLeft in a submenu): back to the button, unless focus has gone elsewhere
    // meanwhile (a click outside on something that takes focus) or the button itself went away with a parent menu
    var a = document.activeElement;
    var lost = !a || a === document.body || menu.contains(a) || a === button;
    if (x.focusInside && button && lost) {
      var to = backTo(menu, button);
      if (visible(to)) to.focus({ preventScroll: true });
    }
    x.focusInside = false; x.noReturn = false; x.returnTo = null;
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

  // Another script opens a menu for its own key (sb-window.js: F10, a lone Alt) and names where focus goes back to.
  document.addEventListener("sb-menu-open", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[aria-haspopup='menu']") : null;
    var menu = button && menuOf(button);
    if (!menu) return;
    var x = s(menu), to = event.detail && event.detail.returnTo;
    x.returnTo = to instanceof Element && to !== document.body ? to : null;
    if (menu.matches(":popover-open")) { focusItem(menu, "first"); return; }
    x.focus = "first";
    if (button.hasAttribute("popovertarget")) button.click();                // keeps the native invoker link
    else { try { menu.showPopover({ source: button }); } catch (e) { menu.showPopover(); } }
  });

  // Choosing an item: close the whole menu and give focus back first (capture phase, before the item's own handlers).
  // An item with a submenu is not a choice: its press opens the submenu (popovertarget).
  document.addEventListener("click", function (event) {
    var item = event.target instanceof Element ? event.target.closest(".sb-menu " + ITEM) : null;
    if (!item || opensSub(item)) return;
    var menu = item.closest(".sb-menu");
    if (!menu.matches(":popover-open")) return;
    var top = rootOf(menu), button = buttonOf(top), to = button && backTo(top, button);
    closeAll(menu);
    s(top).returnTo = null;
    if (to && visible(to)) to.focus({ preventScroll: true });
  }, true);

  document.addEventListener("keydown", function (event) {
    if (!(event.target instanceof Element)) return;
    var button = event.target.closest("[aria-haspopup='menu']");
    if (button && !button.closest(".sb-menu") && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
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
    var rtl = getComputedStyle(menu).direction === "rtl";
    var inward = rtl ? "ArrowLeft" : "ArrowRight", outward = rtl ? "ArrowRight" : "ArrowLeft";
    switch (event.key) {
      case "ArrowDown": next = at < 0 || at === list.length - 1 ? 0 : at + 1; break;
      case "ArrowUp": next = at <= 0 ? list.length - 1 : at - 1; break;
      case "Home": case "PageUp": next = 0; break;
      case "End": case "PageDown": next = list.length - 1; break;
      case inward:
        if (at >= 0 && opensSub(list[at])) { event.preventDefault(); openSub(list[at], "first"); }
        return;
      case outward:
        var item = parentMenu(menu) && buttonOf(menu);
        if (!item) return;
        event.preventDefault();
        s(menu).noReturn = true;
        menu.hidePopover();
        item.focus({ preventScroll: true });
        return;
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

  // Tab (or any other way focus leaves the open menu) closes it with all its submenus and lets focus go where it went.
  document.addEventListener("focusout", function (event) {
    var menu = event.target instanceof Element ? event.target.closest(".sb-menu") : null;
    if (!menu || !menu.matches(":popover-open")) return;
    var top = rootOf(menu), to = event.relatedTarget;
    if (to instanceof Node && (top.contains(to) || to === buttonOf(top))) return;   // a press on the button toggles it
    closeAll(menu);
  });

  function follow() {
    document.querySelectorAll(".sb-menu:popover-open").forEach(function (menu) { var b = buttonOf(menu); if (b) place(menu, b, false); });
  }
  window.addEventListener("resize", follow);
  window.addEventListener("scroll", follow, { passive: true, capture: true });
})();
