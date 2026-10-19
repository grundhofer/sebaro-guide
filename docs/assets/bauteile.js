// bauteile.js: behaviour of bauteile.html that the system scripts do not cover. Classic script, no modules, no network.
// [data-g-bauteile-enter="<id>"] replays the entry motion (.sb-enter) on that element, so the specimen can be watched again.
(function () {
  document.addEventListener("click", function (event) {
    var button = event.target instanceof Element ? event.target.closest("[data-g-bauteile-enter]") : null;
    if (!button) return;
    var target = document.getElementById(button.getAttribute("data-g-bauteile-enter"));
    if (!target) return;
    target.classList.remove("sb-enter");
    void target.offsetWidth;                                       // restart the animation
    target.classList.add("sb-enter");
  });
})();
