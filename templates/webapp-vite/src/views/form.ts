// form.ts: create or edit an entry (EIN-01 label on top, „(optional)“ in grey, EIN-02 error line, glyph and sentence,
// STA-03 the primary action stays enabled: its press says „<Beschriftung> fehlt.“ at each field and moves focus to the
// first, AKT-11 „Abbrechen“ · „Verwerfen“ · „Sichern“ before leaving with unsaved changes, EBE-05 removing a sub-step
// from the unsaved form goes without a dialog and with an undo toast, BEL-10 the data-path line under the action).
import { html, icon, type Html } from "../html";
import { app, go, toast } from "../main";
import { t } from "../strings";
import { nextId, type Category, type Entry } from "../store";

let editing: string | null = null;
let initial = "";
let steps: string[] = [];

const CATS: Category[] = ["none", "home", "work", "garden", "health"];

function field(id: string, label: Html | string, control: Html, help?: Html): Html {
  return html`<div class="sb-field" data-app-field="${id}">
  <label class="sb-field__label" for="${id}">${label}</label>
  <div class="sb-field__control${id === "app-f-cat" ? " sb-select" : ""}">${control}</div>
  ${help ?? ""}
</div>`;
}

function stepRows(): Html {
  const s = t();
  if (!steps.length) return html`<p class="sb-list-row__meta">${s.form.stepsNone}</p>`;
  return html`<ul class="sb-list" aria-label="${s.form.steps}">${steps.map(
    (step, i) => html`<li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${step}</p></div><div class="sb-list-row__trail"><button class="sb-icon-button" type="button" aria-label="${s.form.stepRemove(step)}" data-app-step-remove="${i}">${icon("close")}</button></div></li>`,
  )}</ul>`;
}

export function formView(id: string | null): Html {
  const s = t();
  editing = id;
  const e = id ? app.entries.find((x) => x.id === id) : undefined;
  steps = e ? [...e.steps] : [];
  const opt = html` <span class="sb-optional">${s.form.optional}</span>`;
  const title = id ? s.form.titleEdit : s.form.titleNew;
  const back = id ? `#/eintrag/${id}` : "#/";
  const note = e?.note ?? "";
  return html`<div class="sb-view sb-view--wide" data-sb-view="formular">
  <div class="sb-top-bar sb-top-bar--sub"><a class="sb-icon-button" href="${back}" aria-label="${s.common.back}">${icon("arrow-left")}</a><div class="sb-top-bar__heading"><div class="sb-top-bar__text"><h1 class="sb-top-bar__title" id="app-form-title">${title}</h1></div></div></div>
  <div class="sb-view__content"><div class="sb-container">
  <form class="sb-form-grid" id="app-form" aria-labelledby="app-form-title" novalidate>
    ${field("app-f-title", s.form.name, html`<input id="app-f-title" name="title" type="text" autocomplete="off" required value="${e?.title ?? ""}">`)}
    ${field("app-f-cat", html`${s.form.category}${opt}`, html`<select id="app-f-cat" name="category">${CATS.map((c) => html`<option value="${c}"${(e?.category ?? "none") === c ? html` selected` : ""}>${s.categories[c]}</option>`)}</select>${icon("chevron-down")}`)}
    ${field("app-f-due", html`${s.form.due}${opt}`, html`<input id="app-f-due" name="due" type="date" value="${e?.due ?? ""}">`)}
    ${field("app-f-effort", s.form.effort, html`<input id="app-f-effort" name="effort" type="text" inputmode="numeric" autocomplete="off" required value="${e ? String(e.effort) : ""}" aria-describedby="app-f-effort-help"><span class="sb-field__suffix">${s.form.effortSuffix}</span>`, html`<p class="sb-field__help" id="app-f-effort-help"><span>${s.form.effortHelp}</span></p>`)}
    <div class="sb-form-grid__wide">${field("app-f-note", html`${s.form.note}${opt}`, html`<textarea id="app-f-note" name="note" rows="3" aria-describedby="app-f-note-help">${note}</textarea>`, html`<p class="sb-field__help" id="app-f-note-help"><span>${s.form.noteHelp(200 - note.length)}</span></p>`)}</div>
    <fieldset class="sb-form-grid__wide app-steps">
      <legend class="sb-field__label">${s.form.steps}${opt}</legend>
      <div id="app-steps">${stepRows()}</div>
      <div class="sb-field"><label class="sb-visually-hidden" for="app-f-step">${s.form.stepLabel}</label><div class="sb-field__control"><input id="app-f-step" type="text" autocomplete="off" placeholder="${s.form.stepLabel}"></div></div>
      <div><button class="sb-secondary-action" type="button" data-app-step-add>${icon("plus")}${s.form.stepAdd}</button></div>
    </fieldset>
    <div class="sb-form-grid__actions">
      <button class="sb-secondary-action" type="button" data-app-cancel>${s.common.cancel}</button>
      <button class="sb-primary-action" type="submit"><span class="sb-primary-action__label">${s.form.save}</span><i class="sb-primary-action__bar" aria-hidden="true"></i></button>
    </div>
    <p class="sb-action-hint sb-form-grid__wide">${s.common.localOnly}</p>
  </form>
  </div></div>
  <dialog class="sb-dialog" id="app-dlg-unsaved" aria-labelledby="app-dlg-unsaved-title" aria-describedby="app-dlg-unsaved-text">
    <form method="dialog">
      <h2 class="sb-dialog__title" id="app-dlg-unsaved-title">${s.form.unsavedTitle}</h2>
      <p class="sb-dialog__text" id="app-dlg-unsaved-text">${s.form.unsavedText}</p>
      <div class="sb-dialog__actions">
        <button class="sb-secondary-action" value="cancel" autofocus>${s.common.cancel}</button>
        <button class="sb-danger-action sb-danger-action--outlined" value="discard">${s.form.discard}</button>
        <button class="sb-secondary-action" value="save">${s.form.save}</button>
      </div>
    </form>
  </dialog>
</div>`;
}

