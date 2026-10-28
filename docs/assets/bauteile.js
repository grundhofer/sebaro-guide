// bauteile.js: behaviour of bauteile.html that the system scripts do not cover. Classic script, no modules, no network.
// [data-g-bauteile-enter="<id>"] replays the entry motion (.sb-enter) on that element, so the specimen can be watched again.
// #b-canvas: places the free canvas through the CSSOM as an app does (spec/02 §3.29, CSP-safe, no style attribute);
// the same places and steps as the entry's JavaScript block.
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
(function () {
  var plane = document.querySelector("#b-canvas .sb-canvas__plane");
  if (!plane) return;
  var places = [                                                  // in rem, in markup order: group, four cards, two pointers
    { x: 1.5, y: 1.5, w: 26, h: 18 },
    { x: 3, y: 5 }, { x: 3, y: 11.5 },
    { x: 31, y: 3 }, { x: 33, y: 14 },
    { x: 34, y: 8.5 }, { x: 13, y: 15.5 }
  ];
  plane.style.inlineSize = "56rem";
  plane.style.blockSize = "22rem";
  Array.prototype.forEach.call(plane.children, function (part, i) {
    var place = places[i];
    if (!place) return;
    part.style.insetInlineStart = place.x + "rem";
    part.style.insetBlockStart = place.y + "rem";
    if (place.w) {
      part.style.inlineSize = place.w + "rem";
      part.style.blockSize = place.h + "rem";
    }
  });
})();
