// list.ts: „Einträge“, the list with search, filter chips and empty states (DAT-01, DAT-02, DAT-07, EIN-04, EIN-05,
// STA-07, AKT-01, BEL-10). The primary action „Neuer Eintrag“ sits in the action zone at the bottom of the view.
import { html, icon, type Html } from "../html";
import { app } from "../main";
import { t, currentLang } from "../strings";
import * as fmt from "../format";
import type { Category, Entry } from "../store";

export const CATEGORY_TONE: Record<Category, number> = { none: 0, home: 1, work: 2, garden: 3, health: 4 };

export function categoryWord(c: Category): Html {
  const word = t().categories[c];
  if (c === "none") return html``;
  return html`<span class="sb-category sb-category--${CATEGORY_TONE[c]}">${word}</span>`;
}

type Filter = "all" | "open" | "done";
let query = "";
let filter: Filter = "all";

function meta(e: Entry): Html {
  const s = t();
  const lang = currentLang();
  const parts: Html[] = [];
  if (e.category !== "none") parts.push(categoryWord(e.category));
  if (e.due) parts.push(html`<time datetime="${e.due}">${s.list.due(fmt.date(lang, e.due))}</time>`);
  parts.push(html`${fmt.unit(lang, e.effort, s.common.minutes)}`);
  return html`${parts.map((p, i) => html`${i ? " · " : ""}${p}`)}`;
}

function row(e: Entry): Html {
  const s = t();
  if (e.state === "open") {
    return html`<li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title"><a class="sb-list-row__link" href="#/eintrag/${e.id}">${e.title}</a></p><p class="sb-list-row__meta">${meta(e)}</p></div><span class="sb-list-row__trail">${icon("chevron-right")}</span></li>`;
  }
  const word = e.state === "closed" ? s.status.closed : s.status.done;
  return html`<li class="sb-list-row sb-list-row--done"><span class="sb-list-row__lead">${icon("success--filled-16", 16)}</span><div class="sb-list-row__main"><p class="sb-list-row__title"><a class="sb-list-row__link" href="#/eintrag/${e.id}"><span class="sb-visually-hidden">${word}: </span>${e.title}</a></p></div><span class="sb-list-row__trail">${icon("chevron-right")}</span></li>`;
}

function matches(e: Entry): boolean {
  if (filter === "open" && e.state !== "open") return false;
  if (filter === "done" && e.state === "open") return false;
  return !query || e.title.toLocaleLowerCase().includes(query.toLocaleLowerCase());
}

function results(): Html {
  const s = t();
  const all = app.entries;
  if (!all.length) {
    return html`<div class="sb-empty sb-empty--section"><p class="sb-empty__title">${s.list.emptyTitle}</p><p class="sb-empty__text">${s.list.emptyText}</p></div>`;
  }
  const shown = all.filter(matches);
  const open = shown.filter((e) => e.state === "open");
  const done = shown.filter((e) => e.state !== "open");
  const count = html`<p class="sb-list-row__meta" role="status">${shown.length ? s.list.count(shown.length) : s.list.countNone}</p>`;
  if (!shown.length) {
    return html`${count}<div class="sb-empty sb-empty--section"><p class="sb-empty__title">${s.list.emptyFilterTitle}</p><p class="sb-empty__text">${s.list.emptyFilterText}</p><button class="sb-text-action" type="button" data-app-reset-filter>${s.list.emptyFilterReset}</button></div>`;
  }
  return html`${count}
${open.length ? html`<h2 class="sb-list-header" id="app-h-open">${s.list.headerOpen} <span class="sb-list-header__count">${open.length}</span></h2><ul class="sb-list" aria-labelledby="app-h-open">${open.map(row)}</ul>` : ""}
${done.length ? html`<h2 class="sb-list-header" id="app-h-done">${s.list.headerDone} <span class="sb-list-header__count">${done.length}</span></h2><ul class="sb-list" aria-labelledby="app-h-done">${done.map(row)}</ul>` : ""}
<p class="sb-list-end">${s.list.end}</p>`;
}

function chip(value: Filter, word: string): Html {
  return html`<button class="sb-chip" type="button" aria-pressed="${filter === value ? "true" : "false"}" data-app-filter="${value}">${icon("check--16", 16)}${word}</button>`;
}

export function listView(): Html {
  const s = t();
  const stillOpen = app.entries.filter((e) => e.state === "open").length;
  const demo = app.entries.some((e) => e.demo);
  return html`<div class="sb-view sb-view--wide" data-sb-view="liste">
  <div class="sb-view__content"><div class="sb-container sb-stack">
    <h1 class="sb-type-headline app-view-title">${s.list.title}</h1>
    <p><a href="#/daten">${s.list.allTypes}</a>${demo ? html` <span class="sb-demo-marker">${s.app.demo}</span>` : ""}</p>
    <div class="sb-field">
      <label class="sb-visually-hidden" for="app-search">${s.list.searchLabel}</label>
      <div class="sb-field__control sb-search">
        ${icon("search")}
        <input id="app-search" type="search" placeholder="${s.list.searchPlaceholder}" value="${query}" autocomplete="off">
        <button class="sb-icon-button" type="button" aria-label="${s.list.clearSearch}"${query ? "" : html` hidden`}>${icon("close")}</button>
      </div>
    </div>
    <div class="sb-chips" role="group" aria-label="${s.list.filterLabel}" data-sb-single>
      ${chip("all", s.list.filterAll)}${chip("open", s.list.filterOpen)}${chip("done", s.list.filterDone)}
    </div>
    <div class="sb-stack" id="app-results">${results()}</div>
  </div></div>
  <div class="sb-bottom-block">
    <div class="sb-primary-action-bar">
      <div class="sb-primary-action-bar__message" role="status"></div>
      <p class="sb-primary-action-bar__status">${s.list.stillOpen(stillOpen)}</p>
      <a class="sb-primary-action" href="#/neu">${icon("plus")}<span class="sb-primary-action__label">${s.list.newEntry}</span></a>
      <p class="sb-action-hint">${s.common.localOnly}</p>
    </div>
  </div>
</div>`;
}

function refresh(): void {
  const box = document.getElementById("app-results");
  if (box) box.innerHTML = results().value;
}

export function bindList(): void {
  const input = document.getElementById("app-search") as HTMLInputElement | null;
  input?.addEventListener("input", () => {
    query = input.value.trim();
    refresh();
  });
  document.querySelectorAll<HTMLButtonElement>("[data-app-filter]").forEach((b) =>
    b.addEventListener("click", () => {
      filter = b.dataset.appFilter as Filter;
      refresh();
    }),
  );
  document.getElementById("app-results")?.addEventListener("click", (event) => {
    if (!(event.target as Element).closest("[data-app-reset-filter]")) return;
    filter = "all";
    query = "";
    if (input) {
      input.value = "";
      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.focus();
    }
    document.querySelectorAll<HTMLButtonElement>("[data-app-filter]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.appFilter === "all")));
    refresh();
  });
}
