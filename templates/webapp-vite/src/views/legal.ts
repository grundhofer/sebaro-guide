// legal.ts: the three pages every footer links (WEB-03) as short placeholders, and the view for an unknown address.
import { html, icon, type Html } from "../html";
import { t } from "../strings";

export function legalView(page: "impressum" | "datenschutz" | "barrierefreiheit"): { markup: Html; title: string } {
  const s = t().legal;
  const [title, body] =
    page === "impressum" ? [s.imprintTitle, s.imprintBody] : page === "datenschutz" ? [s.privacyTitle, s.privacyBody] : [s.accessibilityTitle, s.accessibilityBody];
  return {
    title,
    markup: html`<div class="sb-view sb-view--wide" data-sb-view="${page}" data-sb-primary-expected="0">
  <div class="sb-view__content"><div class="sb-container sb-stack sb-stack--group">
    <h1 class="sb-type-headline app-view-title">${title}</h1>
    <div class="sb-callout sb-callout--warning" role="note">${icon("warning--filled", 20)}<p class="sb-callout__text">${s.placeholder}</p></div>
    <div class="sb-prose"><p>${body}</p></div>
  </div></div>
</div>`,
  };
}

export function notFoundView(): Html {
  const s = t().notFound;
  return html`<div class="sb-view sb-view--wide" data-sb-view="nicht-gefunden" data-sb-primary-expected="0">
  <div class="sb-view__content"><div class="sb-container sb-stack">
    <h1 class="sb-type-headline app-view-title">${s.title}</h1>
    <p>${s.text} <a href="#/">${s.link}</a></p>
  </div></div>
</div>`;
}
