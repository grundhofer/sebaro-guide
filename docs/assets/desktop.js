// desktop.js: behaviour of desktop.html that the system scripts do not cover. Classic script, no modules, no network.
// #dk-combo-in: the keys of a field with suggestions (spec/02 §4.26), which sebaro ships no script for and the app
// supplies: ↓ / ↑ move the active option (aria-activedescendant, kept in view), Eingabe takes it, Escape closes the list
// and keeps the text (a second Escape is the field's), typing filters, a press on an option takes it; focus stays in
// the field, the list never takes it. A guide demonstration, not a sebaro part.
(function () {
  var field = document.getElementById("dk-combo-in");
  var list = field && document.getElementById(field.getAttribute("aria-controls"));
  if (!list) return;
  var items = Array.prototype.map.call(list.querySelectorAll("[role=option]"), function (option) {
    return { option: option, name: option.querySelector(".sb-row__name").textContent };
  });
  function shown() { return items.filter(function (it) { return !it.option.hidden; }); }
  function setActive(it) {
    items.forEach(function (x) { x.option.setAttribute("aria-selected", x === it ? "true" : "false"); });
    if (it) { field.setAttribute("aria-activedescendant", it.option.id); it.option.scrollIntoView({ block: "nearest" }); }
    else field.removeAttribute("aria-activedescendant");
  }
  function active() { var id = field.getAttribute("aria-activedescendant"); return items.filter(function (it) { return it.option.id === id; })[0]; }
  function hide(el, off) { el.hidden = off; el.style.display = off ? "none" : ""; }   // sebaro's display outweighs [hidden]
  function open(on) {
    hide(list, !on);
    field.setAttribute("aria-expanded", on ? "true" : "false");
    if (!on) setActive(null);
  }
  function mark(it, typed) {                                     // the typed letters in body-strong (sb-completion__hit)
    var name = it.option.querySelector(".sb-row__name"), at = it.name.toLowerCase().indexOf(typed.toLowerCase());
    name.textContent = "";
    if (at < 0 || !typed) { name.textContent = it.name; return; }
    var hit = document.createElement("b");
    hit.className = "sb-completion__hit";
    hit.textContent = it.name.slice(at, at + typed.length);
    name.append(it.name.slice(0, at), hit, it.name.slice(at + typed.length));
  }
  function filter() {
    var typed = field.value.trim();
    items.forEach(function (it) {
      hide(it.option, !typed || it.name.toLowerCase().indexOf(typed.toLowerCase()) < 0);
      mark(it, typed);
    });
    var left = shown();
    open(left.length > 0);
    if (left.length) setActive(left[0]);
  }
  function take(it) { field.value = it.name; open(false); }
  field.addEventListener("input", filter);
  field.addEventListener("keydown", function (event) {
    var expanded = field.getAttribute("aria-expanded") === "true", left = shown(), at = left.indexOf(active());
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      if (!expanded) { filter(); return; }
      var step = event.key === "ArrowDown" ? 1 : -1;
      setActive(left[Math.min(Math.max(at + step, 0), left.length - 1)]);
    } else if (event.key === "Enter" && expanded && at >= 0) {
      event.preventDefault();
      take(left[at]);
    } else if (event.key === "Escape" && expanded) {
      event.preventDefault();
      event.stopPropagation();
      open(false);
    }
  });
  field.addEventListener("blur", function () { open(false); });
  list.addEventListener("mousedown", function (event) { event.preventDefault(); });   // the field keeps focus
  list.addEventListener("click", function (event) {
    var option = event.target instanceof Element ? event.target.closest("[role=option]") : null;
    var it = items.filter(function (x) { return x.option === option; })[0];
    if (it) take(it);
  });
})();
