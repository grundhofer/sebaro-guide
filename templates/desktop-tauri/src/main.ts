// main.ts: the app's own behaviour. Everything sebaro already does is left to its scripts (sb-window.js: palette,
// fixed shortcuts, F6, panes, dividers, document tabs, theme choice; sb-menu.js, sb-tree.js, sb-search.js,
// sb-tone.js, sb-controls.js: dialogs, switches, motion setting). This module runs before them (a module script in the
// head, the sebaro scripts deferred at the end of the body), draws the tree, the tabs and the inspector from the demo
// notes, and answers the events the sebaro scripts fire. No style attribute, no inline handler (CSP).
import { t, demoNotes, folders, type Note } from "./strings";
import { reportAppearance, setWindowTitle } from "./tauri-bridge";

const SVG = "http://www.w3.org/2000/svg";
const notes: Note[] = demoNotes.map((n) => ({ ...n, paragraphs: [...n.paragraphs] }));
const openIds: string[] = ["wochenplan", "einkauf"];
let currentId: string | null = "wochenplan";
let newCount = 0;
/** what the tree chose in the bin: "bin" (its row), the id of a note in it, or null (the inspector shows the open note) */
let binChoice: string | null = null;
const TEXT_STEPS = [0.875, 1, 1.125, 1.25, 1.5];   // ⌘+ / ⌘− change only the content's text (DSK-09)
let textStep = 1;

const $ = <T extends HTMLElement = HTMLElement>(id: string) => document.getElementById(id) as T;
const nf = new Intl.NumberFormat(document.documentElement.lang || "de");
const dateFmt = new Intl.DateTimeFormat(document.documentElement.lang || "de", { day: "2-digit", month: "2-digit", year: "numeric" });
const timeFmt = new Intl.DateTimeFormat(document.documentElement.lang || "de", { hour: "2-digit", minute: "2-digit" });

function isMac(): boolean {
  const p = document.documentElement.getAttribute("data-sb-platform");
  if (p) return p === "mac";
  return /mac|iphone|ipad/i.test(navigator.platform || navigator.userAgent);
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, attrs: Record<string, string> = {}, ...kids: Array<Node | string>): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  node.append(...kids);
  return node;
}
function icon(name: string, cls = ""): SVGSVGElement {
  const svg = document.createElementNS(SVG, "svg");
  svg.setAttribute("class", `sb-icon${cls ? " " + cls : ""}`);
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  const use = document.createElementNS(SVG, "use");
  use.setAttribute("href", `#${name}`);
  svg.append(use);
  return svg;
}
function note(id: string | null): Note | undefined { return notes.find((n) => n.id === id); }
function binned(): Note[] { return notes.filter((n) => n.trashed); }
function folderName(n: Note): string | undefined { return folders.find((f) => f.id === n.folder)?.name; }
function words(n: Note): number { return n.paragraphs.join(" ").split(/\s+/).filter(Boolean).length; }
function chars(n: Note): number { return n.paragraphs.join("\n").length; }
function changedText(n: Note): string {
  const d = new Date(n.changed);
  return `${dateFmt.format(d)}, ${timeFmt.format(d)}`;
}

