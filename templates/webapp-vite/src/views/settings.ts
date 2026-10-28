// settings.ts: the small view „Einstellungen“ of a web app without a window (NAV-06, D102): „Farbton: Kühl · Warm“
// (FAR-15, sb-tone.js) and „Bewegung immer reduzieren“ (BEW-04, sb-controls.js stores it, theme-init.js applies it).
// „Hell oder Dunkel“ stays the button in the header (AKT-09, WEB-02). No primary action (AKT-01).
import { html, icon, type Html } from "../html";
import { app, render, toast } from "../main";
import { t, currentLang } from "../strings";
import { seed } from "../store";

export function settingsView(): Html {
  const s = t();
  const root = document.documentElement;
  const warm = root.dataset.sbTone === "warm";
  const reduce = root.dataset.sbMotion === "reduce";
  const option = (value: "cool" | "warm", word: string, on: boolean) =>
    html`<label class="sb-segmented__option"><input type="radio" name="sb-tone" value="${value}"${on ? html` checked` : ""}><span class="sb-segmented__face">${icon("check--16", 16)}${word}</span></label>`;
  return html`<div class="sb-view sb-view--wide" data-sb-view="einstellungen" data-sb-primary-expected="0">
  <div class="sb-view__content"><div class="sb-container"><div class="sb-stack sb-stack--group app-column">
    <h1 class="sb-type-headline app-view-title">${s.settings.title}</h1>
    <form class="sb-stack" data-sb-tone-choice aria-label="${s.settings.tone}">
      <fieldset class="sb-segmented"><legend>${s.settings.tone}</legend>
        <div class="sb-segmented__options">${option("cool", s.settings.cool, !warm)}${option("warm", s.settings.warm, warm)}</div>
      </fieldset>
    </form>
    <div class="sb-switch-field">
      <div class="sb-switch-row"><span id="app-motion">${s.settings.motion}</span><button class="sb-switch" type="button" role="switch" aria-checked="${reduce ? "true" : "false"}" aria-labelledby="app-motion" aria-describedby="app-motion-help" data-sb-motion-setting><span class="sb-switch__track"></span><span class="sb-switch__thumb">${icon("check--16", 16)}</span></button></div>
      <p class="sb-field__help" id="app-motion-help">${s.settings.motionHelp}</p>
    </div>
    <p>${s.settings.themeHint}</p>
    <section class="sb-stack" aria-labelledby="app-about-h">
      <h2 class="sb-type-title" id="app-about-h">${s.settings.about}</h2>
      <dl class="sb-meta-list">
        <div><dt>${s.settings.version}</dt><dd><span class="sb-mono">0.1.0</span></dd></div>
        <div><dt>${s.settings.storage}</dt><dd>${s.settings.storageValue}</dd></div>
      </dl>
      <div>
        <button class="sb-secondary-action" type="button" data-app-reset>${icon("refresh")}${s.settings.reset}</button>
        <p class="sb-action-hint">${s.settings.resetHint}</p>
      </div>
    </section>
  </div></div></div>
</div>`;
}

export function bindSettings(): void {
  const s = t();
  document.querySelector("[data-app-reset]")?.addEventListener("click", () => {
    const before = app.entries;
    app.entries = seed(currentLang());
    app.persist();
    toast(s.settings.resetToast, () => {
      app.entries = before;
      app.persist();
      if (app.route.name !== "settings") render(false);
    });
  });
}
