// regeln-ex-a.js: live behaviour of the rule examples of batch a (Haltung … Bewegung) on regeln.html.
// Classic script, CSP-safe, no network. Only hooks with data-g-rx-*, so it never doubles what sebaro's own
// sb-controls.js does (if a page loads both). Every specimen shows its right state without this script.
// Dialogs (EBE-03, FOR-04) open through sb-controls.js ([data-sb-opens]), the hook products use.
//   [data-g-rx-add="<list id>"]      BEW-01: adds a list row that enters with .sb-enter (8 px from below, 200 ms)
//   [data-g-rx-show="<id>"]          BEW-02/04: shows the toast again, so its entry motion plays once more
//   [data-g-rx-wrong="<id>"]         BEW-02 "Nicht so": the same, but flying in from the side with a bounce
//   [data-g-rx-tone]                 BEW-03: toggles aria-pressed; the tone box next to it changes over 120/160/200/500 ms
//   [data-g-rx-switch]               BEW-04: a switch (role="switch"); with data-g-rx-scope="<id>" it sets
//                                    data-g-rx-reduced on that element only, a local stand-in for html[data-sb-motion]
(function () {
  var rowCount = {};

  function replay(el, extraClass) {
    if (!el) return;
    if (extraClass) el.classList.add(extraClass);
    el.hidden = true;
    void el.offsetWidth; // restart the CSS entry animation: display none -> shown again
    el.hidden = false;
  }

  document.addEventListener("click", function (event) {
    var t = event.target instanceof Element ? event.target : null;
    if (!t) return;

    var add = t.closest("[data-g-rx-add]");
    if (add) {
      var list = document.getElementById(add.getAttribute("data-g-rx-add"));
      if (!list) return;
      var id = list.id;
      rowCount[id] = (rowCount[id] || 0) + 1;
      var li = document.createElement("li");
      li.className = "sb-list-row sb-enter";
      var main = document.createElement("div");
      main.className = "sb-list-row__main";
      var title = document.createElement("p");
      title.className = "sb-list-row__title";
      title.textContent = "Neue Zeile " + rowCount[id];
      var meta = document.createElement("p");
      meta.className = "sb-list-row__meta";
      meta.textContent = "gerade hinzugefügt";
      main.appendChild(title);
      main.appendChild(meta);
      li.appendChild(main);
      list.appendChild(li);
      while (list.children.length > 4) list.removeChild(list.firstElementChild);
      return;
    }

    var show = t.closest("[data-g-rx-show]");
    if (show) { replay(document.getElementById(show.getAttribute("data-g-rx-show"))); return; }

    var wrong = t.closest("[data-g-rx-wrong]");
    if (wrong) { replay(document.getElementById(wrong.getAttribute("data-g-rx-wrong")), "is-playing"); return; }

    var tone = t.closest("[data-g-rx-tone]");
    if (tone) { tone.setAttribute("aria-pressed", String(tone.getAttribute("aria-pressed") !== "true")); return; }

  });

  // The switch state is read in the capture phase, before sb-controls.js (a bubbling listener) can toggle it;
  // after all listeners ran, toggle here only when nobody else did, then mirror the state onto the scope.
  document.addEventListener("click", function (event) {
    var t = event.target instanceof Element ? event.target : null;
    var sw = t && t.closest("[data-g-rx-switch]");
    if (!sw || sw.disabled) return;
    var before = sw.getAttribute("aria-checked");
    setTimeout(function () {
      if (sw.getAttribute("aria-checked") === before) sw.setAttribute("aria-checked", String(before !== "true"));
      var scope = document.getElementById(sw.getAttribute("data-g-rx-scope") || "");
      if (scope) {
        if (sw.getAttribute("aria-checked") === "true") scope.setAttribute("data-g-rx-reduced", "");
        else scope.removeAttribute("data-g-rx-reduced");
      }
    }, 0);
  }, true);
})();