// ------------------------------------------------------------------ tree (NAV-11, STA-08)
function noteRow(n: Note, level: number): HTMLLIElement {
  const row = el("div", {
    class: "sb-row sb-tree__row", role: "treeitem", "aria-level": String(level),
    "aria-selected": String(n.id === currentId), tabindex: n.id === currentId ? "0" : "-1", "data-note": n.id, title: n.name,
  }, el("span", { class: "sb-tree__twist", "aria-hidden": "true" }), icon("file-text", "sb-row__icon"), el("span", { class: "sb-row__name" }, n.name));
  if (n.unsaved) row.append(el("span", { class: "sb-row__meta" }, el("span", { class: "sb-status sb-status--warning" }, icon("warning--16", "sb-icon--16"), t("status.unsaved"))));
  else if (n.online) row.append(el("span", { class: "sb-row__meta" }, el("span", { class: "sb-status sb-status--neutral" }, icon("info--16", "sb-icon--16"), t("status.online"))));
  return el("li", { role: "none" }, row);
}
function drawTree(): void {
  const tree = $("baum");
  const open = new Map<string, boolean>();
  tree.querySelectorAll<HTMLElement>("[data-folder]").forEach((r) => open.set(r.dataset.folder!, r.getAttribute("aria-expanded") === "true"));
  const binWasOpen = tree.querySelector("[data-bin]")?.getAttribute("aria-expanded") === "true";
  tree.replaceChildren();
  for (const f of folders) {
    const isOpen = open.get(f.id) ?? f.open;
    const group = el("ul", { class: "sb-tree__group", role: "group", id: `gruppe-${f.id}` });
    group.hidden = !isOpen;
    for (const n of notes.filter((x) => x.folder === f.id && !x.trashed)) group.append(noteRow(n, 2));
    const row = el("div", {
      class: "sb-row sb-tree__row", role: "treeitem", "aria-level": "1", "aria-expanded": String(isOpen),
      "aria-owns": group.id, "aria-selected": "false", tabindex: "-1", "data-folder": f.id,
    }, el("span", { class: "sb-tree__twist", "aria-hidden": "true" }, icon("chevron-right--16", "sb-icon--16")), icon("folder", "sb-row__icon"), el("span", { class: "sb-row__name" }, f.name));
    tree.append(el("li", { role: "none" }, row, group));
  }
  for (const n of notes.filter((x) => x.folder === null && !x.trashed)) tree.append(noteRow(n, 1));
  // the bin takes nothing by dragging (DSK-11); it goes through the dialog. With notes in it, it opens like a folder and
  // lists them; choosing one shows „Zurücklegen“ in the inspector and the menu
  const inBin = binned();
  const binRow = el("div", {
    class: "sb-row sb-tree__row", role: "treeitem", "aria-level": "1", "aria-selected": String(binChoice === "bin"), tabindex: "-1",
    "data-sb-drop": "none", "data-bin": "", title: t("side.trashTitle"),
  }, el("span", { class: "sb-tree__twist", "aria-hidden": "true" }, ...(inBin.length ? [icon("chevron-right--16", "sb-icon--16")] : [])),
  icon("trash", "sb-row__icon"), el("span", { class: "sb-row__name" }, t("side.trash")));
  const binItem = el("li", { role: "none" }, binRow);
  if (inBin.length) {
    const group = el("ul", { class: "sb-tree__group", role: "group", id: "gruppe-papierkorb" });
    group.hidden = !binWasOpen;
    binRow.setAttribute("aria-expanded", String(binWasOpen));
    binRow.setAttribute("aria-owns", group.id);
    for (const n of inBin) {
      group.append(el("li", { role: "none" }, el("div", {
        class: "sb-row sb-tree__row", role: "treeitem", "aria-level": "2", "aria-selected": String(binChoice === n.id),
        tabindex: "-1", "data-trashed": n.id, title: n.name,
      }, el("span", { class: "sb-tree__twist", "aria-hidden": "true" }), icon("file-text", "sb-row__icon"), el("span", { class: "sb-row__name" }, n.name))));
    }
    binItem.append(group);
  }
  tree.append(binItem);
  if (!tree.querySelector("[tabindex='0']")) tree.querySelector("[role='treeitem']")?.setAttribute("tabindex", "0");
  filterTree();
}
function filterTree(): void {
  const q = $<HTMLInputElement>("suche").value.trim().toLowerCase();
  let hits = 0;
  $("baum").querySelectorAll<HTMLElement>("[data-note]").forEach((row) => {
    const hit = !q || (row.textContent ?? "").toLowerCase().includes(q);
    row.parentElement!.hidden = !hit;
    if (hit) hits++;
  });
  $("baum").querySelectorAll<HTMLElement>("[data-folder]").forEach((row) => {
    const group = document.getElementById(row.getAttribute("aria-owns") ?? "");
    const any = !!group?.querySelector("li:not([hidden]) [data-note]");
    row.parentElement!.hidden = !!q && !any;
    if (q && any && group) { group.hidden = false; row.setAttribute("aria-expanded", "true"); }
  });
  const none = $("baum-leer");
  none.textContent = q && !hits ? t("side.noMatch", { q: $<HTMLInputElement>("suche").value.trim() }) : "";
}