function snapshot(form: HTMLFormElement): string {
  return JSON.stringify([...new FormData(form).entries(), steps]);
}

export function formIsDirty(): boolean {
  const form = document.getElementById("app-form") as HTMLFormElement | null;
  return !!form && snapshot(form) !== initial;
}

let leaveTo = "#/";
export function askBeforeLeaving(target: string): void {
  leaveTo = target;
  (document.getElementById("app-dlg-unsaved") as HTMLDialogElement | null)?.showModal();
}

function setError(fieldId: string, message: string | null): void {
  const box = document.querySelector(`[data-app-field="${fieldId}"]`);
  const input = document.getElementById(fieldId);
  if (!box || !input) return;
  box.querySelector(".sb-field__error")?.remove();
  const help = box.querySelector(".sb-field__help");
  const described = help ? help.id : "";
  if (!message) {
    input.removeAttribute("aria-invalid");
    if (described) input.setAttribute("aria-describedby", described);
    else input.removeAttribute("aria-describedby");
    return;
  }
  const err = document.createElement("p");
  err.className = "sb-field__error";
  err.id = `${fieldId}-error`;
  err.innerHTML = html`${icon("error--filled-16", 16)}${message}`.value;
  box.querySelector(".sb-field__control")?.after(err);
  input.setAttribute("aria-invalid", "true");
  input.setAttribute("aria-describedby", [err.id, described].filter(Boolean).join(" "));
}

