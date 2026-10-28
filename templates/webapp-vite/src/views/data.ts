// data.ts: „Datenarten“, every kind of data of the guide's data page (docs/daten.html) as sebaro shows it, with
// the markup of the guide's specimens (classes from sebaro.css only). Values are formatted by the page's language
// (format.ts). All values are invented and marked „Beispieldaten“ (BEL-09).
// The view's one primary action is „Als CSV exportieren“ in the action zone (AKT-01, AKT-05, BEL-10).
import { html, icon, raw, type Html } from "../html";
import { app } from "../main";
import { t, currentLang, type Lang, type Strings } from "../strings";
import * as fmt from "../format";

let n = 0;
const uid = (p: string) => `app-d-${p}-${++n}`;

function item(title: string, body: Html): Html {
  const id = uid("h");
  return html`<article class="sb-stack app-specimen" aria-labelledby="${id}"><h3 class="sb-type-title" id="${id}">${title}</h3>${body}</article>`;
}

function section(key: string, title: string, items: Html[]): Html {
  return html`<section class="sb-section sb-stack sb-stack--group" id="app-d-${key}" aria-labelledby="app-d-${key}-h"><h2 class="sb-section__title" id="app-d-${key}-h">${title}</h2>${items}</section>`;
}

/** label · value pairs as a property list (DAT-03) */
function samples(rows: Array<[string | Html, Html | string]>): Html {
  return html`<dl class="sb-meta-list sb-meta-list--labels">${rows.map(([label, value]) => html`<div><dt>${label}</dt><dd>${value}</dd></div>`)}</dl>`;
}

const num = (v: string) => html`<span class="sb-num">${v}</span>`;
const demo = (s: Strings) => html`<span class="sb-demo-marker">${s.app.demo}</span>`;
const valuesTable = (s: Strings, labelledby: string, head: string[], rows: Array<[string, ...string[]]>) =>
  html`<details class="sb-chart__data"><summary>${icon("chevron-down--16", 16)}${s.data.valuesTable}</summary>
<div class="sb-table-wrap" role="region" aria-labelledby="${labelledby}" tabindex="0"><table class="sb-table"><thead><tr>${head.map((h, i) => html`<th scope="col"${i ? raw(' class="sb-num"') : ""}>${h}</th>`)}</tr></thead><tbody>${rows.map(([h, ...cells]) => html`<tr><th scope="row">${h}</th>${cells.map((c) => html`<td class="sb-num">${c}</td>`)}</tr>`)}</tbody></table></div></details>`;

function textSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  return section("text", d.sections.text, [
    item(d.shortText, samples([[d.screenTitle, d.screenTitleV], [d.rowTitle, d.rowTitleV], [d.actionText, d.actionTextV]])),
    item(d.longText, html`<ul class="sb-list"><li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.longRowTitle}</p><p class="sb-list-row__meta">${d.longRowMeta}</p><p class="sb-list-row__text">${d.longRowText}</p></div></li></ul>`),
    item(d.paragraph, html`<div class="sb-prose"><p>${d.paragraphV}</p></div>`),
    item(d.quote, html`<div class="sb-prose"><p>${d.quoteLead}</p><figure class="sb-quote"><blockquote class="sb-quote__text"><p>${d.quoteText}</p></blockquote><figcaption class="sb-quote__source">${d.quoteSource} ${demo(s)}</figcaption></figure></div>`),
    item(d.languages, samples([
      [d.german, html`<span lang="de">${fmt.num("de", 10000)} ${s.data.steps}</span>`],
      [d.english, html`<span lang="en">${fmt.num("en", 10000)} ${s.data.stepsEn}</span>`],
      [d.dateGerman, html`<time datetime="2026-10-10" lang="de">${fmt.date("de", "2026-10-10")}</time>`],
      [d.dateEnglish, html`<time datetime="2026-10-10" lang="en">${fmt.date("en", "2026-10-10")}</time>`],
    ])),
    item(d.truncated, html`<p>${d.truncatedNote}</p>
<ul class="sb-list app-touch-rows" aria-label="${d.truncatedLabel}" data-sb-truncate>
  <li class="sb-row" title="${d.fileLong}">${icon("file-text", undefined, "sb-row__icon")}<span class="sb-row__name">${d.fileLong}</span><span class="sb-row__meta"><time datetime="2026-10-09">${d.yesterday}</time></span></li>
  <li class="sb-row" title="${d.fileShop}">${icon("file-text", undefined, "sb-row__icon")}<span class="sb-row__name">${d.fileShop}</span><span class="sb-row__meta"><span class="sb-status sb-status--warning">${icon("warning--16", 16)}${d.notSaved}</span></span></li>
  <li class="sb-row">${icon("file-text", undefined, "sb-row__icon")}<span class="sb-row__name">${d.fileNotes}</span><span class="sb-row__meta"><time datetime="2026-10-10T08:12">${fmt.time(lang, "2026-10-10T08:12")}</time></span></li>
</ul>`),
    item(d.menuPath, html`<p>${d.menuPathSentence}</p><nav class="sb-breadcrumb" aria-label="${d.menuPathLabel}"><ol>${d.menuPathParts.map((p, i, all) =>
      i < all.length - 1 ? html`<li><a href="#app-d-text">${p}</a>${icon("chevron-right--16", 16)}</li>` : html`<li><span aria-current="page">${p}</span></li>`,
    )}</ol></nav>`),
  ]);
}

function numbersSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const steps = [["Montag", 8412], ["Dienstag", 12075], ["Mittwoch", 980], ["Donnerstag", 10000]] as const;
  const dayNames = ["2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08"].map((iso) => fmt.weekday(lang, iso));
  return section("numbers", d.sections.numbers, [
    item(d.integer, samples([[d.numberWithUnit, num(fmt.unit(lang, 8, d.glasses))], [d.fraction, num("5 / 8")], [d.inSentence, num(d.ofDone(3, 5))]])),
    item(d.decimal, samples([[d.decimalComma, num(fmt.unit("de", 2.5, "l"))], [d.leadingZero, num(fmt.num(lang, 0.75))], [d.decimalPoint, html`<span class="sb-num" lang="en">${fmt.unit("en", 2.5, "l")}</span>`]])),
    item(d.large, samples([[d.thousands, num(`${fmt.num(lang, 10000)} ${d.stepsWord}`)], [d.millions, num(fmt.num(lang, 1250000))]])),
    item(d.percentT, samples([[d.value, num(fmt.percent(lang, 60))], [d.inStateSentence, num(d.stateSentence(3, 5, fmt.percent(lang, 60)))]])),
    item(d.money, samples([[d.amount, num(fmt.money(lang, 12.9))], [d.withThousands, num(fmt.money(lang, 1249))], [d.withPeriod, num(`${fmt.money(lang, 0.99)} ${d.perMonth}`)]])),
    item(d.units, samples([
      [d.minutesL, num(fmt.unit(lang, 12, s.common.minutes))],
      [d.hoursL, num(fmt.unit(lang, 2, s.common.hours))],
      [d.measure, num(fmt.unit(lang, 5.2, "km", 1))],
      [d.temperature, num(fmt.unit(lang, 21, "°C"))],
      [d.fileSize, num(fmt.unit(lang, 1.2, "MB", 1))],
    ])),
    item(d.signed, samples([
      [d.minus, html`<span class="sb-signed sb-signed--minus">${icon("arrow-down--16", 16)}${"−" + fmt.money(lang, 84)}</span>`],
      [d.plus, html`<span class="sb-signed sb-signed--plus">${icon("arrow-up--16", 16)}+3</span>`],
      [d.zero, html`<span class="sb-signed">±0</span>`],
    ])),
    item(d.range, samples([[d.amounts, num(`3–5 ${d.glasses}`)], [d.times, num("08:00–22:00")], [d.days, num(lang === "de" ? "10.–16.10.2026" : "2026-10-10 – 2026-10-16")]])),
    item(d.approx, samples([[d.estimate, num(d.approxEstimate(fmt.unit(lang, 40, s.common.minutes)))], [d.rounded, num(d.approxRounded(`${fmt.num(lang, 2000)} ${d.stepsWord}`))]])),
    item(d.rank, samples([[d.rankWith, num(d.rankV(2, 14))], [d.ordinal, num(d.ordinalV(3))]])),
    item(d.columns, html`<div class="sb-table-wrap" role="region" aria-labelledby="app-d-steps-cap" tabindex="0"><table class="sb-table"><caption id="app-d-steps-cap">${d.stepsPerDay} ${demo(s)}</caption>
<thead><tr><th scope="col">${d.day}</th><th scope="col" class="sb-num">${d.stepsWord}</th></tr></thead>
<tbody>${steps.map(([, v], i) => html`<tr><td>${dayNames[i]}</td><td class="sb-num">${fmt.num(lang, v)}</td></tr>`)}</tbody></table></div>`),
  ]);
}

function timeSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const tm = (iso: string) => fmt.time(lang, iso);
  return section("time", d.sections.time, [
    item(d.dateT, samples([
      [d.dayHead, html`<time datetime="2026-10-10">${fmt.dateLong(lang, "2026-10-10")}</time>`],
      [d.noteTableEvidence, html`<time datetime="2026-10-10">${fmt.date(lang, "2026-10-10")}</time>`],
    ])),
    item(d.timeT, samples([[d.morning, html`<time datetime="08:12">08:12</time>`], [d.evening, html`<time datetime="22:00">22:00</time>`]])),
    item(d.duration, samples([
      [d.durationText, html`<time datetime="PT1H20M">${fmt.unit(lang, 1, s.common.hours)} ${fmt.unit(lang, 20, s.common.minutes)}</time>`],
      [d.durationShort, html`<time datetime="PT45M">${fmt.unit(lang, 45, s.common.minutes)}</time>`],
      [d.timer, html`<time class="sb-num" datetime="PT25M">25:00</time>`],
    ])),
    item(d.relative, samples([
      [d.justNow, html`<time datetime="2026-10-10T14:32">${d.relJustNow(tm("2026-10-10T14:32"))}</time>`],
      [d.yesterday, html`<time datetime="2026-10-09T18:40">${d.relYesterday(tm("2026-10-09T18:40"))}</time>`],
      [d.older, html`<time datetime="2026-10-07">${d.relOlder(fmt.date(lang, "2026-10-07"))}</time>`],
    ])),
    item(d.span, samples([[d.tableTitle, d.thisWeek(fmt.dayMonth(lang, "2026-10-04"), fmt.date(lang, "2026-10-10"))], [d.reminderWindow, "08:00–22:00"]])),
    item(d.weekdayT, samples([[d.inText, fmt.weekday(lang, "2026-10-10")], [d.axisHead, fmt.weekday(lang, "2026-10-10", true)]])),
    item(d.calendar, html`<div class="sb-calendar" data-sb-calendar data-sb-month="2026-10" data-sb-selected="2026-10-09" data-sb-today="2026-10-10" data-sb-entries="2026-10-02 2026-10-09">
  <div class="sb-calendar__body">
    <div class="sb-calendar__month">
      <div class="sb-calendar__head"><p class="sb-calendar__title" id="app-d-cal-title" aria-live="polite"></p><div class="sb-calendar__nav"><button class="sb-icon-button" type="button" data-sb-calendar-step="-1" aria-label="${d.prevMonth}">${icon("chevron-left")}</button><button class="sb-icon-button" type="button" data-sb-calendar-step="1" aria-label="${d.nextMonth}">${icon("chevron-right")}</button></div></div>
      <table class="sb-calendar__grid" role="grid" aria-labelledby="app-d-cal-title"></table>
    </div>
    <div class="sb-calendar__agenda">
      <h4 class="sb-calendar__agenda-title" data-sb-calendar-heading>${fmt.dateLong(lang, "2026-10-09")}</h4>
      <ul class="sb-calendar__entries" data-sb-calendar-day="2026-10-09"><li class="sb-calendar__entry"><time datetime="2026-10-09T07:30">07:30</time><span>${d.calVitamin}</span></li></ul>
      <ul class="sb-calendar__entries" data-sb-calendar-day="2026-10-02" hidden><li class="sb-calendar__entry"><time datetime="2026-10-02T19:00">19:00</time><span>${d.calWalk}</span></li></ul>
      <p class="sb-calendar__none" data-sb-calendar-day="" hidden>${d.nothingEntered}</p>
    </div>
  </div>
</div>`),
    item(d.timeline, html`<ol class="sb-timeline" aria-label="${d.timelineLabel}">
  <li class="sb-timeline__item"><time class="sb-timeline__date" datetime="2026-10-10T14:32">${d.tlToday(tm("2026-10-10T14:32"))}</time><span class="sb-timeline__mark">${icon("edit", 16)}</span><div class="sb-timeline__main"><p class="sb-timeline__title">${d.tlEdited}</p><p class="sb-timeline__meta">${d.tlEditedMeta}</p></div></li>
  <li class="sb-timeline__item"><time class="sb-timeline__date" datetime="2026-10-09T22:05">${d.tlYesterday(tm("2026-10-09T22:05"))}</time><span class="sb-timeline__mark sb-timeline__mark--warning">${icon("warning--16", 16)}</span><div class="sb-timeline__main"><p class="sb-timeline__title">${d.tlConflict}</p><p class="sb-timeline__meta">${d.tlConflictMeta}</p></div></li>
  <li class="sb-timeline__item"><time class="sb-timeline__date" datetime="2026-10-02">${fmt.date(lang, "2026-10-02")}</time><span class="sb-timeline__mark">${icon("plus--16", 16)}</span><div class="sb-timeline__main"><p class="sb-timeline__title">${d.tlCreated}</p></div></li>
</ol>
<div><button class="sb-text-action" type="button">${d.tlOlder}</button></div>`),
    item(d.countdown, html`<p class="sb-big-number"><span class="sb-big-number__value"><time datetime="PT12M40S">12:40</time></span><span class="sb-big-number__label">${d.countdownLabel("10:30")}</span></p>`),
  ]);
}

function stateSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  return section("state", d.sections.state, [
    item(d.statusT, html`<div class="sb-cluster">
  <span class="sb-status sb-status--info">${icon("progress", 20)}${d.running}</span>
  <span class="sb-status sb-status--neutral">${icon("clock", 20)}${d.planned}</span>
  <span class="sb-status sb-status--success">${icon("success--filled", 20)}${d.doneW}</span>
  <span class="sb-status sb-status--danger">${icon("error--filled", 20)}${d.error}</span>
  <span class="sb-status sb-status--warning">${icon("pending", 20)}${d.oneOpen}</span>
</div>`),
    item(d.partial, html`<p class="sb-day-summary">${d.stateSentence(3, 5, fmt.percent(lang, 60))} ${s.list.stillOpen(2)}</p>
<ul class="sb-list">
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.survey}</p><p class="sb-list-row__meta">${d.surveyMeta}</p></div><span class="sb-status sb-status--warning">${icon("pending", 20)}${d.twoOpen}</span></li>
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.photos}</p><p class="sb-list-row__meta">${d.photosMeta}</p></div><span class="sb-status sb-status--neutral">${icon("pending", 20)}${d.twoOpen}</span></li>
</ul>`),
    item(d.sum, html`<ul class="sb-list">
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.sumRow1}</p></div><span class="sb-status sb-status--warning">${icon("warning--16", 16)}${d.notSaved}</span></li>
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.sumRow2}</p></div><span class="sb-status sb-status--neutral">${icon("info--16", 16)}${d.onlyOnline}</span></li>
</ul><p>${d.sumNote}</p>`),
    item(d.onOff, html`<div class="sb-switch-row"><span id="app-d-quiet">${d.quietReminder}</span><button class="sb-switch" type="button" role="switch" aria-checked="true" aria-labelledby="app-d-quiet"><span class="sb-switch__track"></span><span class="sb-switch__thumb">${icon("check--16", 16)}</span></button></div>
<dl class="sb-meta-list"><div><dt>${d.reminder}</dt><dd>${d.on}</dd></div><div><dt>${d.sound}</dt><dd>${d.off}</dd></div></dl>`),
    item(d.checks, html`<div class="sb-stack">
  <p class="sb-check-state sb-check-state--passed">${icon("success--filled-16", 16)}${d.passed}</p>
  <p class="sb-check-state sb-check-state--open">${icon("pending--16", 16)}${s.status.open}</p>
  <p class="sb-check-state sb-check-state--skipped">${icon("skipped--16", 16)}${d.skipped}</p>
  <p class="sb-check-state sb-check-state--failed">${icon("error--filled-16", 16)}${d.failed}</p>
  <p class="sb-check-state sb-check-state--open">${icon("pending--16", 16)}${d.notEvidenced}</p>
</div>`),
    item(d.progress, html`<p class="sb-day-summary" id="app-d-summary">${d.stateSentence(3, 5, fmt.percent(lang, 60))} ${s.list.stillOpen(2)}</p>
<progress class="sb-progress__bar" value="3" max="5" aria-labelledby="app-d-summary">${fmt.percent(lang, 60)}</progress>
<div class="sb-progress"><p class="sb-progress__head"><span id="app-d-sync">${d.syncing}</span><span>${fmt.percent(lang, 60)}</span></p><progress value="60" max="100" aria-labelledby="app-d-sync"></progress></div>`),
    item(d.actionProgress, html`<p>${d.actionProgressNote}</p>`),
    item(d.stepsT, html`<div class="sb-progress"><p class="sb-progress__head"><span>${d.stepOf(2, 3)}</span></p>
<ol class="sb-progress__steps">
  <li class="sb-progress__step" data-sb-state="done">${icon("check--16", 16)}<span class="sb-progress__word">${d.stepName}</span></li>
  <li class="sb-progress__step" aria-current="step"><span class="sb-progress__word">${d.stepGoal}</span></li>
  <li class="sb-progress__step"><span class="sb-progress__word">${d.stepReminder}</span></li>
</ol></div>`),
  ]);
}

