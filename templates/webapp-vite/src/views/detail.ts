// detail.ts: one entry (DAT-03 properties, STA-01 state as glyph + word, EBE-05 toast with „Rückgängig“, AKT-07 and
// AKT-08 deleting asks, FOR-04 a final step that deletes nothing carries the 45° cut without the trash).
// No primary action: the view has no clear next step (AKT-01), so it is marked data-sb-primary-expected="0" (TEC-03).
import { html, icon, type Html } from "../html";
import { app, go, render, toast } from "../main";
import { t, currentLang } from "../strings";
import * as fmt from "../format";
import { categoryWord } from "./list";
import type { Entry } from "../store";

function stateWord(e: Entry): Html {
  const s = t().status;
  if (e.state === "done") return html`<span class="sb-status sb-status--success">${icon("success--filled", 20)}${s.done}</span>`;
  if (e.state === "closed") return html`<span class="sb-status sb-status--success">${icon("success--filled", 20)}${s.closed}</span>`;
  return html`<span class="sb-status sb-status--neutral">${icon("clock", 20)}${s.open}</span>`;
}

export function detailView(id: string): { markup: Html; title: string } {
  const s = t();
  const lang = currentLang();
  const e = app.entries.find((x) => x.id === id);
  const back = html`<a class="sb-icon-button" href="#/" aria-label="${s.common.back}">${icon("arrow-left")}</a>`;
  if (!e) {
    return {
      title: s.detail.notFoundTitle,
      markup: html`<div class="sb-view sb-view--wide" data-sb-view="eintrag" data-sb-primary-expected="0">
  <div class="sb-top-bar sb-top-bar--sub">${back}<div class="sb-top-bar__heading"><div class="sb-top-bar__text"><h1 class="sb-top-bar__title">${s.detail.notFoundTitle}</h1></div></div></div>
  <div class="sb-view__content"><div class="sb-container"><p>${s.detail.notFoundText}</p></div></div>
</div>`,
    };
  }
  const editable = e.state !== "closed";
  return {
    title: e.title,
    markup: html`<div class="sb-view sb-view--wide" data-sb-view="eintrag" data-sb-primary-expected="0">
  <div class="sb-top-bar sb-top-bar--sub">${back}<div class="sb-top-bar__heading"><div class="sb-top-bar__text"><h1 class="sb-top-bar__title">${e.title}</h1></div></div></div>
  <div class="sb-view__content"><div class="sb-container sb-stack sb-stack--group">
    ${e.demo ? html`<p><span class="sb-demo-marker">${s.app.demo}</span></p>` : ""}
    ${e.state === "closed" ? html`<div class="sb-callout sb-callout--note" role="note">${icon("info--filled", 20)}<p class="sb-callout__text">${s.detail.closedNote}</p></div>` : ""}
    <dl class="sb-meta-list">
      <div><dt>${s.detail.state}</dt><dd>${stateWord(e)}</dd></div>
      <div><dt>${s.detail.category}</dt><dd>${e.category === "none" ? s.common.none : categoryWord(e.category)}</dd></div>
      <div><dt>${s.detail.due}</dt><dd>${e.due ? html`<time datetime="${e.due}">${fmt.date(lang, e.due)}</time>` : s.common.noValue}</dd></div>
      <div><dt>${s.detail.effort}</dt><dd>${fmt.unit(lang, e.effort, s.common.minutes)}</dd></div>
      <div><dt>${s.detail.note}</dt><dd>${e.note || s.common.none}</dd></div>
      <div><dt>${s.form.steps}</dt><dd>${e.steps.length ? e.steps.join(", ") : s.common.none}</dd></div>
      <div><dt>${s.detail.created}</dt><dd><time datetime="${e.created}">${fmt.date(lang, e.created)}</time></dd></div>
    </dl>
    ${editable
      ? html`<div class="sb-cluster">
      <a class="sb-secondary-action" href="#/bearbeiten/${e.id}">${icon("edit")}${s.detail.edit}</a>
      <button class="sb-secondary-action" type="button" data-app-toggle>${e.state === "done" ? s.detail.reopen : s.detail.markDone}</button>
    </div>`
      : ""}
    <div class="sb-cluster">
      ${editable ? html`<button class="sb-danger-action" type="button" data-sb-opens="app-dlg-finish">${s.detail.finish}</button>` : ""}
      <button class="sb-danger-action" type="button" data-sb-opens="app-dlg-delete">${icon("trash")}${s.detail.delete}</button>
    </div>
  </div></div>
  <dialog class="sb-dialog" id="app-dlg-delete" aria-labelledby="app-dlg-delete-title" aria-describedby="app-dlg-delete-text">
    <form method="dialog">
      <h2 class="sb-dialog__title" id="app-dlg-delete-title">${s.detail.deleteTitle}</h2>
      <p class="sb-dialog__text" id="app-dlg-delete-text">${s.detail.deleteText(e.title)}</p>
      <div class="sb-dialog__actions">
        <button class="sb-secondary-action" value="cancel" autofocus>${s.common.cancel}</button>
        <button class="sb-danger-action sb-danger-action--outlined" value="confirm">${s.detail.deleteConfirm}</button>
      </div>
    </form>
  </dialog>
  <dialog class="sb-dialog" id="app-dlg-finish" aria-labelledby="app-dlg-finish-title" aria-describedby="app-dlg-finish-text">
    <form method="dialog">
      <h2 class="sb-dialog__title" id="app-dlg-finish-title">${s.detail.finishTitle(e.title)}</h2>
      <p class="sb-dialog__text" id="app-dlg-finish-text">${s.detail.finishText}</p>
      <div class="sb-dialog__actions">
        <button class="sb-secondary-action" value="cancel" autofocus>${s.common.cancel}</button>
        <button class="sb-danger-action sb-danger-action--outlined" value="confirm">${s.detail.finishConfirm}</button>
      </div>
    </form>
  </dialog>
</div>`,
  };
}

export function bindDetail(id: string): void {
  const s = t();
  const e = app.entries.find((x) => x.id === id);
  if (!e) return;
  document.querySelector("[data-app-toggle]")?.addEventListener("click", () => {
    const was = e.state;
    e.state = was === "done" ? "open" : "done";
    e.demo = false;
    app.persist();
    render(false);
    document.querySelector<HTMLElement>("[data-app-toggle]")?.focus();
    toast(e.state === "done" ? s.detail.toastDone(e.title) : s.detail.toastOpen(e.title), () => {
      e.state = was;
      app.persist();
      if (app.route.name === "detail" && app.route.id === id) {
        render(false);
        document.querySelector<HTMLElement>("[data-app-toggle]")?.focus();
      }
    });
  });
  const del = document.getElementById("app-dlg-delete") as HTMLDialogElement | null;
  del?.addEventListener("close", () => {
    if (del.returnValue !== "confirm") return;
    app.entries = app.entries.filter((x) => x.id !== id);
    app.persist();
    go("#/");
  });
  const fin = document.getElementById("app-dlg-finish") as HTMLDialogElement | null;
  fin?.addEventListener("close", () => {
    if (fin.returnValue !== "confirm") return;
    e.state = "closed";
    e.demo = false;
    app.persist();
    render();
  });
}
