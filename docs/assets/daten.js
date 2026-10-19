// daten.js: behaviour of the proposal specimens on daten.html. Classic script, no modules, no network, CSP-safe.
// The page reads correctly without it: the table is already sorted, the tree is already open.
// 1) [data-g-sort] tables: a column head button sorts the body rows by data-value (or text); aria-sort follows.
(function () {
  document.querySelectorAll("table[data-g-sort]").forEach(function (table) {
    var buttons = Array.prototype.slice.call(table.querySelectorAll("thead .g-daten-sort"));
    var status = document.getElementById(table.getAttribute("data-g-sort"));
    function cellValue(row, index) {
      var cell = row.children[index];
      var v = cell.getAttribute("data-value");
      return v !== null ? parseFloat(v) : cell.textContent.trim().toLowerCase();
    }
    buttons.forEach(function (button) {
      button.addEventListener("click", function () {
        var th = button.closest("th");
        var index = Array.prototype.indexOf.call(th.parentNode.children, th);
        var dir = button.getAttribute("data-dir") === "desc" ? "asc" : "desc";
        var body = table.tBodies[0];
        var rows = Array.prototype.slice.call(body.rows);
        rows.sort(function (a, b) {
          var x = cellValue(a, index), y = cellValue(b, index);
          var r = typeof x === "number" ? x - y : String(x).localeCompare(String(y), "de");
          return dir === "asc" ? r : -r;
        });
        rows.forEach(function (r) { body.appendChild(r); });
        buttons.forEach(function (b) {
          b.removeAttribute("data-dir");
          b.closest("th").removeAttribute("aria-sort");
        });
        button.setAttribute("data-dir", dir);
        th.setAttribute("aria-sort", dir === "asc" ? "ascending" : "descending");
        if (status) {
          status.textContent = "Sortiert nach " + button.getAttribute("data-name") + ", " +
            (dir === "asc" ? "aufsteigend." : "absteigend.");
        }
      });
    });
  });
})();

// 2) .g-daten-twist buttons open and close the nested list named by aria-controls (tree specimen).
(function () {
  document.addEventListener("click", function (event) {
    var button = event.target.closest ? event.target.closest(".g-daten-twist") : null;
    if (!button) return;
    var target = document.getElementById(button.getAttribute("aria-controls"));
    var open = button.getAttribute("aria-expanded") !== "true";
    button.setAttribute("aria-expanded", open ? "true" : "false");
    if (target) target.hidden = !open;
  });
})();