function categoriesSection(s: Strings): Html {
  const d = s.data;
  const chip = (word: string, on: boolean) => html`<button class="sb-chip" type="button" aria-pressed="${on ? "true" : "false"}">${icon("check--16", 16)}${word}</button>`;
  return section("categories", d.sections.categories, [
    item(d.tags, html`<ul class="sb-tags">${d.tagList.map((tag) => html`<li class="sb-tag">${tag}</li>`)}</ul>`),
    item(d.categoryWord, html`<p class="sb-list-row__meta">${d.longRowMeta}</p><div class="sb-chips" role="group" aria-label="${d.filterCategory}" data-sb-single>${chip(d.catAll, true)}${chip(d.catHealth, false)}${chip(d.catMove, false)}</div>`),
    item(d.categoryColour, html`<p>${d.roses} · <span class="sb-category sb-category--4">${d.catGarden}</span> · 17:30</p>
<p><span class="sb-category sb-category--1">${d.catHealth}</span> <span class="sb-category sb-category--2">${d.catLearn}</span> <span class="sb-category sb-category--3">${d.catMove}</span></p>
<p class="sb-category sb-category--5">${icon("folder--filled", 20)}${d.catWork}</p>
<p><span class="sb-category">${d.catNone}</span></p>`),
    item(d.marks, html`<p>${d.markParts[0]}<mark aria-current="true">${d.markParts[1]}</mark>${d.markParts[2]} · <mark>${d.markParts[3]}</mark>${d.markParts[4]}</p><p class="sb-list-row__meta" role="status">${d.hitOf(1, 2)}</p>`),
  ]);
}

function identitySection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const tile = (document.getElementById("app-tile-48") as HTMLTemplateElement | null)?.innerHTML ?? "";
  const tm = (iso: string) => fmt.time(lang, iso);
  return section("identity", d.sections.identity, [
    item(d.person, html`<ul class="sb-list"><li class="sb-list-row"><span class="sb-list-row__lead"><span class="sb-avatar" aria-hidden="true"><span>AK</span></span></span><div class="sb-list-row__main"><p class="sb-list-row__title">${d.personName}</p><p class="sb-list-row__meta">${d.personMeta} · <time datetime="2026-10-10T14:32">${d.relJustNow(tm("2026-10-10T14:32"))}</time></p></div></li></ul>`),
    item(d.group, html`<ul class="sb-avatars" aria-hidden="true"><li class="sb-avatar"><span>AK</span></li><li class="sb-avatar"><span>LM</span></li><li class="sb-avatar"><span>JB</span></li></ul><p>${d.groupNames}</p>`),
    item(d.appT, html`<ul class="sb-app-list"><li class="sb-app-row"><span class="sb-sign-tile sb-sign-tile--48" aria-hidden="true">${raw(tile)}</span><div><h4 class="sb-app-row__name" translate="no">${s.app.name}</h4><p class="sb-app-row__text">${d.appLine}</p><p class="sb-app-row__meta"><span>${d.appPlatform}</span><span aria-hidden="true">·</span><span>${d.version} <span class="sb-mono">0.1.0</span></span><span aria-hidden="true">·</span><span class="sb-demo-marker">${s.app.demo}</span></p></div></li></ul><p class="sb-list-row__meta">${d.appTileNote}</p>`),
    item(d.device, html`<ul class="sb-list">
  <li class="sb-list-row"><span class="sb-list-row__lead">${icon("smartphone")}</span><div class="sb-list-row__main"><p class="sb-list-row__title">${d.phone}</p><p class="sb-list-row__meta">${d.thisDevice} · ${d.synced(d.todayAt(tm("2026-10-10T08:12")))}</p></div></li>
  <li class="sb-list-row"><span class="sb-list-row__lead">${icon("monitor")}</span><div class="sb-list-row__main"><p class="sb-list-row__title">${d.laptop}</p><p class="sb-list-row__meta">${d.synced(d.yesterdayAt(tm("2026-10-09T22:40")))}</p></div></li>
  <li class="sb-list-row"><span class="sb-list-row__lead">${icon("watch")}</span><div class="sb-list-row__main"><p class="sb-list-row__title">${d.watch}</p><p class="sb-list-row__meta">${d.neverSynced}</p></div></li>
</ul>`),
    item(d.address, html`<address>${d.addressLines.map((l, i) => html`${i ? raw("<br>") : ""}${l}`)}</address>`),
    item(d.contact, html`<dl class="sb-meta-list">
  <div><dt>${d.email}</dt><dd><a href="mailto:example@example.org">example@${raw("<wbr>")}example.${raw("<wbr>")}org${icon("external-link--16", 16)}</a></dd></div>
  <div><dt>${d.website}</dt><dd><a href="https://example.org/">example.org${icon("external-link--16", 16)}</a></dd></div>
</dl>`),
  ]);
}

function codeBlock(lang: string, label: string, copy: string, code: Html): Html {
  return html`<div class="sb-code"><div class="sb-code__bar"><span class="sb-code__lang">${lang}</span><button class="sb-code__copy" type="button">${icon("copy--16", 16)}<span class="sb-code__copy-label">${copy}</span></button></div><pre tabindex="0" role="region" aria-label="${label}"><code>${code}</code></pre></div>`;
}

function techSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const k = (c: string) => html`<span class="sb-tok-keyword">${c}</span>`;
  const str = (c: string) => html`<span class="sb-tok-string">${c}</span>`;
  const con = (c: string) => html`<span class="sb-tok-constant">${c}</span>`;
  const com = (c: string) => html`<span class="sb-tok-comment">${c}</span>`;
  const [v0, v1, v2, v3] = d.versionLine("1.4.0", "");
  return section("tech", d.sections.tech, [
    item(d.ids, samples([
      [d.shortHash, html`<code class="sb-code-inline">7b3d2e1</code>`],
      [d.uuid, html`<code class="sb-code-inline">3f2a9c1e-5b7d-4e0a-9c1f-2b8e6d4a0c17</code>`],
      [d.ruleId, html`<code class="sb-code-inline">FAR-01</code>`],
      [d.idInSentence, html`${d.ruleWord} <span class="sb-id">DAT-02</span>`],
    ])),
    item(d.version, html`<p>${v0}<code class="sb-code-inline">${v1}</code>${v2}<time datetime="2026-10-10">${fmt.date(lang, "2026-10-10")}</time>${v3}</p>`),
    item(d.path, html`<p><code class="sb-code-inline sb-file-name">notizen/${raw("<wbr>")}research/${raw("<wbr>")}offline-${raw("<wbr>")}first.md</code></p>`),
    item(d.command, codeBlock(d.commandLang, d.commandLabel, d.copy, html`${com(d.commandComment)}\nnpm run build`)),
    item(d.code, codeBlock(d.codeLang, d.codeLabel, d.copy, html`${com(d.codeComment)}\n${k("let")} count = ${con("0")};\n${k("function")} add(): ${k("string")} {\n  count += ${con("1")};\n  ${k("return")} ${str("`")}\${count}${str(d.codeString + "`")};\n}`)),
    item(d.json, codeBlock(d.json, d.jsonLabel, d.copy, html`{\n  "id": ${str('"wasser"')},\n  "title": ${str(`"${d.jsonTitle}"`)},\n  "goal": ${con("8")},\n  "reminder": { "every": ${str('"PT2H"')}, "from": ${str('"08:00"')}, "to": ${str('"22:00"')} }\n}`)),
    item(d.log, codeBlock(d.logLang, d.logLabel, d.copy, html`${d.logLines.map((l, i) => `2026-10-10T08:12:0${i === 0 ? 3 : 4}  ${l}`).join("\n")}`)),
    item(d.diff, html`<figure class="sb-diff" aria-labelledby="app-d-diff-file">
  <figcaption class="sb-diff__bar"><span class="sb-diff__file" id="app-d-diff-file">entry.json</span><span>${d.diffVersions}</span></figcaption>
  <div class="sb-diff__lines" role="region" aria-label="${d.diffLabel}" tabindex="0">
    <span class="sb-diff__hunk">@@ -4,4 +4,5 @@</span>
    <div class="sb-diff__line"><span class="sb-diff__num">4</span><span class="sb-diff__num">4</span><span class="sb-diff__sign" aria-hidden="true"> </span><span class="sb-diff__code">  "goal": ${con("8")},</span></div>
    <div class="sb-diff__line sb-diff__line--del"><span class="sb-diff__num">5</span><span class="sb-diff__num"></span><span class="sb-diff__sign" aria-hidden="true">−</span><span class="sb-diff__code"><span class="sb-visually-hidden">${d.diffRemoved}</span>  "every": ${str('"PT1H"')},</span></div>
    <div class="sb-diff__line sb-diff__line--add"><span class="sb-diff__num"></span><span class="sb-diff__num">5</span><span class="sb-diff__sign" aria-hidden="true">+</span><span class="sb-diff__code"><span class="sb-visually-hidden">${d.diffAdded}</span>  "every": ${str('"PT2H"')},</span></div>
    <div class="sb-diff__line sb-diff__line--add"><span class="sb-diff__num"></span><span class="sb-diff__num">6</span><span class="sb-diff__sign" aria-hidden="true">+</span><span class="sb-diff__code"><span class="sb-visually-hidden">${d.diffAdded}</span>  "quiet": [${str('"22:00"')}, ${str('"08:00"')}], ${com(d.diffComment)}</span></div>
    <div class="sb-diff__line"><span class="sb-diff__num">6</span><span class="sb-diff__num">7</span><span class="sb-diff__sign" aria-hidden="true"> </span><span class="sb-diff__code">  "sound": ${con("false")}</span></div>
  </div>
  <p class="sb-diff__sum">${d.diffSum}</p>
</figure>`),
    item(d.keys, html`<p>${d.keysSentence[0]}<kbd><span aria-hidden="true">⌘</span> ${d.keysCmd}</kbd>${d.keysSentence[1]}<kbd>K</kbd>${d.keysSentence[2]}<kbd>${d.keysCtrl}</kbd>${d.keysSentence[3]}<kbd>K</kbd>${d.keysSentence[4]}</p>
${samples([[d.keysInMenu, html`${d.keysNewNote} <span class="sb-keys"><span aria-hidden="true">⇧⌘N</span><span class="sb-visually-hidden">${d.keysWords}</span></span>`]])}`),
  ]);
}

function collectionsSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const tableRows: Array<[string, number, number, number]> = [["", 7, 100, 31], ["", 6, 86, 12], ["", 5, 71, 4], ["", 4, 57, 2]];
  const spend: Array<[string, number | null]> = [["2026-10-01", 1250], ["2026-10-03", 412.3], ["2026-10-08", 38.9], ["2026-10-06", null]];
  const known = spend.reduce((sum, [, v]) => sum + (v ?? 0), 0);
  const row = (name: string, level: number, opts: { icon: string; selected?: boolean; expanded?: boolean; owns?: string; status?: Html; title?: string; tab?: boolean }) =>
    html`<div class="sb-row sb-tree__row" role="treeitem" aria-level="${level}"${opts.expanded !== undefined ? raw(` aria-expanded="${opts.expanded}"`) : ""}${opts.owns ? raw(` aria-owns="${opts.owns}"`) : ""} aria-selected="${opts.selected ? "true" : "false"}" tabindex="${opts.tab ? "0" : "-1"}"${opts.title ? html` title="${opts.title}"` : ""}><span class="sb-tree__twist" aria-hidden="true">${opts.expanded !== undefined ? icon("chevron-right--16", 16) : ""}</span>${icon(opts.icon, undefined, "sb-row__icon")}<span class="sb-row__name">${name}</span>${opts.status ? html`<span class="sb-row__meta">${opts.status}</span>` : ""}</div>`;
  return section("collections", d.sections.collections, [
    item(d.listT, html`<ul class="sb-list">
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title"><a class="sb-list-row__link" href="#/">${d.listRow1}</a></p><p class="sb-list-row__meta">${d.listRow1Meta}</p></div><span class="sb-list-row__trail">${icon("chevron-right")}</span></li>
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title"><a class="sb-list-row__link" href="#/">${d.listRow2}</a></p><p class="sb-list-row__meta">${d.listRow2Meta}</p></div><span class="sb-list-row__trail">${icon("chevron-right")}</span></li>
</ul><p class="sb-list-end">${d.listEnd}</p>`),
    item(d.doneRows, html`<p class="sb-day-summary">${d.stateSentence(3, 5, fmt.percent(lang, 60))} ${s.list.stillOpen(2)}</p>
<p class="sb-list-header">${s.list.headerOpen} <span class="sb-list-header__count">2</span></p>
<ul class="sb-list">
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.listRow1}</p><p class="sb-list-row__meta">${d.listRow1Meta}</p></div><span class="sb-status sb-status--info">${icon("progress", 20)}${d.running}</span></li>
  <li class="sb-list-row"><div class="sb-list-row__main"><p class="sb-list-row__title">${d.longRowTitle}</p><p class="sb-list-row__meta">${d.longRowMeta}</p></div><span class="sb-status sb-status--neutral">${icon("clock", 20)}${d.planned}</span></li>
</ul>
<p class="sb-list-header">${s.list.headerDone} <span class="sb-list-header__count">2</span></p>
<ul class="sb-list">
  <li class="sb-list-row sb-list-row--done"><span class="sb-list-row__lead">${icon("success--filled-16", 16)}</span><div class="sb-list-row__main"><p class="sb-list-row__title"><span class="sb-visually-hidden">${s.list.doneHidden}</span>${d.doneRow1}</p></div><span class="sb-list-row__trail"><time datetime="2026-10-10T08:12">08:12</time></span></li>
  <li class="sb-list-row sb-list-row--done"><span class="sb-list-row__lead">${icon("success--filled-16", 16)}</span><div class="sb-list-row__main"><p class="sb-list-row__title"><span class="sb-visually-hidden">${s.list.doneHidden}</span>${d.doneRow2}</p></div><span class="sb-list-row__trail"><time datetime="2026-10-10T07:40">07:40</time></span></li>
</ul>`),
    item(d.tableT, html`<div class="sb-table-wrap" role="region" aria-labelledby="app-d-tab-cap" tabindex="0"><table class="sb-table">
<caption id="app-d-tab-cap">${d.tableCaption(fmt.dayMonth(lang, "2026-10-04"), fmt.date(lang, "2026-10-10"))} ${demo(s)}</caption>
<thead><tr><th scope="col">${d.habit}</th><th scope="col" class="sb-num">${d.daysCol}</th><th scope="col" class="sb-num">${d.rate}</th><th scope="col" class="sb-num">${d.streak}</th></tr></thead>
<tbody>${tableRows.map(([, days, rate, streak], i) => html`<tr><th scope="row">${d.habits[i]}</th><td class="sb-num">${d.ofN(days, 7)}</td><td class="sb-num">${fmt.percent(lang, rate)}</td><td class="sb-num">${fmt.unit(lang, streak, d.daysWord)}</td></tr>`)}</tbody>
</table></div>`),
    item(d.sortTable, html`<div class="sb-table-wrap" role="region" aria-labelledby="app-d-sum-cap" tabindex="0"><table class="sb-table">
<caption id="app-d-sum-cap">${d.sortCaption} ${demo(s)}</caption>
<thead><tr><th scope="col"><button class="sb-table__sort" type="button">${d.colDate}</button></th><th scope="col"><button class="sb-table__sort" type="button">${d.colPurpose}</button></th><th scope="col" class="sb-num" aria-sort="descending"><button class="sb-table__sort" type="button">${icon("arrow-down--16", 16)}${d.colAmount}</button></th></tr></thead>
<tbody>${spend.map(([iso, v], i) => html`<tr><td><time datetime="${iso}">${fmt.dayMonth(lang, iso)}</time></td><td>${d.purposes[i]}</td><td class="sb-num">${v === null ? s.common.noValue : fmt.money(lang, v)}</td></tr>`)}</tbody>
<tfoot><tr><th scope="row" colspan="2">${d.sumKnown}</th><td class="sb-num">${fmt.money(lang, known)}</td></tr></tfoot>
</table></div>`),
    item(d.keyValue, html`<dl class="sb-meta-list">
  <div><dt>${d.kvReminder}</dt><dd>${d.kvReminderV}</dd></div>
  <div><dt>${d.kvCategory}</dt><dd>${d.catHealth}</dd></div>
  <div><dt>${d.kvGoal}</dt><dd>${fmt.unit(lang, 8, d.glasses)}</dd></div>
  <div><dt>${d.kvCreated}</dt><dd><time datetime="2026-03-12">${fmt.date(lang, "2026-03-12")}</time></dd></div>
</dl>`),
    item(d.tree, html`<p>${d.treeNote}</p><div class="app-touch-rows">
<p class="sb-side-nav__head" id="app-d-tree-h">${d.treeHead}</p>
<ul class="sb-tree" role="tree" aria-labelledby="app-d-tree-h">
  <li role="none">${row(d.treeProjects, 1, { icon: "folder", expanded: true, owns: "app-d-tree-g1" })}
    <ul class="sb-tree__group" role="group" id="app-d-tree-g1">
      <li role="none">${row(d.treeWeek, 2, { icon: "file-text", selected: true, tab: true, status: html`<span class="sb-status sb-status--warning">${icon("warning--16", 16)}${d.notSaved}</span>` })}</li>
      <li role="none">${row(d.treeGarden, 2, { icon: "file-text" })}</li>
    </ul>
  </li>
  <li role="none">${row(d.treeArchive, 1, { icon: "folder", expanded: false, owns: "app-d-tree-g2" })}
    <ul class="sb-tree__group" role="group" id="app-d-tree-g2" hidden>
      <li role="none">${row(d.treeOld, 2, { icon: "file-text" })}</li>
    </ul>
  </li>
</ul></div>`),
    item(d.multi, html`<p>${d.multiNote}</p><div class="app-touch-rows">
<p class="sb-list-header" id="app-d-sel-h">${d.multiHead}</p>
<ul class="sb-listbox" role="listbox" aria-labelledby="app-d-sel-h" aria-multiselectable="true" data-app-listbox>
  ${d.multiNames.map((name, i) => html`<li class="sb-row" role="option" id="app-d-sel-${i}" aria-selected="${i === 2 ? "false" : "true"}" tabindex="${i === 1 ? "0" : "-1"}"${i === 1 ? raw(' aria-current="true"') : ""}>${icon("file-text", undefined, "sb-row__icon")}<span class="sb-row__check" aria-hidden="true">${icon("check--16", 16)}</span><span class="sb-row__name">${name}</span></li>`)}
</ul>
<p class="sb-list-row__meta" role="status" id="app-d-sel-status">${d.selected(3)}</p></div>`),
    item(d.cardsMany, html`<ul class="sb-stack" aria-label="${d.cardsLabel}">${d.cards.map(([title, text], i) => html`<li class="sb-card sb-card--item"${i === 1 ? raw(' aria-current="true"') : ""}><p class="sb-card__title">${title}</p><p class="sb-card__text">${text}</p></li>`)}</ul>`),
    item(d.cardGrid, html`<div class="app-card-grid">${d.gridCards.map(([title, text, action]) => html`<div class="sb-card"><h4 class="sb-card__title">${title}</h4><p class="sb-card__text">${text}</p><div class="sb-card__actions"><button class="sb-secondary-action" type="button">${action}</button></div></div>`)}</div>`),
  ]);
}

