// main.ts: the shell of Musterapp, a web app without a window (NAV-06, WEB-03, WEB-10): site header with
// „Einstellungen“, DE / EN and „Hell oder Dunkel“, one view at a time by hash route, the footer with the required links.
// sebaro's own scripts (public/sebaro/js/*.js) do the behaviour of the parts: dialogs, chips, switch, tone, language,
// toasts, tabs, tree, sortable tables, calendar, heatmap and large text. This file only renders and routes.
import { html, icon, raw, type Html } from "./html";
import { currentLang, t } from "./strings";
import { load, save, type Entry } from "./store";
import { listView, bindList } from "./views/list";
import { detailView, bindDetail } from "./views/detail";
import { formView, bindForm, formIsDirty, askBeforeLeaving } from "./views/form";
import { settingsView, bindSettings } from "./views/settings";
import { dataView, bindData } from "./views/data";
import { legalView, notFoundView } from "./views/legal";

declare global {
  interface Window {
    sbToast?: { show(el: Element): void; hide(el: Element): void };
    sbCalendar?: { render(root: Element): void };
    sbSticky?: { watch(head: Element): void };
    sbFit?: { refresh(el?: Element | null): void };
  }
}

export type Route =
  | { name: "list" }
  | { name: "detail"; id: string }
  | { name: "new" }
  | { name: "edit"; id: string }
  | { name: "settings" }
  | { name: "data" }
  | { name: "legal"; page: "impressum" | "datenschutz" | "barrierefreiheit" }
  | { name: "notFound" };

export const app = {
  entries: [] as Entry[],
  route: { name: "list" } as Route,
  persist(): void {
    save(this.entries);
  },
};

