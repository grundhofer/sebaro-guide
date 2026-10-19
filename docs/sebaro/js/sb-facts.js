// sb-facts.js: the sebaro facts renderer for pages without a framework (spec/10 §5; FACTS-CONTRACT 1.1 §8).
// Classic script, no modules, no fetch (pages open from file://), CSP-safe: it reads JSON data blocks, builds DOM
// nodes with createElement (no innerHTML, no eval, no inline styles) and never invents text. Every sentence after a
// claim comes from the note data of `python3 tools/check_facts.py <facts> --notes` (FACTS-CONTRACT §8.6); the claim
// itself follows the wording table of spec/10 §3.2 and states exactly the fact value from facts.json.
//
// Data (inline_assets markers drop their own lines, TOOLS.md §4, CSP-safe form):
//   <script type="application/json" data-sb-facts="<id>"> facts.json </script>
//   <script type="application/json" data-sb-notes="<id>"> <id>.notes.json </script>
// Targets: any element with data-sb-render="<form>" and data-sb-product="<id>":
//   name           the product name from the file; title: name and version ("Tagwerk 1.4.0")
//   facts-line     (a) compact form; data-sb-full-href = link of the "n nicht belegt" cell
//   claim-rows     (b) full form as claim rows; data-sb-refs="accounts,tracking.adIds,…" (default: every fact, in the
//                  fixed order of spec/10 §4.2), data-sb-device (device rows first), data-sb-open="<refs>" (expanded),
//                  data-sb-for-version (apps: "für 1.4.0"), data-sb-checks-href, data-sb-id (id prefix)
//   check-summary  counts per state, one per line, + "Wie geprüft?" (data-sb-checks-href)
//   closing-line   "<Produkt> <Version> · Fakten geprüft am … · Nächste Prüfung fällig am …"
//   check-list     (c) every check in execution order
//   notes          website footnotes "Belege": numbered notes data-sb-from..data-sb-to (check_facts --note), back
//                  links to #ref-n; data-sb-checks-href for "Alle Prüfungen"
//   action         a button named by a path's action (data-sb-path, data-sb-kind="primary|secondary", data-sb-icon)
//                  plus its per-action hint (d)
//   action-hint    the hint alone, for an action button in the markup (data-sb-path)
// data-sb-running-version="1.5.0" on a target renders it as that version would see it (R1 version rule): stale.
// [data-sb-demo-marker="<id>"] gets the demo marker "Beispieldaten" when the file is demo data (f).
// [data-sb-needs-note="<id>:1,2"]: the element (a sentence with digits) is removed unless every listed numbered note
// may be stated (state "shown", or "unverified-disclosure" for a disclosure); D21, spec/10 §4.4.
(function () {
  "use strict";
  var SVGNS = "http://www.w3.org/2000/svg";
  var store = { facts: {}, notes: {} };

  // ------------------------------------------------------------------ data blocks
  function readBlocks() {
    var blocks = document.querySelectorAll('script[type="application/json"][data-sb-facts], script[type="application/json"][data-sb-notes]');
    Array.prototype.forEach.call(blocks, function (el) {
      var text = el.textContent.split("\n").filter(function (l) { return !/^\s*<!--/.test(l); }).join("\n");
      var data = JSON.parse(text);
      if (el.hasAttribute("data-sb-facts")) store.facts[el.getAttribute("data-sb-facts")] = data;
      else store.notes[el.getAttribute("data-sb-notes")] = data;
    });
  }

  // ------------------------------------------------------------------ words
  // FACTS-CONTRACT §6.1, §6.2, §6.4 default labels (the renderer's wording; the enum value is the contract)
  var DATA = { content: "deine Inhalte", settings: "Einstellungen", account: "Kontodaten", "ip-address": "IP-Adresse",
    "device-info": "Geräte- und Browserangaben", usage: "Nutzungsdaten", "crash-report": "Absturzberichte",
    contact: "Kontaktdaten", "search-terms": "Suchbegriffe" };
  var TRIGGER = { automatic: "automatisch", "on-user-command": "nur auf deinen Befehl", never: "nie" };
  var TRANSPORT = { tls: "verschlüsselt (TLS)", "end-to-end": "Ende-zu-Ende", none: "unverschlüsselt", local: "ohne Netz" };
  var STATE_GLYPH = { passed: "success--filled-16", open: "pending--16", skipped: "skipped--16", failed: "error--filled-16" };
  var STATE_STATUS = { passed: "success", open: "warning", skipped: "info", failed: "danger" };
  var STATE_WORD = { passed: "bestanden", open: "offen", skipped: "übersprungen", failed: "nicht bestanden" };
  var NBSP = " ";

  function tx(value) {                       // facts texts are {lang: text}; the tool's labels carry de and en
    if (value == null) return "";
    if (typeof value === "string") return value;
    return value.de != null ? value.de : (value.en != null ? value.en : "");
  }
  function cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : s; }
  function dateDe(iso) { var p = String(iso || "").split("-"); return p.length === 3 ? p[2] + "." + p[1] + "." + p[0] : iso; }
  function dataLabel(list) { return (list || []).map(function (d) { return DATA[d] || d; }).join(", "); }
  function retentionLabel(r, place) {
    if (!r) return "";
    var base = r.policy === "none" ? "nicht gespeichert" : r.policy === "session" ? "bis zum Schließen" :
      r.policy === "days" ? r.days + NBSP + "Tage" : r.policy === "until-deleted" ? "bis du es löschst" :
      r.policy === "user-controlled" ? "liegt bei dir" :
      r.policy === "processor-terms" ? "nach den Bedingungen von " + ((place && place.operator) || "…") : r.policy;
    return r.note ? base + " (" + tx(r.note) + ")" : base;
  }

  // ------------------------------------------------------------------ DOM helpers
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function icon(id, extra) {
    var svg = document.createElementNS(SVGNS, "svg");
    svg.setAttribute("class", "sb-icon" + (/-16$/.test(id) ? " sb-icon--16" : "") + (extra ? " " + extra : ""));
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("focusable", "false");
    var use = document.createElementNS(SVGNS, "use");
    use.setAttribute("href", "#" + id);
    svg.appendChild(use);
    return svg;
  }
  function link(href, cls, text) { var a = el("a", cls, text); a.href = href; return a; }
  function append(parent, children) { children.forEach(function (c) { if (c) parent.appendChild(c); }); return parent; }

  // ------------------------------------------------------------------ model
  function product(id) {
    var F = store.facts[id], N = store.notes[id];
    if (!F || !N) throw new Error("sb-facts: no facts or notes block for '" + id + "'");
    return { id: id, F: F, N: N, notes: N.notes };
  }
  function isStale(P, target) {
    var running = target && target.getAttribute("data-sb-running-version");
    if (running && running !== P.F.product.version) return true;          // R1 version rule
    return !!P.notes.stale;                                                 // computed by check_facts for --today
  }
  function claimOf(P, ref) {
    var list = P.notes.claims || [];
    for (var i = 0; i < list.length; i++) if (list[i].refs.join(",") === ref) return list[i];
    return null;
  }
  function placeById(P, id) {
    var list = P.F.places || [];
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }
  function pathById(P, id) {
    var list = P.F.paths || [];
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }
  function isRemote(place) { return place && (place.kind === "server" || place.kind === "third-party"); }
  function toLabel(P, placeId) {            // display form of a destination (FACTS-CONTRACT §5.5, §8.1)
    // the tool's own label wins when a note lists this destination as an outflow
    var claims = P.notes.claims || [];
    for (var i = 0; i < claims.length; i++) {
      var ds = claims[i].disclosures || [];
      for (var j = 0; j < ds.length; j++) if (ds[j].to === placeId && ds[j].labels && ds[j].labels.to) return tx(ds[j].labels.to);
    }
    var place = placeById(P, placeId);
    if (!place) return placeId;
    if (!isRemote(place)) return tx(place.label);
    var verified = place.proof && place.proof.status === "verified" && place.city;
    return tx(place.label) + " · " + (verified ? place.city + " (" + place.country + ")" : "Ort nicht belegt");
  }
  function pathLine(P, path) {              // the rest of a path fact after its claim: transport and retention (§8.5 b)
    var parts = [];
    if (path.transport) parts.push("Übertragung: " + (TRANSPORT[path.transport] || path.transport));
    var r = path.retention;
    if (r) parts.push("Speicherdauer: " + (r.policy === "processor-terms" && r.note ? tx(r.note) : retentionLabel(r, placeById(P, path.to))));
    return parts.join(" · ");
  }

  // claim wording, spec/10 §3.2: {text: claim when stated, label: row label when hidden}
  var TRACKING = {
    trackers: { none: "Keine Tracker", some: function (n, items) { return n + " Tracker: " + items; }, label: "Tracker" },
    analytics: { none: "Keine Analyse-Skripte", some: function (n, items) { return n + " Analyse-Dienste: " + items; }, label: "Analyse-Skripte" },
    adIds: { none: "Keine Werbe-ID", some: function () { return "liest die Werbe-ID"; }, label: "Werbe-ID" },
    cookies: { none: "Keine Cookies", some: function (n, items) { return n + " Cookies: " + items; }, label: "Cookies" }
  };
  function itemNames(items) { return (items || []).map(function (i) { return typeof i === "string" ? i : (i.name || tx(i.label)); }).join(", "); }
  function wording(P, ref) {
    var F = P.F, head = ref.split(".")[0], key = ref.slice(head.length + 1);
    if (head === "accounts") {
      var a = F.accounts || {};
      if (a.mode === "none") return { text: "Kein Konto", label: "Konto" };
      return { text: (a.mode === "optional" ? "Konto freiwillig" : "Konto nötig") + (a.purpose ? ": " + tx(a.purpose) : ""), label: "Konto" };
    }
    if (head === "tracking") {
      var t = (F.tracking || {})[key] || {}, w = TRACKING[key];
      return { text: t.count ? w.some(t.count, itemNames(t.items)) : w.none, label: w.label };
    }
    if (head === "places") {
      var pl = placeById(P, key);
      return { text: tx(pl.label) + " in " + pl.city + " (" + pl.country + ")", label: "Ort von " + tx(pl.label) };
    }
    if (head === "paths") {
      var p = pathById(P, key), purpose = tx(p.purpose);
      if (p.trigger === "never") return { text: "Nie: " + purpose, label: purpose };
      if (p.trigger === "on-user-command") return { text: "„" + (tx(p.action) || purpose) + "“ nur auf deinen Befehl", label: purpose };
      return { text: dataLabel(p.data) + " an " + toLabel(P, p.to) + ": automatisch", label: purpose };
    }
    if (head === "backup") {
      var b = (F.backup || {}).android || {}, cloud = b.cloudPath && pathById(P, b.cloudPath);
      var off = !b.allowBackup || (cloud && cloud.trigger === "never");
      return { text: "Android-Sicherung: " + (off ? "aus" : "an"), label: "Android-Sicherung" };
    }
    if (head === "permissions") {
      var n = ((F.permissions || {}).items || []).length;
      return { text: n === 0 ? "Keine Berechtigungen" : n + (n === 1 ? " Berechtigung" : " Berechtigungen"), label: "Berechtigungen" };
    }
    if (head === "dependencies") {
      var d = ((F.dependencies || {}).items || []).length;
      return { text: d === 0 ? "Keine Bibliotheken mit Datenweg" : d + (d === 1 ? " Bibliothek von Belang" : " Bibliotheken von Belang"), label: "Bibliotheken" };
    }
    if (head === "licence") return { text: "Lizenz: " + F.licence.spdx + (F.licence.content ? ", Texte " + F.licence.content : ""), label: "Lizenz" };
    if (head === "source") return { text: F.source.open ? "Quellcode offen" : "Quellcode nicht offen" + (F.source.reason ? ": " + tx(F.source.reason) : ""), label: "Quellcode" };
    return { text: ref, label: ref };
  }

  // a note may be stated when shown, or as an unverified disclosure (D21; FACTS-CONTRACT §8.6)
  function stated(note) { return note && (note.state === "shown" || note.state === "unverified-disclosure"); }

  function resultLine(note, withVersion) {    // spec/10 §3.3 item 1
    var L = note.labels, r = note.result;
    var line = (r === "open" || r === "skipped") ? tx(L.checkedOn) : tx(L.state) + " · " + tx(L.checkedOn);
    if (withVersion && L.forVersion) line += " " + tx(L.forVersion);
    if (note.state !== "shown") line = tx(L.notVerified || { de: "nicht belegt" }) + " · " + line;
    return line;
  }
  function resultGlyph(note) {
    var r = note.state === "shown" || note.result !== "passed" ? note.result : "open";
    return icon(STATE_GLYPH[r] || STATE_GLYPH.open, "sb-check-glyph sb-check-glyph--" + (r || "open"));
  }

  // the note text after the result line, spec/10 §3.3 items 2-7
  function noteBody(P, note, body, opts) {
    var lines = [];
    if (opts.pathLine) lines.push(el("p", "sb-note__outflow", opts.pathLine));
    var checkedText = (note.method || []).concat(note.proofNotes || []).map(function (m) {
      var text = tx(m).trim();
      return text ? text.replace(/[.!?]$/, "") + "." : "";
    }).filter(Boolean).join(" ");
    if (checkedText) lines.push(el("p", "sb-note__method", checkedText));
    (note.reasons || []).forEach(function (r) { lines.push(el("p", "sb-note__proof", "Grund: " + tx(r.text))); });
    (note.disclosures || []).forEach(function (d) {
      var L = d.labels;
      var line = tx(L.data) + " an " + tx(L.to) + ": " + [tx(L.trigger), tx(L.transport), tx(L.retention)].filter(Boolean).join(", ");
      if (L.retentionNote) line += " (" + tx(L.retentionNote) + ")";
      if (L.notVerified) line += " · " + tx(L.notVerified);
      lines.push(el("p", "sb-note__outflow", line));
    });
    var limits = note.labels.limits || [];
    limits.forEach(function (l) { lines.push(el("p", "sb-note__limit", tx(l))); });
    if (!limits.length) lines.push(el("p", "sb-note__limit", "Nicht geprüft: Der Umfang über die beschriebenen Schritte hinaus ist nicht angegeben."));
    var byText = tx(note.labels.by);
    if (note.by === "unknown") byText += ", Methode noch offen";
    var byLine = el("p", "sb-note__by", byText + ". ");
    if (opts.checksHref) byLine.appendChild(link(opts.checksHref, "sb-note__checks", opts.checksText));
    lines.push(byLine);
    return append(body, lines);
  }

  function demoMarker(P) {
    var label = P.notes.labels && P.notes.labels.demo;
    return label ? el("span", "sb-demo-marker", tx(label)) : null;
  }

  // ------------------------------------------------------------------ (b) claim rows, fixed order of spec/10 §4.2
  function fullOrder(P) {
    var claims = P.notes.claims || [], refs = claims.map(function (c) { return c.refs.join(","); });
    var rank = function (ref) {
      var head = ref.split(".")[0];
      var order = { accounts: 2, tracking: 3, places: 4, paths: 5, backup: 6, permissions: 7, dependencies: 7.5, licence: 8, source: 8.5 };
      var sub = { trackers: 0, analytics: 0.1, adIds: 0.2, cookies: 0.3 };
      var r = order[head] != null ? order[head] : 9;
      if (head === "tracking") r += sub[ref.split(".")[1]] || 0;
      return r;
    };
    return refs.map(function (r, i) { return [rank(r), i, r]; })
      .sort(function (a, b) { return a[0] - b[0] || a[1] - b[1]; })
      .map(function (x) { return x[2]; });
  }

  function deviceRows(P) {
    return (P.F.places || []).filter(function (pl) { return pl.kind === "device" && pl.stores; }).map(function (pl) {
      var s = pl.stores, row = el("div", "sb-facts__device");
      var how = tx(s.how).replace(/\.\s*$/, "");                  // the facts' own retention note says it best ("bis du Einträge löschst …")
      var keep = s.retention ? (s.retention.note ? tx(s.retention.note) : retentionLabel(s.retention)) : "";
      append(row, [
        el("p", null, tx(pl.label) + ": " + dataLabel(s.data)),
        el("p", null, how + (keep ? ", " + keep : "")),
        el("p", null, "Bleibt auf diesem Gerät.")
      ]);
      return row;
    });
  }

  function claimRow(P, ref, opts) {
    var note = claimOf(P, ref);
    if (!note) return null;
    var w = wording(P, ref), hidden = !stated(note);
    var id = opts.prefix + "-n-" + ref.replace(/[^a-zA-Z0-9]+/g, "-");
    var li = el("li", "sb-claim-row");
    li.setAttribute("data-refs", ref);
    li.setAttribute("data-state", note.state);
    var open = opts.open.indexOf(ref) >= 0;
    var btn = el("button", "sb-claim-row__toggle");
    btn.type = "button";
    btn.setAttribute("aria-expanded", String(open));
    btn.setAttribute("aria-controls", id);
    var result = el("span", "sb-claim-row__result");
    append(result, [resultGlyph(note), document.createTextNode(resultLine(note, opts.forVersion))]);
    append(btn, [el("span", "sb-claim-row__claim", cap(hidden ? w.label : w.text)), result, icon("chevron-down", "sb-claim-row__chevron")]);
    var body = el("div", "sb-claim-row__note sb-note__body");
    body.id = id;
    if (!open) body.hidden = true;
    var head = ref.split(".")[0], path = head === "paths" ? pathById(P, ref.slice(6)) : null;
    noteBody(P, note, body, {
      pathLine: path && path.trigger !== "never" && !hidden ? pathLine(P, path) || null : null,
      checksHref: opts.checksHref, checksText: "Wie geprüft?"
    });
    return append(li, [btn, body]);
  }

  function staleNotice(P) {
    var p = el("p", "sb-stale-notice");
    return append(p, [icon("warning--filled-16"), document.createTextNode(tx(P.notes.labels.stale))]);
  }

  function renderClaimRows(target, P) {
    var refsAttr = target.getAttribute("data-sb-refs");
    var opts = {
      prefix: target.getAttribute("data-sb-id") || P.id,
      open: (target.getAttribute("data-sb-open") || "").split(",").filter(Boolean),
      forVersion: target.hasAttribute("data-sb-for-version"),
      checksHref: target.getAttribute("data-sb-checks-href")
    };
    var out = [];
    if (isStale(P, target)) {
      out.push(staleNotice(P));
    } else {
      if (target.hasAttribute("data-sb-device")) out = out.concat(deviceRows(P));
      var ul = el("ul", "sb-claim-rows");
      var refs = refsAttr ? refsAttr.split(",").map(function (r) { return r.trim(); }) : fullOrder(P);
      refs.forEach(function (ref) { var row = claimRow(P, ref, opts); if (row) ul.appendChild(row); });
      out.push(ul);
    }
    target.replaceChildren.apply(target, out);
  }

  // ------------------------------------------------------------------ check summary, closing line, (c) check list
  function renderCheckSummary(target, P) {
    var counts = P.N.view.checks, out = [];
    ["passed", "open", "skipped", "failed"].forEach(function (s) {
      if (!counts[s]) return;
      var p = el("p", "sb-status sb-status--" + STATE_STATUS[s]);
      append(p, [icon(STATE_GLYPH[s]), document.createTextNode(counts[s] + " " + STATE_WORD[s])]);
      out.push(p);
    });
    var href = target.getAttribute("data-sb-checks-href");
    if (href) { var p2 = el("p"); p2.appendChild(link(href, null, "Wie geprüft?")); out.push(p2); }
    target.replaceChildren.apply(target, out);
  }

  function renderClosingLine(target, P) {
    var F = P.F;
    target.textContent = F.product.name + " " + F.product.version + " · Fakten geprüft am " + dateDe(F.freshness.checkedOn) +
      " · " + tx(P.notes.labels.nextDue);
  }

  function renderCheckList(target, P) {
    var ol = el("ol", "sb-check-list");
    (P.notes.checks || []).forEach(function (c) {
      var li = el("li", "sb-check-list__item");
      li.setAttribute("data-check", c.id);
      li.setAttribute("data-state", c.state);
      var state = el("p", "sb-check-state sb-check-state--" + c.state);
      append(state, [icon(STATE_GLYPH[c.state]), document.createTextNode(tx(c.labels.state))]);
      var parts = [state, el("p", "sb-check-list__title", tx(c.title)),
        el("p", "sb-check-list__meta", tx(c.labels.date) + " · " + tx(c.labels.by) + (c.by ? "" : ", Methode noch offen"))];
      if (c.reason) parts.push(el("p", "sb-check-list__reason", "Grund: " + tx(c.reason)));
      if (c.labels.limit) parts.push(el("p", "sb-check-list__limit", tx(c.labels.limit)));
      (c.evidence || []).forEach(function (ev) {
        var p = el("p", "sb-check-list__meta");
        p.appendChild(document.createTextNode("Beleg: "));
        if (/^https?:\/\//.test(ev.ref)) p.appendChild(link(ev.ref, null, ev.ref));
        else p.appendChild(el("code", null, ev.ref));                        // demo refs "demo:…" stay code
        parts.push(p);
      });
      ol.appendChild(append(li, parts));
    });
    target.replaceChildren(ol);
  }

  // ------------------------------------------------------------------ (a) compact form, spec/10 §4.1
  function renderFactsLine(target, P) {
    var cells = [], F = P.F, hiddenCount = 0;
    function cell(node) { var c = el("span", "sb-facts-line__cell"); var s = el("span", "sb-facts-line__sep", "·"); s.setAttribute("aria-hidden", "true"); return append(c, [s, node]); }
    if (isStale(P, target)) {
      cells.push(cell(staleNotice(P)));
    } else {
      ["trackers", "analytics", "adIds", "cookies"].forEach(function (k) {
        if (!(F.tracking || {})[k]) return;
        var note = claimOf(P, "tracking." + k);
        if (stated(note)) cells.push(cell(document.createTextNode(wording(P, "tracking." + k).text))); else hiddenCount++;
      });
      if (F.accounts) {
        var an = claimOf(P, "accounts");
        if (stated(an)) cells.push(cell(document.createTextNode(wording(P, "accounts").text))); else hiddenCount++;
      }
      var net = P.N.view.network, netText;
      if (net === "none") {
        var neverShown = (F.paths || []).filter(function (p) { return p.trigger === "never" && isRemote(placeById(P, p.to)); })
          .every(function (p) { return stated(claimOf(P, "paths." + p.id)); });
        netText = neverShown ? "verbindet sich mit keinem Server" : null;
        if (!neverShown) hiddenCount++;
      } else {
        netText = net === "on-user-command" ? "verbindet sich nur auf deinen Befehl" : "verbindet sich selbst";
      }
      if (netText) cells.push(cell(document.createTextNode(netText)));
      (P.notes.claims || []).forEach(function (c) {
        var ref = c.refs.join(",");
        if (!/^places\./.test(ref) || c.refs.length !== 1) return;
        var pl = placeById(P, ref.slice(7));
        if (!isRemote(pl)) return;
        if (c.state === "shown") cells.push(cell(document.createTextNode(pl.city + " (" + pl.country + ")"))); else hiddenCount++;
      });
      if (hiddenCount) {
        var href = target.getAttribute("data-sb-full-href");
        var label = hiddenCount + " nicht belegt";
        cells.push(cell(href ? link(href, null, label) : document.createTextNode(label)));
      }
    }
    var marker = demoMarker(P);
    if (marker) cells.push(cell(marker));
    target.replaceChildren.apply(target, [el("span", "sb-facts-line__name", F.product.name)].concat(cells));
  }

  // ------------------------------------------------------------------ website notes "Belege"
  function renderNotes(target, P) {
    var from = +(target.getAttribute("data-sb-from") || 1), to = +(target.getAttribute("data-sb-to") || 999);
    var href = target.getAttribute("data-sb-checks-href");
    var ol = target.tagName === "OL" ? target : el("ol", "sb-notes__list");   // the list itself, or a box for it
    if (from !== 1) ol.setAttribute("start", String(from));
    ol.replaceChildren();
    (P.notes.numbered || []).forEach(function (note) {
      if (note.n < from || note.n > to) return;
      var li = el("li", "sb-note");
      li.id = "beleg-" + note.n;
      var backlinks = el("span", "sb-note__backs");
      var citations = document.querySelectorAll('.sb-note-ref[href="#beleg-' + note.n + '"]');
      Array.prototype.forEach.call(citations, function (citation, index) {
        var back = link("#" + citation.id, "sb-note__back", index === 0 ? String(note.n) : String(note.n) + "b");
        back.setAttribute("role", "doc-backlink");
        back.setAttribute("aria-label", "Zurück zur Aussage " + note.n + (index ? ", weitere Stelle" : ", erste Stelle"));
        backlinks.appendChild(back);
      });
      var body = el("div", "sb-note__body");
      var result = el("p", "sb-note__result");
      append(result, [resultGlyph(note), document.createTextNode(resultLine(note, false))]);
      body.appendChild(result);
      noteBody(P, note, body, { checksHref: href, checksText: "Alle Prüfungen" });
      ol.appendChild(append(li, [backlinks, body]));
    });
    if (ol !== target) target.replaceChildren(ol);
  }

  // ------------------------------------------------------------------ (d) actions and their hints, spec/10 §3.4
  function hintText(P, path) {
    var place = placeById(P, path.to);
    if (place && place.kind === "device") return "Bleibt auf diesem Gerät.";
    return cap(TRIGGER[path.trigger] || path.trigger) + ". Ziel: " + toLabel(P, path.to) + ".";
  }
  function renderAction(target, P) {
    var path = pathById(P, target.getAttribute("data-sb-path"));
    var kind = target.getAttribute("data-sb-kind") === "primary" ? "sb-primary-action" : "sb-secondary-action";
    var btn = el("button", kind);
    btn.type = "button";
    var ic = target.getAttribute("data-sb-icon");
    if (ic) btn.appendChild(icon(ic));
    btn.appendChild(document.createTextNode(tx(path.action)));
    target.replaceChildren(btn, el("p", "sb-action-hint", hintText(P, path)));
  }
  function renderActionHint(target, P) { target.textContent = hintText(P, pathById(P, target.getAttribute("data-sb-path"))); }

  // ------------------------------------------------------------------ run
  var RENDER = { name: function (t, P) { t.textContent = P.F.product.name; },
    title: function (t, P) { t.textContent = P.F.product.name + " " + P.F.product.version; }, "facts-line": renderFactsLine,
    "claim-rows": renderClaimRows, "check-summary": renderCheckSummary, "closing-line": renderClosingLine,
    "check-list": renderCheckList, notes: renderNotes, action: renderAction, "action-hint": renderActionHint };

  function renderAll(root) {
    root = root || document;
    root.querySelectorAll("[data-sb-render]").forEach(function (t) {
      var fn = RENDER[t.getAttribute("data-sb-render")];
      if (!fn) throw new Error("sb-facts: unknown form '" + t.getAttribute("data-sb-render") + "'");
      fn(t, product(t.getAttribute("data-sb-product")));
    });
    root.querySelectorAll("[data-sb-demo-marker]").forEach(function (t) {
      var m = demoMarker(product(t.getAttribute("data-sb-demo-marker")));
      if (m) t.replaceChildren(m); else t.remove();
    });
    root.querySelectorAll("[data-sb-needs-note]").forEach(function (t) {
      var spec = t.getAttribute("data-sb-needs-note").split(":"), P = product(spec[0]);
      var ok = !isStale(P, t) && spec[1].split(",").every(function (n) {
        return (P.notes.numbered || []).some(function (note) { return String(note.n) === n.trim() && stated(note); });
      });
      if (!ok) t.remove();
    });
  }

  readBlocks();
  window.SbFacts = { data: store, render: renderAll, wording: function (id, ref) { return wording(product(id), ref); } };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", function () { renderAll(); });
  else renderAll();
})();