function barList(heights: number[], current: number, dense = false, counts?: number[]): Html {
  return html`<ol class="sb-chart__bars${dense ? " sb-chart__bars--dense" : ""}" aria-hidden="true">${heights.map((h, i) =>
    html`<li><svg viewBox="0 0 1 1" preserveAspectRatio="none" height="${h}%" focusable="false"><rect class="sb-chart__bar${i === current ? " sb-chart__bar--current" : ""}"${dense ? raw(' width="1"') : raw(' x="0.18" width="0.64"')} height="1"/></svg>${counts ? html`<span class="sb-chart__count" data-sb-y="${Math.round(h)}">${counts[i]}</span>` : ""}</li>`,
  )}</ol>`;
}

function chartsSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const days = ["2026-10-04", "2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09", "2026-10-10"];
  const glasses = [8, 6, 8, 7, 4, 8, 5];
  const weekly = [6.1, 6.5, 7.0, 6.8, 7.2, 7.5, 6.9, 7.4, 7.8, 7.6, 8.0, 7.1];
  const weeks = ["2026-07-20", "2026-07-27", "2026-08-03", "2026-08-10", "2026-08-17", "2026-08-24", "2026-08-31", "2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28", "2026-10-05"];
  const series = [[70, 74, 78, 76, 82, 85, 83, 90], [40, 55, 50, 62, 58, 65, 70, 72], [30, 28, 35, 40, 38, 45, 42, 50]];
  const sWeeks = ["2026-08-10", "2026-08-17", "2026-08-24", "2026-08-31", "2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28"];
  const poly = (vals: number[]) => vals.map((v, i) => `${(6.25 + i * 12.5).toFixed(2)},${100 - v}`).join(" ");
  const pct = (v: number) => fmt.percent(lang, v);
  const seriesChart = (count: 2 | 3, capId: string, caption: string) => {
    const names = d.seriesNames.slice(0, count);
    const legend = html`<ul class="sb-chart__legend" aria-label="${d.legend}"${count === 2 ? raw(" hidden data-sb-fit-legend") : ""}>${names.map((nm, i) => html`<li><svg class="sb-chart__key" viewBox="0 0 24 8" aria-hidden="true" focusable="false"><line class="sb-chart__line sb-chart__line--${i + 1}" x1="1" y1="4" x2="23" y2="4"/></svg>${nm}</li>`)}</ul>`;
    return html`<figure class="sb-chart" aria-labelledby="${capId}">${legend}
<div class="sb-chart__plot">
  <ul class="sb-chart__ticks" aria-hidden="true"><li data-sb-y="50">50</li><li data-sb-y="0">0</li></ul>
  <div class="sb-chart__area"><svg class="sb-chart__shapes" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true" focusable="false"><line class="sb-chart__grid" x1="0" y1="50" x2="100" y2="50"/><line class="sb-chart__axis" x1="0" y1="100" x2="100" y2="100"/>${names.map((_, i) => html`<polyline class="sb-chart__line sb-chart__line--${i + 1}" points="${poly(series[i])}"/>`)}</svg></div>
  <ul class="sb-chart__ends" aria-hidden="true">${names.map((nm, i) => html`<li class="sb-chart__end--series" data-sb-y="${series[i][7]}"><span class="sb-chart__end-name">${nm} </span>${pct(series[i][7])}</li>`)}</ul>
  <ol class="sb-chart__slots sb-chart__slots--start" aria-hidden="true">${d.seriesMonths.map(([m, span]) => html`<li data-sb-span="${span}">${m}</li>`)}</ol>
</div>
${valuesTable(s, capId, [d.weekFrom, ...names], sWeeks.map((w, wi) => [fmt.dayMonth(lang, w), ...names.map((_, i) => pct(series[i][wi]))] as [string, ...string[]]))}
<figcaption id="${capId}">${caption} ${demo(s)}</figcaption></figure>`;
  };
  const shareRows = (vals: number[], track: boolean, rowNames: string[]) =>
    html`<ul class="sb-chart__rows">${vals.map((v, i) => html`<li class="sb-chart__row"><span class="sb-chart__name">${rowNames[i]} <b>${v}</b></span><svg viewBox="0 0 100 12" preserveAspectRatio="none" aria-hidden="true" focusable="false">${track ? html`<rect class="sb-chart__track" width="100" height="12"/>` : ""}<rect class="sb-chart__fill" width="${track ? v : v * 2}" height="12"/></svg></li>`)}</ul>`;
  // heatmap: four weeks from 14.09., today 10.10. (Saturday), Sunday 11.10. still to come
  const heat: Array<Array<number | null | undefined>> = [[4, 6, 7, 3, 2, 5, 7], [8, 6, 1, 7, null, 3, 6], [5, 8, 2, 9, 7, 4, 8], [2, 5, 7, 6, 3, 5, undefined]];
  const cls = (v: number | null) => (v === null ? "none" : v <= 2 ? "seq-1" : v <= 4 ? "seq-2" : v <= 6 ? "seq-3" : "seq-4");
  const monday = (w: number) => new Date(Date.UTC(2026, 8, 14 + w * 7)).toISOString().slice(0, 10);
  const dayIso = (w: number, i: number) => new Date(Date.UTC(2026, 8, 14 + w * 7 + i)).toISOString().slice(0, 10);
  const heads = Array.from({ length: 7 }, (_, i) => fmt.weekday(lang, dayIso(0, i), true));
  const dev = [0.5, -1, 1.5, -0.5, -2, 1, 0.5];
  const devDays = ["2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04"];
  const ringPart = [
    "M59.77 8.15 A48 48 0 0 1 87.17 19.5", "M92.5 24.83 A48 48 0 0 1 103.85 52.23", "M103.85 59.77 A48 48 0 0 1 92.5 87.17", "M87.17 92.5 A48 48 0 0 1 59.77 103.85",
    "M52.23 103.85 A48 48 0 0 1 24.83 92.5", "M19.5 87.17 A48 48 0 0 1 8.15 59.77", "M8.15 52.23 A48 48 0 0 1 19.5 24.83", "M24.83 19.5 A48 48 0 0 1 52.23 8.15",
  ];
  const goalRing = (done: number, label: string, reached: boolean) =>
    html`<figure class="sb-goal-ring"><div class="sb-goal-ring__ring"><svg viewBox="0 0 112 112" aria-hidden="true" focusable="false">${ringPart.map((p, i) => html`<path class="sb-goal-ring__part"${i < done ? raw(' data-sb-state="done"') : ""} d="${p}"/>`)}</svg><p class="sb-goal-ring__text">${done}<br>${d.ofGoal(8)}</p></div><figcaption>${label}</figcaption>${reached ? html`<p class="sb-status sb-status--success">${icon("success--filled", 20)}${d.reached}</p>` : ""}</figure>`;

  return section("charts", d.sections.charts, [
    item(d.bars, html`<figure class="sb-chart" aria-labelledby="app-d-bars-cap"><div class="sb-chart__plot">
  <div class="sb-chart__area"><svg class="sb-chart__shapes" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true" focusable="false"><line class="sb-chart__grid" x1="0" y1="50" x2="100" y2="50"/></svg>
  ${barList(glasses.map((g) => (g / 8) * 100), 6)}
  <svg class="sb-chart__shapes" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true" focusable="false"><line class="sb-chart__target" x1="0" y1="0" x2="100" y2="0"/></svg></div>
  <ul class="sb-chart__ends" aria-hidden="true"><li data-sb-y="100">${d.goal("8")}</li><li data-sb-y="50">4</li></ul>
  <ol class="sb-chart__slots">${days.map((day, i) => html`<li${i === 6 ? raw(' aria-current="date"') : ""}><span class="sb-chart__label">${fmt.weekday(lang, day, true)}</span><span class="sb-chart__value">${glasses[i]}</span></li>`)}</ol>
</div><figcaption id="app-d-bars-cap">${d.barsCaption(fmt.date(lang, "2026-10-10"))} ${demo(s)}</figcaption></figure>`),
    item(d.line, html`<figure class="sb-chart" aria-labelledby="app-d-line-cap"><div class="sb-chart__plot">
  <div class="sb-chart__area"><svg class="sb-chart__shapes" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true" focusable="false">
    <line class="sb-chart__grid" x1="0" y1="71.43" x2="100" y2="71.43"/><line class="sb-chart__target" x1="0" y1="14.29" x2="100" y2="14.29"/><line class="sb-chart__axis" x1="0" y1="100" x2="100" y2="100"/>
    <polyline class="sb-chart__line" points="4.17,68.57 12.5,57.14 20.83,42.86 29.17,48.57 37.5,37.14 45.83,28.57 54.17,45.71 62.5,31.43 70.83,20 79.17,25.71 87.5,14.29 95.83,40"/>
    <line class="sb-chart__point sb-chart__point--current" x1="95.83" y1="40" x2="95.83" y2="40"/></svg></div>
  <ul class="sb-chart__ends" aria-hidden="true"><li data-sb-y="86">${d.goal("8")}</li><li class="sb-chart__end--current" data-sb-y="60">${fmt.num(lang, 7.1, 1)}</li><li data-sb-y="29">6</li><li data-sb-y="0">5</li></ul>
  <ol class="sb-chart__slots sb-chart__slots--start" aria-hidden="true">${d.lineMonths.map(([m, span]) => html`<li data-sb-span="${span}">${m}</li>`)}</ol>
</div>
${valuesTable(s, "app-d-line-cap", [d.weekFrom, d.glassesPerDay], weeks.map((w, i) => [fmt.dayMonth(lang, w), fmt.num(lang, weekly[i], 1)]))}
<figcaption id="app-d-line-cap">${d.lineCaption} ${demo(s)}</figcaption></figure>`),
    item(d.spark, html`<ul class="sb-stats"><li class="sb-stat"><p class="sb-stat__label">${d.sparkLabel}</p><p class="sb-stat__value">${fmt.num(lang, 7.1, 1)} ${d.glasses}<svg class="sb-sparkline" viewBox="0 0 96 28" aria-hidden="true" focusable="false"><polyline class="sb-sparkline__line" points="3,24 11.18,19.79 19.36,14.53 27.55,16.63 35.73,12.42 43.91,9.26 52.09,15.58 60.27,10.32 68.45,6.11 76.64,8.21 84.82,4 93,13.47"/><circle class="sb-sparkline__now" cx="93" cy="13.47" r="3"/></svg></p></li><li class="sb-stat"><p class="sb-stat__label">${d.seriesL}</p><p class="sb-stat__value">${fmt.unit(lang, 12, d.daysWord)}</p></li></ul>`),
    item(d.rows, html`<figure class="sb-chart">${shareRows([42, 27, 19, 12], false, d.rowNames)}<figcaption>${d.rowsCaption} ${demo(s)}</figcaption></figure>`),
    item(d.three, seriesChart(3, "app-d-three-cap", d.threeCaption)),
    item(d.two, seriesChart(2, "app-d-two-cap", d.twoCaption)),
    item(d.shares, html`<figure class="sb-chart">${shareRows([42, 27, 19, 12], true, d.rowNames)}<figcaption>${d.sharesCaption} ${demo(s)}</figcaption></figure>`),
    item(d.histogram, html`<figure class="sb-chart" aria-labelledby="app-d-hist-cap"><div class="sb-chart__plot">
  <div class="sb-chart__area">${barList([20, 50, 90, 80, 40, 20], -1, true, [2, 5, 9, 8, 4, 2])}</div>
  <ol class="sb-chart__edges" aria-hidden="true">${[0, 10, 20, 30, 40, 50, 60].map((e) => html`<li>${e}</li>`)}</ol>
  <p class="sb-chart__unit" aria-hidden="true">${d.histUnit}</p>
</div>
${valuesTable(s, "app-d-hist-cap", [d.histDuration, d.histWalks], [2, 5, 9, 8, 4, 2].map((c, i) => [d.histBin(i * 10, i * 10 + 10), String(c)]))}
<figcaption id="app-d-hist-cap">${d.histCaption} ${demo(s)}</figcaption></figure>`),
    item(d.heatmap, html`<figure class="sb-chart" aria-labelledby="app-d-heat-cap">
<ul class="sb-scale-legend" aria-label="${d.heatLegend}">${d.heatClasses.map((c, i) => html`<li><span class="sb-scale-cell sb-scale-cell--seq-${i + 1}" aria-hidden="true"></span>${c}</li>`)}<li><span class="sb-scale-cell sb-scale-cell--none" aria-hidden="true"></span>${s.common.noValue}</li><li><span class="sb-scale-cell sb-heatmap__today-key" aria-hidden="true"></span>${d.todayFrame}</li></ul>
<table class="sb-heatmap" aria-labelledby="app-d-heat-cap">
<thead><tr><td></td>${heads.map((h) => html`<th scope="col">${h}</th>`)}</tr></thead>
<tbody>${heat.map((week, w) => html`<tr><th scope="row">${d.weekStart(fmt.dayMonth(lang, monday(w)))}</th>${week.map((v, i) => {
      if (v === undefined) return html`<td></td>`;
      const iso = dayIso(w, i);
      const today = iso === "2026-10-10";
      return html`<td${today ? raw(' aria-current="date"') : ""}><span class="sb-scale-cell sb-scale-cell--${cls(v)}"></span><span class="sb-visually-hidden">${d.heatCell(`${fmt.weekday(lang, iso)}, ${fmt.dayMonth(lang, iso)}`, v, today)}</span></td>`;
    })}</tr>`)}</tbody>
</table>
<p class="sb-chart__readout" aria-hidden="true" hidden>${d.heatReadout}</p>
<details class="sb-chart__data"><summary>${icon("chevron-down--16", 16)}${d.valuesTable}</summary>
<div class="sb-table-wrap" role="region" aria-label="${d.heatNumbers}" tabindex="0"><table class="sb-table"><thead><tr><th scope="col">${d.week}</th>${heads.map((h) => html`<th scope="col" class="sb-num">${h}</th>`)}</tr></thead><tbody>${heat.map((week, w) => html`<tr><th scope="row">${d.weekStart(fmt.dayMonth(lang, monday(w)))}</th>${week.map((v) => html`<td class="sb-num">${v === undefined ? "" : v === null ? s.common.noValue : v}</td>`)}</tr>`)}</tbody></table></div>
</details>
<figcaption id="app-d-heat-cap">${d.heatCaption} ${demo(s)}</figcaption></figure>`),
    item(d.deviation, html`<figure class="sb-chart" aria-labelledby="app-d-dev-cap"><div class="sb-chart__diverging">
<p class="sb-chart__diverging-head"><span>${d.less}</span><span>${d.mid}</span><span>${d.more}</span></p>
<ul class="sb-chart__rows sb-chart__rows--diverging">${dev.map((v, i) => html`<li class="sb-chart__row"><span class="sb-chart__name">${fmt.weekday(lang, devDays[i], true)}</span><svg viewBox="-100 0 200 24" preserveAspectRatio="none" aria-hidden="true" focusable="false"><rect class="sb-chart__fill sb-chart__fill--${v >= 0 ? "more" : "less"}" x="${v >= 0 ? 0 : v * 50}" y="6" width="${Math.abs(v) * 50}" height="12"/><line class="sb-chart__zero" x1="0" y1="0" x2="0" y2="24"/></svg><span class="sb-chart__delta">${icon(v >= 0 ? "arrow-up--16" : "arrow-down--16", 16)}${(v >= 0 ? "+" : "−") + fmt.unit(lang, Math.abs(v), s.common.hours, 1)}</span></li>`)}</ul>
</div><figcaption id="app-d-dev-cap">${d.devCaption} ${demo(s)}</figcaption></figure>`),
    item(d.goalRing, html`<div class="sb-cluster">${goalRing(5, d.glassesToday, false)}${goalRing(8, d.glassesYesterday, true)}</div>`),
    item(d.keyFigure, html`<p class="sb-big-number"><span class="sb-big-number__value">5 / 8</span><span class="sb-big-number__label">${d.glassesToday}</span></p>
<ul class="sb-stats"><li class="sb-stat"><p class="sb-stat__label">${d.seriesL}</p><p class="sb-stat__value">${fmt.unit(lang, 12, d.daysWord)}</p></li><li class="sb-stat"><p class="sb-stat__label">${d.rateL}</p><p class="sb-stat__value">${fmt.percent(lang, 86)}</p></li><li class="sb-stat"><p class="sb-stat__label">${d.bestL}</p><p class="sb-stat__value">${fmt.unit(lang, 31, d.daysWord)}</p></li></ul>`),
    item(d.ringT, html`<div class="sb-cluster"><div class="sb-progress-ring" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="60" aria-labelledby="app-d-ring-label"><svg viewBox="0 0 48 48" aria-hidden="true" focusable="false"><g transform="rotate(-90 24 24)"><circle class="sb-progress-ring__track" cx="24" cy="24" r="20"/><circle class="sb-progress-ring__value" cx="24" cy="24" r="20" pathLength="100" stroke-dasharray="60 100"/></g></svg><span class="sb-progress-ring__text" aria-hidden="true">${fmt.percent(lang, 60)}</span></div><p id="app-d-ring-label">${d.uploading}</p></div>`),
  ]);
}

function mediaSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  return section("media", d.sections.media, [
    item(d.image, html`<figure class="app-figure"><img src="/sebaro/brand/og/studio.png" width="1200" height="630" alt="${d.imageAlt}" loading="lazy"><figcaption class="sb-list-row__meta">${d.imageCaption}</figcaption></figure>`),
    item(d.file, html`<ul class="sb-list">${d.files.map(([name, kind, mb, ic, iso]) => html`<li class="sb-list-row"><span class="sb-list-row__lead">${icon(ic)}</span><div class="sb-list-row__main"><p class="sb-list-row__title">${name}</p><p class="sb-list-row__meta">${kind} · ${fmt.unit(lang, mb, "MB", 1)} · <time datetime="${iso}">${fmt.date(lang, iso)}</time></p></div><span class="sb-list-row__trail"><button class="sb-icon-button" type="button" aria-label="${d.download(name)}">${icon("download")}</button></span></li>`)}</ul>`),
    html`<p>${d.mediaNote}</p>`,
  ]);
}

function placesSection(s: Strings): Html {
  const d = s.data;
  const q = encodeURIComponent(d.mapAddress);
  return section("places", d.sections.places, [
    item(d.placeText, samples([[d.cityCountry, d.cityV], [html`${d.serverPlace} ${demo(s)}`, html`${icon("pin", 16)} ${d.serverV}`], [d.noCity, d.noCityV]])),
    item(d.map, html`<div class="sb-place">
  <div class="sb-place__address">${icon("pin", 20)}<div><p>${d.mapAddress}</p><p><a class="sb-place__link" href="geo:0,0?q=${q}">${d.openInMaps}${icon("external-link--16", 16)}</a></p></div></div>
  <svg class="sb-place__map" viewBox="0 0 360 180" width="360" height="180" role="img" aria-label="${d.mapLabel}">
    <rect class="sb-place__ground" width="360" height="180"/>
    <path class="sb-place__water" d="M0 150 C80 128 140 172 230 146 S330 112 360 124 V180 H0 Z"/>
    <path class="sb-place__road" d="M120 0 L136 180"/><path class="sb-place__road" d="M250 0 L238 140"/><path class="sb-place__road" d="M0 30 L120 36"/>
    <path class="sb-place__road sb-place__road--main" d="M0 76 L360 90"/>
    <circle class="sb-place__marker" cx="190" cy="62" r="20"/>
    <svg class="sb-icon sb-place__pin" x="178" y="50" width="24" height="24" aria-hidden="true" focusable="false"><use href="#pin"/></svg>
  </svg>
</div>`),
  ]);
}

