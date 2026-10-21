// sb-form.js: a website form whose result replaces it (D91 W1a; spec/02 §5.4.1, spec/09 §18.1). Classic script (pages
// open from file://), CSP-safe: no inline handlers, no eval, styles only through classes and the CSSOM.
// Progressive enhancement: without this script the form posts normally and the server answers with the result page
// (POST, then 303 to a GET address that renders the result; a reload shows the result again and never sends twice).
// Markup
//   form.sb-form-grid[data-sb-result="<id>"] with action and method="post"; in its .sb-form-grid__actions an empty
//   p.sb-form-grid__message[data-sb-form-message] and, last, the submit button .sb-primary-action with
//   .sb-primary-action__label and .sb-primary-action__bar.
//   .sb-form-result#<id>[hidden]: heading .sb-form-result__title[tabindex="-1"], a sentence, an optional summary with
//   [data-sb-echo="<field name>"] slots (filled with the sent value as text; a select gives its option's words) and
//   [data-sb-echo-time] (the time of sending in the form's language), the next step as a link; a link with
//   [data-sb-form-again] shows the empty form again.
// Flow (D48, D83 (2), D78)
//   submit → busy: aria-busy, the sweeping bar, label „Wird gesendet …“; a second submit is ignored
//   → fetch(action, POST, FormData)
//   2xx: done (check icon + „Gesendet“ for x-sebaro.primary-action.done-dwell), then the result replaces the form: it
//        enters with .sb-enter (an action, D80) and focus moves to its heading
//   4xx: the server found a field error: the script steps aside and submits natively; the server renders the page
//        with the errors at the fields (spec/02 §2.1)
//   network failure or 5xx: data-sb-state="retry", label „Noch mal versuchen“, the reason as a sentence after the
//        error glyph before the button; every field keeps its value. No toast, no tinted box
// Demo pages without a server: data-sb-demo="ok" | "fail" on the form answers without a request ("fail" fails once,
// then succeeds), like [data-sb-demo-progress] in sb-controls.js.
// Messages follow the language of the form (closest [lang], else <html lang>): German default, English built in;
// window.sbMessages = { "sb-form": { fr: { … } } } before this script adds one (D87, spec/09 §6.1).
(function () {
  var MESSAGES = {
    de: {
      busy: "Wird gesendet …", done: "Gesendet", retry: "Noch mal versuchen",
      failed: "Senden hat nicht geklappt. Deine Eingaben sind noch da.",
      offline: "Keine Verbindung. Deine Eingaben sind noch da; versuch es gleich noch einmal."
    },
    en: {
      busy: "Sending …", done: "Sent", retry: "Try again",
      failed: "Sending did not work. Your entries are still here.",
      offline: "No connection. Your entries are still here; try again in a moment."
    }
  };
  var extra = window.sbMessages && window.sbMessages["sb-form"];
  if (extra) Object.keys(extra).forEach(function (l) { MESSAGES[l.toLowerCase()] = extra[l]; });
  function lang(el) {
    var holder = el && el.closest("[lang]");
    return ((holder || document.documentElement).getAttribute("lang") || "de").toLowerCase();
  }
  function t(el, key) {
    var l = lang(el);
    var table = MESSAGES[l] || MESSAGES[l.split("-")[0]] || MESSAGES.de;
    return table[key] != null ? table[key] : MESSAGES.de[key];
  }
  function icon(href, cls) {
    var ns = "http://www.w3.org/2000/svg";
    var svg = document.createElementNS(ns, "svg");
    svg.setAttribute("class", cls || "sb-icon sb-icon--20");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("focusable", "false");
    var use = document.createElementNS(ns, "use");
    use.setAttribute("href", href); svg.appendChild(use);
    return svg;
  }
  function dwell() {
    var v = getComputedStyle(document.documentElement).getPropertyValue("--sb-x-sebaro-primary-action-done-dwell").trim();
    var ms = parseFloat(v);
    if (!isFinite(ms)) return 1500;
    return /ms$/.test(v) ? ms : ms * 1000;
  }
  // D22: Intl may write U+202F or U+2009 (English times, some percent forms); UI text uses U+00A0
  function nbsp(s) { return s.replace(/[  ]/g, " "); }

  function parts(form) {
    var button = form.querySelector('.sb-form-grid__actions .sb-primary-action[type="submit"], .sb-form-grid__actions button.sb-primary-action:not([type])');
    return {
      button: button,
      label: button && button.querySelector(".sb-primary-action__label"),
      message: form.querySelector("[data-sb-form-message]"),
      result: document.getElementById(form.getAttribute("data-sb-result") || "")
    };
  }

  function busy(form, p) {
    if (!p.label.hasAttribute("data-sb-idle")) p.label.setAttribute("data-sb-idle", p.label.textContent);
    if (p.message) p.message.textContent = "";
    p.button.removeAttribute("data-sb-state");
    p.button.setAttribute("aria-busy", "true");
    p.button.setAttribute("data-sb-progress", "indeterminate");
    p.label.textContent = t(form, "busy");
  }
  function idle(p) {
    p.button.removeAttribute("aria-busy");
    p.button.removeAttribute("data-sb-progress");
  }
  function failed(form, p, key) {
    idle(p);
    p.button.setAttribute("data-sb-state", "retry");
    p.label.textContent = t(form, "retry");
    if (p.message) {
      p.message.textContent = "";
      p.message.appendChild(icon("#error--16", "sb-icon sb-icon--16"));
      p.message.appendChild(document.createTextNode(t(form, key)));
    }
  }
  function echo(form, result) {
    result.querySelectorAll("[data-sb-echo]").forEach(function (slot) {
      var field = form.elements.namedItem(slot.getAttribute("data-sb-echo"));
      if (!field) return;
      var value = field.tagName === "SELECT" && field.selectedOptions[0] ? field.selectedOptions[0].textContent : field.value;
      slot.textContent = value;
    });
    result.querySelectorAll("[data-sb-echo-time]").forEach(function (slot) {
      var now = new Date();
      try { slot.textContent = nbsp(new Intl.DateTimeFormat(lang(slot), { dateStyle: "medium", timeStyle: "short" }).format(now)); }
      catch (e) { slot.textContent = now.toLocaleString(); }
      if (slot.tagName === "TIME") slot.setAttribute("datetime", now.toISOString());
    });
  }
  function done(form, p) {
    idle(p);
    p.label.textContent = "";
    p.label.appendChild(icon("#check"));
    p.label.appendChild(document.createTextNode(t(form, "done")));
    p.button.setAttribute("data-sb-state", "done");
    setTimeout(function () {
      if (!p.result) return;
      echo(form, p.result);
      form.hidden = true;
      p.result.hidden = false;
      enter(p.result);
      var heading = p.result.querySelector(".sb-form-result__title");
      if (heading) heading.focus();
      reset(form, p);
    }, dwell());
  }
  function reset(form, p) {
    p.button.removeAttribute("data-sb-state");
    if (p.label.hasAttribute("data-sb-idle")) p.label.textContent = p.label.getAttribute("data-sb-idle");
    if (p.message) p.message.textContent = "";
  }
  function enter(el) {
    el.classList.add("sb-enter");
    el.addEventListener("animationend", function end() { el.classList.remove("sb-enter"); el.removeEventListener("animationend", end); });
  }

  function send(form, p) {
    var demo = form.getAttribute("data-sb-demo");
    if (demo) {
      setTimeout(function () {
        if (demo === "fail") { form.setAttribute("data-sb-demo", "ok"); failed(form, p, "failed"); }
        else done(form, p);
      }, 1200);
      return;
    }
    if (!window.fetch || !window.FormData) { form.submit(); return; }
    fetch(form.action, { method: "POST", body: new FormData(form), headers: { "Accept": "text/html" }, credentials: "same-origin" })
      .then(function (response) {
        if (response.ok) { done(form, p); return; }
        if (response.status >= 400 && response.status < 500) { idle(p); reset(form, p); form.submit(); return; }
        failed(form, p, "failed");
      })
      .catch(function () { failed(form, p, navigator.onLine === false ? "offline" : "failed"); });
  }

  document.addEventListener("submit", function (event) {
    var form = event.target;
    if (!(form instanceof HTMLFormElement) || !form.hasAttribute("data-sb-result")) return;
    var p = parts(form);
    if (!p.button || !p.label || !p.result) return;   // incomplete markup: let the browser post the form
    event.preventDefault();
    if (p.button.getAttribute("aria-busy") === "true") return;
    busy(form, p);
    send(form, p);
  });

  document.addEventListener("click", function (event) {
    var again = event.target instanceof Element ? event.target.closest("[data-sb-form-again]") : null;
    if (!again) return;
    var result = again.closest(".sb-form-result");
    var form = result && result.id ? document.querySelector('form[data-sb-result="' + result.id + '"]') : null;
    if (!form) return;   // a server-rendered result: the link goes to the form's address
    event.preventDefault();
    form.reset();
    result.hidden = true;
    form.hidden = false;
    enter(form);
    var first = form.querySelector("input:not([type=hidden]), select, textarea");
    if (first) first.focus();
  });
})();