// ------------------------------------------------------------------ document tabs (DSK-10)
function tabFor(id: string): HTMLButtonElement | null { return document.getElementById(`reiter-${id}`) as HTMLButtonElement | null; }
function makeTab(n: Note, selected: boolean): { item: HTMLSpanElement; panel: HTMLDivElement } {
  const tab = el("button", {
    class: "sb-doc-tabs__tab", type: "button", role: "tab", id: `reiter-${n.id}`, "aria-selected": String(selected),
    "aria-controls": `tafel-${n.id}`, "aria-keyshortcuts": isMac() ? "Meta+W Delete" : "Control+W Delete",
    tabindex: selected ? "0" : "-1", title: n.name,
  });
  if (n.unsaved) tab.append(icon("changed--16", "sb-icon--16 sb-doc-tabs__mark"));
  tab.append(icon("file-text", "sb-icon--16"), n.name);
  if (n.unsaved) tab.append(el("span", { class: "sb-visually-hidden" }, t("tabs.changed")));
  const close = el("span", { class: "sb-doc-tabs__close", "aria-hidden": "true", title: t("tabs.close") }, icon("close--16", "sb-icon--16"));
  const item = el("span", { class: "sb-doc-tabs__item", role: "presentation" }, tab, close);
  const meta = el("p", { class: "sb-window__meta" },
    t("doc.meta", { folder: folders.find((f) => f.id === n.folder)?.name ?? t("insp.noFolder"), when: changedText(n) }), " · ",
    el("span", { class: "sb-demo-marker" }, t("app.demo")));
  const prose = el("div", { class: "sb-prose app-doc" }, ...(n.paragraphs.length ? n.paragraphs : [t("doc.empty")]).map((p) => el("p", {}, p)));
  const panel = el("div", { class: "sb-doc-tabs__panel", role: "tabpanel", id: `tafel-${n.id}`, "aria-labelledby": `reiter-${n.id}`, tabindex: "0" },
    el("h1", { class: "sb-window__heading" }, n.name), meta, prose);
  panel.hidden = !selected;
  return { item, panel };
}
function drawTabs(): void {
  const list = $("reiter");
  const content = $("inhalt");
  list.replaceChildren();
  content.querySelectorAll(".sb-doc-tabs__panel").forEach((p) => p.remove());
  for (const id of openIds) {
    const n = note(id);
    if (!n) continue;
    const { item, panel } = makeTab(n, id === currentId);
    list.append(item);
    content.append(panel);
  }
  list.hidden = openIds.length === 0;
  (content.querySelector(".sb-doc-tabs__none") as HTMLElement).hidden = openIds.length > 0;
}
function selectTab(id: string, focus: boolean): void {
  const list = $("reiter");
  list.querySelectorAll<HTMLButtonElement>("[role='tab']").forEach((tab) => {
    const on = tab.id === `reiter-${id}`;
    tab.setAttribute("aria-selected", String(on));
    tab.tabIndex = on ? 0 : -1;
    const panel = document.getElementById(tab.getAttribute("aria-controls") ?? "");
    if (panel) panel.hidden = !on;
    if (on) { tab.scrollIntoView({ block: "nearest", inline: "nearest" }); if (focus) tab.focus(); }
  });
  current(id);
}
function openNote(id: string, focusTab = false): void {
  if (!openIds.includes(id)) {
    openIds.push(id);
    const n = note(id)!;
    const { item, panel } = makeTab(n, false);
    $("reiter").append(item);
    $("inhalt").append(panel);
    $("reiter").hidden = false;
    ($("inhalt").querySelector(".sb-doc-tabs__none") as HTMLElement).hidden = true;
  }
  selectTab(id, focusTab);
}