function ratingSection(s: Strings, lang: Lang): Html {
  const d = s.data;
  const dist = [20, 11, 4, 2, 1];
  return section("rating", d.sections.rating, [
    item(d.ratingT, html`<p class="sb-rating">${icon("star--filled")}<span class="sb-visually-hidden">${d.ratingHidden}</span><span class="sb-rating__value">${d.ratingValue(fmt.num(lang, 4.2, 1))}</span> <span class="sb-rating__count">${d.ratingCount(38)}</span></p>
<figure class="sb-chart"><ul class="sb-chart__rows">${dist.map((c, i) => {
      const [label, value] = d.ratingRow(5 - i, c);
      return html`<li class="sb-chart__row"><span class="sb-chart__name">${label}<b>${value}</b></span><svg viewBox="0 0 100 12" preserveAspectRatio="none" aria-hidden="true" focusable="false"><rect class="sb-chart__fill" width="${(c / 20) * 100}" height="12"/></svg></li>`;
    })}</ul><figcaption>${d.ratingCaption} ${demo(s)}</figcaption></figure>`),
  ]);
}

function emptySection(s: Strings): Html {
  const d = s.data;
  return section("empty", d.sections.empty, [
    item(d.emptyT, html`<div class="sb-empty sb-empty--section"><p class="sb-empty__title">${d.emptyTitle}</p><p class="sb-empty__text">${d.emptyText}</p></div>`),
    item(d.noneT, html`<dl class="sb-meta-list"><div><dt>${d.reminder}</dt><dd>${s.common.none}</dd></div><div><dt>${d.phoneL}</dt><dd>${s.common.noValue}</dd></div><div><dt>${d.entriesL}</dt><dd class="sb-num">0</dd></div></dl>`),
    item(d.unknown, html`<dl class="sb-meta-list"><div><dt>${d.imageService}</dt><dd>${d.imageServiceV}</dd></div><div><dt>${d.servicePlace}</dt><dd><span class="sb-status sb-status--warning">${icon("pending--16", 16)}${d.notEvidenced}</span></dd></div></dl><p>${demo(s)}</p>`),
    item(d.loadError, html`<div class="sb-callout sb-callout--error" role="note" aria-labelledby="app-d-err-t">${icon("error--filled", 20)}<p class="sb-callout__title" id="app-d-err-t">${d.error}</p><p class="sb-callout__text">${d.loadErrorText}</p></div><div><button class="sb-secondary-action" type="button">${icon("refresh")}${d.reload}</button></div>`),
    item(d.loading, html`<div class="sb-skeleton" aria-busy="true" aria-describedby="app-d-load-text"><span class="sb-skeleton__line sb-skeleton__line--title"></span><span class="sb-skeleton__line sb-skeleton__line--long"></span><span class="sb-skeleton__line sb-skeleton__line--short"></span><p class="sb-loading" id="app-d-load-text">${icon("loader", 20, "sb-spinner")}${d.loadingText}</p></div>`),
    item(d.stale, html`<p class="sb-stale-notice">${icon("warning--filled-16", 16)}${d.staleText}</p><p>${demo(s)}</p>`),
  ]);
}

