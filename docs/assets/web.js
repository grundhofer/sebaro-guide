// web.js: behaviour of the example website on web.html (guide page only, never shipped). Classic script, loaded with
// defer, CSP-safe (no inline handlers, no eval), no network. The system scripts (sb-controls.js, sb-notes.js,
// sb-start.js, sb-search.js) do the rest: chips, code copy, dialog, footnote popover, start replay, „Suche leeren“.
//   1) project overview: filter chips, search and the order (segmented) narrow and sort the list; count + empty state
//   2) forms with [data-g-web-send]: the fields are checked first (EIN-02, TXT-07), then the primary action shows its
//      own progress (AKT-05, D48): label says what runs, the ink bar grows, check + done word, then the sent line.
//      No toast. The run is a stand-in for real network work; a product drives the same attributes from its request.
(function () {
  var reduced = function () {
    return document.documentElement.getAttribute("data-sb-motion") === "reduce" ||
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  };

  // 1) project overview
  var list = document.querySelector("[data-g-web-projects]");
  if (list) {
    var rows = Array.prototype.slice.call(list.querySelectorAll(".sb-app-row"));
    var chips = document.querySelector("[data-g-web-project-chips]");
    var search = document.querySelector("[data-g-web-project-search]");
    var count = document.querySelector("[data-g-web-project-count]");
    var empty = document.querySelector("[data-g-web-project-empty]");
    var reset = document.querySelector("[data-g-web-project-reset]");
    var order = document.querySelectorAll("[data-g-web-project-order] input");
    var apply = function () {
      var pressed = chips ? chips.querySelector(".sb-chip[aria-pressed='true']") : null;
      var platform = pressed ? pressed.getAttribute("data-value") : "";
      var q = search ? search.value.trim().toLowerCase() : "";
      var shown = 0;
      rows.forEach(function (row) {
        var ok = (!platform || (row.getAttribute("data-platform") || "").split(" ").indexOf(platform) >= 0) &&
          (!q || row.textContent.toLowerCase().indexOf(q) >= 0);
        row.hidden = !ok;
        if (ok) shown += 1;
      });
      if (count) count.textContent = shown === rows.length ? "Alle " + shown + " Projekte." : shown + " von " + rows.length + " Projekten.";
      if (empty) empty.hidden = shown > 0;
      list.hidden = shown === 0;
    };
    var sort = function () {
      var by = "neu";
      order.forEach(function (r) { if (r.checked) by = r.value; });
      rows.slice().sort(function (a, b) {
        if (by === "name") return a.getAttribute("data-name").localeCompare(b.getAttribute("data-name"), "de");
        return b.getAttribute("data-date").localeCompare(a.getAttribute("data-date"));
      }).forEach(function (row) { list.appendChild(row); });
    };
    // sb-controls.js sets aria-pressed on the same click; read the state after it ran
    if (chips) chips.addEventListener("click", function () { setTimeout(apply, 0); });
    if (search) search.addEventListener("input", apply);
    order.forEach(function (r) { r.addEventListener("change", sort); });
    if (reset) reset.addEventListener("click", function () {
      if (search) search.value = "";
      if (search) search.dispatchEvent(new Event("input", { bubbles: true }));
      if (chips) chips.querySelectorAll(".sb-chip[aria-pressed]").forEach(function (c, i) { c.setAttribute("aria-pressed", String(i === 0)); });
      apply();
      if (search) search.focus();
    });
    apply();
  }

  // 2) forms that send
  function icon(href, cls) {
    var NS = "http://www.w3.org/2000/svg", svg = document.createElementNS(NS, "svg"), use = document.createElementNS(NS, "use");
    svg.setAttribute("class", cls || "sb-icon"); svg.setAttribute("aria-hidden", "true"); svg.setAttribute("focusable", "false");
    use.setAttribute("href", href); svg.appendChild(use);
    return svg;
  }
  function de(n) { return n.toLocaleString("de-DE"); }

  function check(field) {
    var input = field.querySelector("input, textarea");
    if (!input) return "";
    var value = input.type === "checkbox" ? (input.checked ? "x" : "") : input.value.trim();
    if (input.required && !value) return field.getAttribute("data-g-web-missing") || "";
    if (value && input.type === "email" && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value)) return field.getAttribute("data-g-web-invalid") || "";
    var max = parseInt(field.getAttribute("data-g-web-max") || "0", 10);
    if (max && input.value.length > max) {
      return (field.getAttribute("data-g-web-toolong") || "").replace("{n}", de(input.value.length)).replace("{max}", de(max));
    }
    return "";
  }

  function show(field, message) {
    var input = field.querySelector("input, textarea");
    var error = field.querySelector(".sb-field__error");
    var text = error && error.querySelector("[data-g-web-error-text]");
    var ids = (input.getAttribute("aria-describedby") || "").split(" ").filter(function (id) { return id && (!error || id !== error.id); });
    if (message) {
      input.setAttribute("aria-invalid", "true");
      if (text) text.textContent = message;
      if (error) { error.hidden = false; ids.unshift(error.id); }
    } else {
      input.removeAttribute("aria-invalid");
      if (error) error.hidden = true;
    }
    if (ids.length) input.setAttribute("aria-describedby", ids.join(" ")); else input.removeAttribute("aria-describedby");
  }

  // live counter „0 / 1.000“ under a text area
  document.querySelectorAll("[data-g-web-counter]").forEach(function (out) {
    var input = document.getElementById(out.getAttribute("data-g-web-counter"));
    var max = parseInt(out.getAttribute("data-g-web-limit") || "0", 10);
    if (!input) return;
    var sync = function () { out.textContent = de(input.value.length) + " / " + de(max); };
    input.addEventListener("input", sync);
    sync();
  });

  document.querySelectorAll("form[data-g-web-send]").forEach(function (form) {
    var button = form.querySelector(".sb-primary-action");
    var label = button && button.querySelector(".sb-primary-action__label");
    var bar = button && button.querySelector(".sb-primary-action__bar");
    var sent = form.querySelector("[data-g-web-sent]");
    if (!button || !label || !bar) return;
    var idle = label.textContent;
    var fields = Array.prototype.slice.call(form.querySelectorAll("[data-g-web-check]"));

    // a field that was wrong is checked again while the person types
    fields.forEach(function (field) {
      var input = field.querySelector("input, textarea");
      input.addEventListener(input.type === "checkbox" ? "change" : "input", function () {
        if (input.getAttribute("aria-invalid") === "true") show(field, check(field));
      });
    });

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      if (button.getAttribute("aria-busy") === "true") return;
      var first = null;
      fields.forEach(function (field) {
        var message = check(field);
        show(field, message);
        if (message && !first) first = field.querySelector("input, textarea");
      });
      if (first) { first.focus(); return; }

      if (sent) sent.textContent = "";
      button.removeAttribute("data-sb-state");
      label.textContent = button.getAttribute("data-sb-busy") || "Wird gesendet …";
      button.setAttribute("aria-busy", "true");
      button.style.setProperty("--sb-progress", "0");
      if (!reduced()) {
        requestAnimationFrame(function () { requestAnimationFrame(function () {
          bar.style.transition = "transform 1800ms linear";
          button.style.setProperty("--sb-progress", "1");
        }); });
      } else {
        button.style.setProperty("--sb-progress", "1");
      }
      setTimeout(function () {
        bar.style.transition = "";
        button.removeAttribute("aria-busy");
        button.style.removeProperty("--sb-progress");
        label.textContent = "";
        label.appendChild(icon("#check"));
        label.appendChild(document.createTextNode(button.getAttribute("data-sb-done") || "Gesendet"));
        button.setAttribute("data-sb-state", "done");
        if (sent) {
          sent.appendChild(icon("#success--filled-16", "sb-icon sb-icon--16"));
          sent.appendChild(document.createTextNode(sent.getAttribute("data-g-web-sent")));
        }
        setTimeout(function () { label.textContent = idle; button.removeAttribute("data-sb-state"); }, 1500);
      }, 1800);
    });
  });
})();