// ------------------------------------------------------------------ the current note: path, inspector, zone, title
function current(id: string | null): void {
  currentId = id;
  const n = note(id);
  $("pfad-notiz").textContent = n ? n.name : "";
  $("baum").querySelectorAll<HTMLElement>("[data-note]").forEach((row) => row.setAttribute("aria-selected", String(binChoice === null && row.dataset.note === id)));
  if (binChoice === null) $("baum").querySelectorAll<HTMLElement>("[data-bin], [data-trashed]").forEach((row) => row.setAttribute("aria-selected", "false"));
  inspect();
  zone();
  const title = n ? t("app.title", { doc: n.name }) : t("app.name");
  if (location.hash !== "#/einstellungen") { document.title = title; setWindowTitle(title); }
  $("zurueck-wort").textContent = t("set.back", { doc: n ? n.name : t("app.name") });
  menuState();
}
function pair(label: string, value: Node | string, num = false): HTMLDivElement {
  return el("div", {}, el("dt", {}, label), el("dd", num ? { class: "sb-num" } : {}, value));
}
/** The inspector: the note chosen in the bin, the bin itself, or else the open note. */
function inspect(): void {
  const dl = $("eigenschaften");
  dl.replaceChildren();
  const actions = $("papierkorb-aktionen");
  actions.hidden = binChoice === null;
  if (binChoice === "bin") {
    const count = binned().length;
    dl.append(pair(t("insp.bin"), count === 0 ? t("insp.binEmpty") : count === 1 ? t("insp.binOne") : t("insp.binNotes", { n: nf.format(count) })));
    $("zuruecklegen").hidden = true;
    $("leeren").hidden = count === 0;
    actions.hidden = count === 0;
    return;
  }
  const inBin = note(binChoice);
  if (inBin) {
    dl.append(
      pair(t("insp.from"), folderName(inBin) ?? t("insp.fromRoot")),
      pair(t("insp.changed"), el("time", { datetime: inBin.changed }, changedText(inBin))),
      pair(t("insp.words"), nf.format(words(inBin)), true),
    );
    $("zuruecklegen").hidden = false;
    $("leeren").hidden = true;
    return;
  }
  const n = note(currentId);
  if (n) {
    const created = new Date(n.created);
    dl.append(
      pair(t("insp.folder"), folders.find((f) => f.id === n.folder)?.name ?? t("insp.noFolder")),
      pair(t("insp.created"), el("time", { datetime: n.created }, dateFmt.format(created))),
      pair(t("insp.changed"), el("time", { datetime: n.changed }, changedText(n))),
      pair(t("insp.words"), nf.format(words(n)), true),
      pair(t("insp.size"), t("doc.size", { n: nf.format(Math.max(1, Math.ceil(chars(n) / 1024))) }), true),
    );
  } else dl.append(el("div", {}, el("dt", {}, t("insp.label")), el("dd", {}, t("insp.empty"))));
}
/** DSK-08: an item without a target is disabled, never hidden. */
function menuState(): void {
  const able = (id: string, on: boolean) => { if (on) $(id).removeAttribute("aria-disabled"); else $(id).setAttribute("aria-disabled", "true"); };
  able("menue-papierkorb", !!note(currentId));
  able("menue-zuruecklegen", !!note(binChoice)?.trashed);
  able("menue-leeren", binned().length > 0);
}
function chooseInBin(choice: string | null): void {
  binChoice = choice;
  inspect();
  menuState();
}
function zone(): void {
  const n = note(currentId);
  const counts = $("zaehler");
  // the counter line keeps its place (STA-07): with nothing open it holds the last parts invisibly (data-sb-held)
  if (n) {
    counts.removeAttribute("data-sb-held");
    counts.replaceChildren(el("span", {}, t("zone.words", { n: nf.format(words(n)) })), el("span", { class: "sb-visually-hidden" }, " · "),
      el("span", {}, t("zone.chars", { n: nf.format(chars(n)) })));
  } else counts.setAttribute("data-sb-held", "");
  const unsaved = notes.filter((x) => x.unsaved).length;
  $("stand").textContent = unsaved === 0 ? t("zone.saved") : unsaved === 1 ? t("zone.unsavedOne") : t("zone.unsavedMany", { n: unsaved });
}