function parse(hash: string): Route {
  const path = hash.replace(/^#\/?/, "");
  const [head, arg] = path.split("/");
  if (head === "" || head === undefined) return { name: "list" };
  if (head === "eintrag" && arg) return { name: "detail", id: arg };
  if (head === "neu") return { name: "new" };
  if (head === "bearbeiten" && arg) return { name: "edit", id: arg };
  if (head === "einstellungen") return { name: "settings" };
  if (head === "daten") return { name: "data" };
  if (head === "impressum" || head === "datenschutz" || head === "barrierefreiheit") return { name: "legal", page: head };
  return { name: "notFound" };
}

function header(): Html {
  const s = t();
  const lang = currentLang();
  const tile = document.getElementById("app-tile") as HTMLTemplateElement | null;
  const onSettings = app.route.name === "settings";
  return html`<header class="sb-site-header">
  <a class="sb-lockup" href="#/"><span class="sb-sign-tile sb-sign-tile--32" aria-hidden="true">${raw(tile ? tile.innerHTML : "")}</span><span class="sb-wordmark" translate="no">${s.app.name}</span></a>
  <div class="sb-site-header__links">
    <nav class="sb-site-nav" aria-label="${s.header.navLabel}"><a href="#/einstellungen"${raw(onSettings ? ' aria-current="page"' : "")}>${s.header.settings}</a></nav>
    <fieldset class="sb-language-switch sb-language-switch--choice" data-sb-language-choice>
      <legend class="sb-visually-hidden">${s.header.language}</legend>
      <label class="sb-language-switch__option"><input type="radio" name="app-lang" value="de"${raw(lang === "de" ? " checked" : "")}><span lang="de">DE</span></label>
      <span aria-hidden="true">/</span>
      <label class="sb-language-switch__option"><input type="radio" name="app-lang" value="en"${raw(lang === "en" ? " checked" : "")}><span lang="en">EN</span></label>
    </fieldset>
  </div>
  <button class="sb-theme-button" type="button">${s.header.theme}</button>
</header>`;
}

function footer(): Html {
  const s = t().footer;
  return html`<footer class="sb-site-footer">
  <p>${s.copyright}</p>
  <ul class="sb-site-footer__links" aria-label="${s.linksLabel}">
    <li><a href="#/impressum">${s.imprint}</a></li>
    <li><a href="#/datenschutz">${s.privacy}</a></li>
    <li><a href="#/barrierefreiheit">${s.accessibility}</a></li>
    <li><a href="https://github.com/" title="${s.githubTitle}">${s.github}${icon("external-link--16", 16)}</a></li>
  </ul>
</footer>`;
}

function view(): { markup: Html; title: string } {
  const s = t();
  const r = app.route;
  switch (r.name) {
    case "list": return { markup: listView(), title: s.list.title };
    case "detail": return detailView(r.id);
    case "new": return { markup: formView(null), title: s.form.titleNew };
    case "edit": return { markup: formView(r.id), title: s.form.titleEdit };
    case "settings": return { markup: settingsView(), title: s.settings.title };
    case "data": return { markup: dataView(), title: s.data.title };
    case "legal": return legalView(r.page);
    default: return { markup: notFoundView(), title: s.notFound.title };
  }
}

/** The parts sebaro's scripts set up once at load; after a view is replaced, set up the new ones the same way. */
function setUpSebaroParts(root: Element): void {
  root.querySelectorAll("[data-sb-calendar]").forEach((c) => window.sbCalendar?.render(c));
  root.querySelectorAll(".sb-list-header--sticky").forEach((h) => window.sbSticky?.watch(h));
  // sb-chart.js init: one Tab stop in each heatmap (today, else the last day with a value) and the read-out's hint
  root.querySelectorAll<HTMLTableElement>("table.sb-heatmap").forEach((table) => {
    const days = Array.from(table.querySelectorAll<HTMLTableCellElement>("tbody td")).filter((td) => td.querySelector(".sb-visually-hidden"));
    if (!days.length) return;
    table.setAttribute("role", "grid");
    const start = days.find((td) => td.getAttribute("aria-current") === "date") ?? days[days.length - 1];
    days.forEach((td) => (td.tabIndex = td === start ? 0 : -1));
    const out = table.closest("figure")?.querySelector<HTMLElement & { sbHint?: string }>(".sb-chart__readout");
    if (out) {
      out.sbHint = out.textContent ?? "";
      out.hidden = false;
    }
  });
  window.sbFit?.refresh(root);
}

let firstRender = true;

export function render(focusMain = true): void {
  const root = document.getElementById("app");
  if (!root) return;
  const v = view();
  root.innerHTML = html`<a class="sb-skip-link" href="#inhalt" data-app-skip>${t().app.skip}</a>
${header()}
<main id="inhalt" tabindex="-1">${v.markup}</main>
${footer()}
<div class="sb-note-popover" id="sb-note-popover" popover aria-labelledby="sb-note-popover-claim"><p class="sb-note-popover__claim" id="sb-note-popover-claim"></p><div class="sb-note-popover__body"></div><button class="sb-secondary-action sb-note-popover__close" type="button" popovertarget="sb-note-popover" popovertargetaction="hide">${t().common.close}</button></div>
<div class="app-toast-place"><div class="sb-toast" id="app-toast" role="status" hidden><p></p><button class="sb-toast__action" type="button">${t().common.undo}</button></div></div>`.value;
  document.title = t().app.title(v.title);
  setUpSebaroParts(root);
  bindView();
  // a new view: focus its heading, so keyboard and screen reader users start where the content starts (ZUG-06);
  // not on the first load, where focus belongs to the browser
  if (focusMain && !firstRender) {
    const h1 = root.querySelector<HTMLElement>("main h1");
    if (h1) {
      h1.tabIndex = -1;
      h1.focus();
    }
  }
  firstRender = false;
}

function bindView(): void {
  const r = app.route;
  if (r.name === "list") bindList();
  if (r.name === "detail") bindDetail(r.id);
  if (r.name === "new") bindForm(null);
  if (r.name === "edit") bindForm(r.id);
  if (r.name === "settings") bindSettings();
  if (r.name === "data") bindData();
}

/** The one toast of the app (EBE-05): a sentence and an optional „Rückgängig“. */
export function toast(sentence: string, undo?: () => void): void {
  const el = document.getElementById("app-toast");
  if (!el || !window.sbToast) return;
  const p = el.querySelector("p");
  if (p) p.textContent = sentence;
  const action = el.querySelector<HTMLButtonElement>(".sb-toast__action");
  if (action) action.hidden = !undo;
  pendingUndo = undo ?? null;
  window.sbToast.show(el);
}
let pendingUndo: (() => void) | null = null;

export function go(hash: string): void {
  if (location.hash === hash) {
    app.route = parse(hash);
    render();
  } else {
    location.hash = hash;
  }
}

function onHash(): void {
  // in-page anchors (footnotes, contents) are no routes: the view stays
  if (!location.hash.startsWith("#/") && location.hash !== "") return;
  app.route = parse(location.hash);
  render();
}

function start(): void {
  app.entries = load(currentLang());
  app.route = location.hash.startsWith("#/") ? parse(location.hash) : { name: "list" };
  render(false);
  window.addEventListener("hashchange", onHash);

  // the skip link focuses the content without changing the route
  document.addEventListener("click", (event) => {
    const target = event.target as Element;
    if (target.closest("[data-app-skip]")) {
      event.preventDefault();
      document.getElementById("inhalt")?.focus();
    }
    // with unsaved changes in the form, leaving asks first (AKT-11)
    const link = target.closest<HTMLAnchorElement>('a[href^="#/"]');
    if (link && formIsDirty() && !link.closest("form")) {
      event.preventDefault();
      askBeforeLeaving(link.getAttribute("href") ?? "#/");
    }
  });

  // „Rückgängig“ of the toast (sb-controls.js fires sb-toast-action, then closes the toast)
  document.addEventListener("sb-toast-action", () => {
    const undo = pendingUndo;
    pendingUndo = null;
    if (undo) undo();
  });

  // DE / EN: sb-controls.js has set <html lang> and stored it; the app swaps its words without a reload (D102 (50))
  document.addEventListener("sb-language-change", () => {
    render(false);
    document.querySelector<HTMLInputElement>(`[data-sb-language-choice] input[value="${currentLang()}"]`)?.focus();
  });
}

// sebaro's classic scripts are deferred; DOMContentLoaded fires after all of them, so their APIs exist here
document.addEventListener("DOMContentLoaded", start);
