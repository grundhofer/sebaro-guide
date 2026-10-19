// gedanken.js: behaviour of gedanken.html only. Classic script, no network, no inline handlers.
// 1) colour-job demo: a chip with data-g-job-chip sets data-g-show on .g-gedanken-demo and says what is left in colour.
//    sb-controls.js keeps exactly one chip pressed (data-sb-single); this script only reads the clicked chip.
(function () {
  var demo = document.querySelector(".g-gedanken-demo");
  if (!demo) return;
  var say = demo.querySelector("[data-g-job-say]");
  var text = {
    alle: "Alle Farben mit ihrer Aufgabe. Der Rest ist grau.",
    ort: "Kobalt: der Ort „Heute“ und der Link. Alles andere ist jetzt grau.",
    schritt: "Lindgrün: nur die eine Hauptaktion „Neue Gewohnheit“, unten.",
    zustand: "Statusfarben: nur die Zeichen, jedes mit einem Wort daneben.",
    app: "Kachelfarbe: nur in der Kachel der App, nirgends sonst."
  };
  demo.addEventListener("click", function (event) {
    var chip = event.target.closest("[data-g-job-chip]");
    if (!chip) return;
    var job = chip.getAttribute("data-g-job-chip");
    demo.setAttribute("data-g-show", job);
    if (say && text[job]) say.textContent = text[job];
  });
})();

// 2) motion demo: "Zeile einfügen" adds a row with sb-enter (8 px from below, 200 ms; a fade with reduced motion).
//    After four rows the list starts over, so the specimen stays short.
(function () {
  var button = document.querySelector("[data-g-motion-add]");
  var list = document.querySelector("[data-g-motion-list]");
  if (!button || !list) return;
  var names = ["Abendspaziergang", "Vitamin D", "Lesen, 20 Min.", "Dehnen"];
  var next = 0;
  button.addEventListener("click", function () {
    if (list.children.length >= 4) {
      while (list.children.length > 1) list.removeChild(list.lastElementChild);
    }
    var li = document.createElement("li");
    li.className = "sb-list-row sb-enter";
    var main = document.createElement("div");
    main.className = "sb-list-row__main";
    var title = document.createElement("p");
    title.className = "sb-list-row__title";
    title.textContent = names[next % names.length];
    next += 1;
    main.appendChild(title);
    li.appendChild(main);
    list.appendChild(li);
    li.addEventListener("animationend", function () { li.classList.remove("sb-enter"); }, { once: true });
  });
})();