// ------------------------------------------------------------------ commands
function newNote(): void {
  newCount++;
  const now = new Date();
  const iso = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
  const time = `${iso}T${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
  const n: Note = { id: `neu-${newCount}`, name: t("zone.newNoteName", { n: newCount }), folder: "projekte", created: iso, changed: time, paragraphs: [] };
  notes.push(n);
  currentId = n.id;
  drawTree();
  // new content enters from below (BEW-02); an instant local result shows no check (AKT-05)
  $("baum").querySelector(`[data-note="${n.id}"]`)?.classList.add("sb-enter");
  openNote(n.id, true);
}
function closeCurrentTab(): void {
  const tab = currentId ? tabFor(currentId) : null;
  // sb-window.js closes a tab on Entf / ⌘W while the tab has focus; from the menu the app sends the same key
  if (tab) tab.dispatchEvent(new KeyboardEvent("keydown", { key: "Delete", bubbles: true, cancelable: true }));
}
function goSettings(): void { location.hash = "#/einstellungen"; }
function focusSearch(): void {
  const input = $<HTMLInputElement>("suche");
  if ($("seite").hidden) $("werkzeug-seite").click();
  input.focus();
  input.select();
}
function setTextStep(step: number): void {
  textStep = Math.max(0, Math.min(TEXT_STEPS.length - 1, step));
  // through the CSSOM: no style attribute in the markup, so the CSP holds
  $("inhalt").style.setProperty("--app-doc-scale", String(TEXT_STEPS[textStep]));
}
function runCommand(command: string | undefined): void {
  switch (command) {
    case "new-note": $("neue-notiz").click(); break;
    case "close-tab": closeCurrentTab(); break;
    case "find": focusSearch(); break;
    case "settings": goSettings(); break;
    case "text-bigger": setTextStep(textStep + 1); break;
    case "text-smaller": setTextStep(textStep - 1); break;
    case "restore": restore(); break;
  }
}

// ------------------------------------------------------------------ dialogs
let closing: HTMLButtonElement | null = null;
function openTrashDialog(): void {
  const n = note(currentId);
  if (!n) return;
  $("dlg-papierkorb-t").textContent = t("dlg.trashTitle", { name: n.name });
  $("dlg-papierkorb-x").textContent = t("dlg.trashText", { name: n.name });
}
function message(text: string): void {
  ($("haupt").querySelector(".sb-primary-action-bar__message") as HTMLElement).textContent = text;
}
/** Into the bin: the note leaves its folder and its tab, and comes back with „Zurücklegen“. */
function trash(id: string): void {
  const n = note(id);
  if (!n || n.trashed) return;
  const name = n.name;
  n.trashed = true;
  const at = openIds.indexOf(id);
  if (at >= 0) openIds.splice(at, 1);
  currentId = openIds[Math.min(at, openIds.length - 1)] ?? null;
  drawTree();
  drawTabs();
  current(currentId);
  message(t("zone.trashed", { name }));
}
/** „Zurücklegen“: the chosen note goes back into the folder it came from; it does not open on its own. */
function restore(): void {
  const n = note(binChoice);
  if (!n?.trashed) return;
  n.trashed = false;
  binChoice = binned().length ? "bin" : null;
  drawTree();
  current(currentId);
  const folder = folderName(n);
  message(folder ? t("zone.restored", { name: n.name, folder }) : t("zone.restoredRoot", { name: n.name }));
  $<HTMLElement>("baum").querySelector<HTMLElement>(`[data-note="${n.id}"]`)?.focus();
}
function openEmptyDialog(): void {
  const inBin = binned();
  $("dlg-leeren-x").textContent = inBin.length === 1 ? t("dlg.emptyTextOne", { name: inBin[0].name }) : t("dlg.emptyTextMany", { n: nf.format(inBin.length) });
}
/** „Papierkorb leeren“: every note in the bin is gone for good (the dialog said so). */
function emptyBin(): void {
  for (let i = notes.length - 1; i >= 0; i--) if (notes[i].trashed) notes.splice(i, 1);
  binChoice = null;
  drawTree();
  current(currentId);
  message(t("zone.emptied"));
  $<HTMLElement>("baum").querySelector<HTMLElement>("[data-bin]")?.focus();
}

// ------------------------------------------------------------------ settings view (DSK-02) and the window's place
function route(moveFocus: boolean): void {
  const settings = location.hash === "#/einstellungen";
  const main = $("haupt"), view = $("einstellungen");
  // the wrappers hide a view: sebaro.css gives .sb-window its own display, which would outweigh [hidden] on it
  $("ansicht-haupt").hidden = settings;
  $("ansicht-einstellungen").hidden = !settings;
  // only the window on screen fills it: sb-window.js takes the one sb-window--fill when focus is on the page
  main.classList.toggle("sb-window--fill", !settings);
  view.classList.toggle("sb-window--fill", settings);
  const n = note(currentId);
  const title = settings ? t("app.titleSettings") : (n ? t("app.title", { doc: n.name }) : t("app.name"));
  document.title = title;
  setWindowTitle(title);
  if (!moveFocus) return;
  if (settings) $("einstellungen-h").focus();
  else $("zu-einstellungen").focus();
}

function init(): void {
  try { if (localStorage.getItem("app-autosave") === "on") $("autosave").setAttribute("aria-checked", "true"); } catch { /* storage off: the default */ }
  drawTree();
  drawTabs();
  current(currentId);
  route(false);
  window.addEventListener("hashchange", () => route(true));

  $<HTMLInputElement>("suche").addEventListener("input", filterTree);
  $("neue-notiz").addEventListener("click", newNote);
  document.addEventListener("click", (event) => {
    const target = event.target instanceof Element ? event.target.closest<HTMLElement>("[data-app-command]") : null;
    if (target && target.getAttribute("aria-disabled") !== "true") runCommand(target.dataset.appCommand);
    if (event.target instanceof Element && event.target.closest("[data-sb-opens='dlg-papierkorb']")) openTrashDialog();
    if (event.target instanceof Element && event.target.closest("[data-sb-opens='dlg-leeren']")) openEmptyDialog();
  }, true);
  // back in the document: the inspector shows the open note again
  $("inhalt").addEventListener("focusin", () => { if (binChoice !== null) { binChoice = null; current(currentId); } });
  document.addEventListener("sb-command", (event) => runCommand((event as CustomEvent).detail?.command));
  document.addEventListener("sb-tree-select", (event) => {
    const item = (event as CustomEvent).detail?.item as HTMLElement | undefined;
    if (item?.dataset.note) { binChoice = null; openNote(item.dataset.note); }
    else if (item?.hasAttribute("data-bin")) chooseInBin("bin");
    else if (item?.dataset.trashed) chooseInBin(item.dataset.trashed);
  });
  // a tab chosen by click or keys (sb-window.js keeps aria-selected): follow it
  new MutationObserver(() => {
    const sel = $("reiter").querySelector<HTMLElement>("[role='tab'][aria-selected='true']");
    const id = sel ? sel.id.replace(/^reiter-/, "") : null;
    for (let i = openIds.length - 1; i >= 0; i--) if (!tabFor(openIds[i])) openIds.splice(i, 1);
    if (id !== currentId) { binChoice = null; current(id); }
  }).observe($("reiter"), { subtree: true, childList: true, attributes: true, attributeFilter: ["aria-selected"] });

  // AKT-11: a tab with unsaved changes asks before it closes, unless the app saves on its own (the setting)
  document.addEventListener("sb-doc-tab-close", (event) => {
    const tab = (event as CustomEvent).detail?.tab as HTMLButtonElement;
    const n = note(tab.id.replace(/^reiter-/, ""));
    if (!n?.unsaved || tab.dataset.appClosing) return;
    if ($("autosave").getAttribute("aria-checked") === "true") { n.unsaved = false; drawTree(); zone(); return; }
    event.preventDefault();
    closing = tab;
    $("dlg-ungesichert-t").textContent = t("dlg.unsavedTitle", { name: n.name });
    $("dlg-ungesichert-x").textContent = t("dlg.unsavedText", { time: timeFmt.format(new Date(n.changed)) });
    $<HTMLDialogElement>("dlg-ungesichert").showModal();
  });
  $<HTMLDialogElement>("dlg-ungesichert").addEventListener("close", () => {
    const dlg = $<HTMLDialogElement>("dlg-ungesichert");
    // the close event comes a task later: if the dialog was opened again in between, this one is stale
    if (dlg.open) return;
    const tab = closing;
    closing = null;
    if (!tab) return;
    if (dlg.returnValue !== "discard" && dlg.returnValue !== "save") { tab.focus(); return; }
    const n = note(tab.id.replace(/^reiter-/, ""));
    if (n) n.unsaved = false;   // saved, or the changes are gone: the note itself stays
    tab.dataset.appClosing = "1";
    tab.focus();
    tab.dispatchEvent(new KeyboardEvent("keydown", { key: "Delete", bubbles: true, cancelable: true }));
    drawTree();
    zone();
  });
  $<HTMLDialogElement>("dlg-papierkorb").addEventListener("close", () => {
    if ($<HTMLDialogElement>("dlg-papierkorb").returnValue === "confirm" && currentId) trash(currentId);
  });
  $<HTMLDialogElement>("dlg-leeren").addEventListener("close", () => {
    if ($<HTMLDialogElement>("dlg-leeren").returnValue === "confirm" && binned().length) emptyBin();
  });
  $("autosave").addEventListener("click", () => {
    // sb-controls.js turns aria-checked over on the click; read it after that
    setTimeout(() => {
      try { localStorage.setItem("app-autosave", $("autosave").getAttribute("aria-checked") === "true" ? "on" : "off"); } catch { /* not stored */ }
    }, 0);
  });

  // ZUG-09: sb-fit.js measured the page at load; a dialog that opens later is measured again, so a word that alone
  // does not fit its line in the dialog gets its hyphen
  const fit = (window as unknown as { sbFit?: { refresh: (el?: Element) => void } });
  document.querySelectorAll("dialog").forEach((dlg) => {
    new MutationObserver(() => { if (dlg.open) fit.sbFit?.refresh(dlg); }).observe(dlg, { attributes: true, attributeFilter: ["open"] });
  });

  // DSK-14: tell the Rust side the choice, so it sets the window ground and the system theme of every window
  const report = () => {
    const theme = document.documentElement.dataset.theme === "light" || document.documentElement.dataset.theme === "dark" ? document.documentElement.dataset.theme : "system";
    reportAppearance(theme, document.documentElement.dataset.sbTone === "warm" ? "warm" : "cool");
  };
  document.addEventListener("sb-theme-change", report);
  document.addEventListener("sb-tone-change", report);
}

init();