function evidenceSection(s: Strings): Html {
  const d = s.data;
  return section("evidence", d.sections.evidence, [
    item(d.footnote, html`<p>${d.claim1}<a class="sb-note-ref" id="app-ref-1" href="#app-beleg-1" role="doc-noteref" aria-label="${d.noteLabel(1)}" data-claim-text="${d.claim1}">1</a>. ${d.claim2}<a class="sb-note-ref" id="app-ref-2" href="#app-beleg-2" role="doc-noteref" aria-label="${d.noteLabel(2)}" data-claim-text="${d.claim2}">2</a>.</p>
<section class="sb-notes" role="doc-endnotes" aria-labelledby="app-notes-h"><h4 class="sb-notes__title" id="app-notes-h">${d.notesTitle} ${demo(s)}</h4><ol class="sb-notes__list">
  <li class="sb-note" id="app-beleg-1"><a class="sb-note__back" href="#app-ref-1" role="doc-backlink" aria-label="${d.backLabel(1)}">1</a><div class="sb-note__body"><p class="sb-note__result">${icon("success--filled-16", 16, "sb-check-glyph sb-check-glyph--passed")}${d.passedOn}</p><p class="sb-note__method">${d.method1}</p><p class="sb-note__limit">${d.limit1}</p><p class="sb-note__by">${d.byAuto}</p></div></li>
  <li class="sb-note" id="app-beleg-2"><a class="sb-note__back" href="#app-ref-2" role="doc-backlink" aria-label="${d.backLabel(2)}">2</a><div class="sb-note__body"><p class="sb-note__result">${icon("pending--16", 16, "sb-check-glyph sb-check-glyph--open")}${d.openPlace}</p><p class="sb-note__outflow">${d.outflow2}</p><p class="sb-note__limit">${d.limit2}</p><p class="sb-note__by">${d.byHand}</p></div></li>
</ol></section>`),
    item(d.claimRows, html`<section class="sb-claims-block" aria-labelledby="app-claims-h"><h4 class="sb-claims-block__title" id="app-claims-h">${d.claimBlock} ${demo(s)}</h4><ul class="sb-claim-rows">
  <li class="sb-claim-row"><button class="sb-claim-row__toggle" type="button" aria-expanded="true" aria-controls="app-n-konto"><span class="sb-claim-row__claim">${d.claimNoAccount}</span><span class="sb-claim-row__result">${icon("success--filled-16", 16, "sb-check-glyph sb-check-glyph--passed")}${d.claimPassed}</span>${icon("chevron-down", undefined, "sb-claim-row__chevron")}</button>
    <div class="sb-claim-row__note sb-note__body" id="app-n-konto"><p class="sb-note__method">${d.method1}</p><p class="sb-note__limit">${d.limit1}</p><p class="sb-note__by">${d.byAuto}</p></div></li>
  <li class="sb-claim-row"><button class="sb-claim-row__toggle" type="button" aria-expanded="false" aria-controls="app-n-bild"><span class="sb-claim-row__claim">${d.claimIp}</span><span class="sb-claim-row__result">${icon("pending--16", 16, "sb-check-glyph sb-check-glyph--open")}${d.claimOpen}</span>${icon("chevron-down", undefined, "sb-claim-row__chevron")}</button>
    <div class="sb-claim-row__note sb-note__body" id="app-n-bild" hidden><p class="sb-note__outflow">${d.outflow2}</p><p class="sb-note__limit">${d.limit2}</p><p class="sb-note__by">${d.byHand}</p></div></li>
</ul></section>`),
  ]);
}

export function dataView(): Html {
  n = 0;
  const s = t();
  const lang = currentLang();
  const d = s.data;
  const keys = Object.keys(d.sections) as Array<keyof Strings["data"]["sections"]>;
  return html`<div class="sb-view sb-view--wide" data-sb-view="daten">
  <div class="sb-view__content"><div class="sb-container">
    <div class="sb-stack">
      <h1 class="sb-type-headline app-view-title">${d.title}</h1>
      <p>${d.intro} ${demo(s)}</p>
      <nav aria-labelledby="app-d-toc-h"><h2 class="sb-type-label" id="app-d-toc-h">${d.toc}</h2><ul class="sb-cluster app-toc">${keys.map((k) => html`<li><a href="#app-d-${k}">${d.sections[k]}</a></li>`)}</ul></nav>
    </div>
    ${textSection(s, lang)}${numbersSection(s, lang)}${timeSection(s, lang)}${stateSection(s, lang)}${categoriesSection(s)}${identitySection(s, lang)}${techSection(s, lang)}${collectionsSection(s, lang)}${chartsSection(s, lang)}${mediaSection(s, lang)}${placesSection(s)}${ratingSection(s, lang)}${emptySection(s)}${evidenceSection(s)}
  </div></div>
  <div class="sb-bottom-block">
    <div class="sb-primary-action-bar">
      <div class="sb-primary-action-bar__message" role="status"></div>
      <p class="sb-primary-action-bar__status">${d.exportState}</p>
      <button class="sb-primary-action" type="button" data-app-export>${icon("download")}<span class="sb-primary-action__label">${d.export}</span><i class="sb-primary-action__bar" aria-hidden="true"></i></button>
      <p class="sb-action-hint">${d.exportHint}</p>
    </div>
  </div>
</div>`;
}

function csv(): string {
  const quote = (v: string) => `"${v.replace(/"/g, '""')}"`;
  const head = ["id", "title", "category", "due", "effort", "note", "state"];
  const rows = app.entries.map((e) => [e.id, e.title, e.category, e.due, String(e.effort), e.note, e.state].map(quote).join(";"));
  return [head.join(";"), ...rows].join("\n");
}

export function bindData(): void {
  // the multiple selection (DAT-08): arrows move focus, Space adds or removes, the count is the state sentence
  const box = document.querySelector<HTMLElement>("[data-app-listbox]");
  const status = document.getElementById("app-d-sel-status");
  if (box && status) {
    const options = () => Array.from(box.querySelectorAll<HTMLElement>("[role='option']"));
    const update = () => (status.textContent = t().data.selected(options().filter((o) => o.getAttribute("aria-selected") === "true").length));
    const toggle = (o: HTMLElement) => {
      o.setAttribute("aria-selected", String(o.getAttribute("aria-selected") !== "true"));
      update();
    };
    const focus = (o: HTMLElement) => {
      options().forEach((x) => {
        x.tabIndex = x === o ? 0 : -1;
        x.toggleAttribute("aria-current", x === o);
        if (x === o) x.setAttribute("aria-current", "true");
      });
      o.focus();
    };
    box.addEventListener("click", (event) => {
      const o = (event.target as Element).closest<HTMLElement>("[role='option']");
      if (!o) return;
      focus(o);
      toggle(o);
    });
    box.addEventListener("keydown", (event) => {
      const all = options();
      const at = all.indexOf(document.activeElement as HTMLElement);
      if (at < 0) return;
      const moves: Record<string, number> = { ArrowDown: at + 1, ArrowUp: at - 1, Home: 0, End: all.length - 1 };
      if (event.key in moves) {
        event.preventDefault();
        focus(all[Math.max(0, Math.min(all.length - 1, moves[event.key]))]);
      } else if (event.key === " " || event.key === "Enter") {
        event.preventDefault();
        toggle(all[at]);
      }
    });
  }
  // „Als CSV exportieren“: written on this device, saved where the browser saves downloads (BEL-10)
  document.querySelector("[data-app-export]")?.addEventListener("click", () => {
    const url = URL.createObjectURL(new Blob([csv()], { type: "text/csv;charset=utf-8" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = "musterapp-eintraege.csv";
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
}