/** Checks every field, writes the errors, focuses the first wrong field; returns the entry's values or null. */
function validate(form: HTMLFormElement): Omit<Entry, "id" | "state" | "created" | "demo"> | null {
  const s = t();
  const data = new FormData(form);
  const title = String(data.get("title") ?? "").trim();
  const effortRaw = String(data.get("effort") ?? "").trim();
  const due = String(data.get("due") ?? "");
  const note = String(data.get("note") ?? "");
  const errors: Array<[string, string | null]> = [];
  errors.push(["app-f-title", title ? null : s.common.missing(s.form.name)]);
  let effort = 0;
  if (!effortRaw) errors.push(["app-f-effort", s.common.missing(s.form.effort)]);
  else if (!/^\d+$/.test(effortRaw)) errors.push(["app-f-effort", s.form.effortNotNumber]);
  else {
    effort = Number(effortRaw);
    errors.push(["app-f-effort", effort >= 1 && effort <= 600 ? null : s.form.effortRange]);
  }
  const dueInput = document.getElementById("app-f-due") as HTMLInputElement | null;
  errors.push(["app-f-due", dueInput && dueInput.validity.badInput ? s.form.dueInvalid : null]);
  errors.push(["app-f-note", note.length > 200 ? s.form.noteTooLong(note.length) : null]);
  errors.forEach(([id, msg]) => setError(id, msg));
  const first = errors.find(([, msg]) => msg);
  if (first) {
    document.getElementById(first[0])?.focus();
    return null;
  }
  return { title, category: String(data.get("category") ?? "none") as Category, due, effort, note, steps: [...steps] };
}

function store(values: NonNullable<ReturnType<typeof validate>>): string {
  if (editing) {
    const e = app.entries.find((x) => x.id === editing);
    if (e) Object.assign(e, values, { demo: false });
    app.persist();
    return editing;
  }
  const id = nextId(app.entries);
  app.entries.push({ ...values, id, state: "open", created: new Date().toISOString().slice(0, 10), demo: false });
  app.persist();
  return id;
}

export function bindForm(id: string | null): void {
  const s = t();
  const form = document.getElementById("app-form") as HTMLFormElement | null;
  if (!form) return;
  initial = snapshot(form);
  const redrawSteps = () => {
    const box = document.getElementById("app-steps");
    if (box) box.innerHTML = stepRows().value;
  };
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const values = validate(form);
    if (!values) return;
    const saved = store(values);
    initial = snapshot(form);
    // saving on this device is instant: no progress, no check, no toast (AKT-05); the entry opens
    go(`#/eintrag/${saved}`);
  });
  const note = document.getElementById("app-f-note") as HTMLTextAreaElement | null;
  note?.addEventListener("input", () => {
    const help = document.querySelector("#app-f-note-help span");
    if (help) help.textContent = s.form.noteHelp(Math.max(0, 200 - note.value.length));
  });
  const stepInput = document.getElementById("app-f-step") as HTMLInputElement | null;
  const addStep = () => {
    const v = stepInput?.value.trim();
    if (!v || !stepInput) return;
    steps.push(v);
    stepInput.value = "";
    redrawSteps();
    stepInput.focus();
  };
  form.querySelector("[data-app-step-add]")?.addEventListener("click", addStep);
  stepInput?.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      addStep();
    }
  });
  document.getElementById("app-steps")?.addEventListener("click", (event) => {
    const b = (event.target as Element).closest<HTMLButtonElement>("[data-app-step-remove]");
    if (!b) return;
    const at = Number(b.dataset.appStepRemove);
    const [gone] = steps.splice(at, 1);
    redrawSteps();
    stepInput?.focus();
    toast(s.form.stepRemoved(gone), () => {
      steps.splice(at, 0, gone);
      redrawSteps();
    });
  });
  const back = id ? `#/eintrag/${id}` : "#/";
  form.querySelector("[data-app-cancel]")?.addEventListener("click", () => {
    if (formIsDirty()) askBeforeLeaving(back);
    else go(back);
  });
  const dlg = document.getElementById("app-dlg-unsaved") as HTMLDialogElement | null;
  dlg?.addEventListener("close", () => {
    if (dlg.returnValue === "discard") {
      initial = snapshot(form);
      go(leaveTo);
    } else if (dlg.returnValue === "save") {
      const values = validate(form);
      if (!values) return;
      store(values);
      initial = snapshot(form);
      go(leaveTo);
    }
  });
}
