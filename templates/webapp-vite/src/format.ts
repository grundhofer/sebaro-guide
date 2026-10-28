// format.ts: numbers, money, dates and times by the page's language (TXT-04, TXT-12, TEC-10). Everything goes through
// Intl, then one rule: between a number and its unit stands U+00A0, never U+202F or U+2009 (some Intl outputs use those).
import type { Lang } from "./strings";

const NBSP = "\u00a0";
const clean = (s: string) => s.replace(/[\u202f\u2009]/g, NBSP);
const loc = (lang: Lang) => (lang === "de" ? "de-DE" : "en-GB");

/** 10.000 (de) / 10,000 (en); digits = fixed fraction digits */
export function num(lang: Lang, n: number, digits?: number): string {
  const opts: Intl.NumberFormatOptions = digits === undefined ? {} : { minimumFractionDigits: digits, maximumFractionDigits: digits };
  return clean(new Intl.NumberFormat(loc(lang), opts).format(n));
}

/** 12,90 € (de) / €12.90 (en) */
export function money(lang: Lang, n: number): string {
  return clean(new Intl.NumberFormat(loc(lang), { style: "currency", currency: "EUR" }).format(n));
}

/** 60 % (de, with U+00A0) / 60% (en) */
export function percent(lang: Lang, n: number): string {
  return lang === "de" ? `${num(lang, n)}${NBSP}%` : `${num(lang, n)}%`;
}

/** a number and its unit word, joined by U+00A0: „8 Gläser“, „12 Min.“ */
export function unit(lang: Lang, n: number, word: string, digits?: number): string {
  return `${num(lang, n, digits)}${NBSP}${word}`;
}

function parseDate(iso: string): Date {
  const [y, m, d] = iso.slice(0, 10).split("-").map(Number);
  const date = new Date(y, m - 1, d);
  if (iso.length > 10) {
    const [hh, mm] = iso.slice(11, 16).split(":").map(Number);
    date.setHours(hh, mm);
  }
  return date;
}

/** 10.10.2026 (de) / 2026-10-10 (en), as the guide's data page writes them */
export function date(lang: Lang, iso: string): string {
  if (lang === "en") return iso.slice(0, 10);
  const d = parseDate(iso);
  return clean(new Intl.DateTimeFormat("de-DE", { day: "2-digit", month: "2-digit", year: "numeric" }).format(d));
}

/** 10.10. (de) / 10 Oct (en): day and month without the year */
export function dayMonth(lang: Lang, iso: string): string {
  const d = parseDate(iso);
  if (lang === "de") return clean(new Intl.DateTimeFormat("de-DE", { day: "2-digit", month: "2-digit" }).format(d));
  return clean(new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short" }).format(d));
}

/** Samstag, 10. Oktober (de) / Saturday 10 October (en) */
export function dateLong(lang: Lang, iso: string): string {
  return clean(new Intl.DateTimeFormat(loc(lang), { weekday: "long", day: "numeric", month: "long" }).format(parseDate(iso)));
}

/** 08:12, always 24 hours (TXT-04) */
export function time(lang: Lang, iso: string): string {
  return clean(new Intl.DateTimeFormat(loc(lang), { hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).format(parseDate(iso)));
}

/** weekday: long „Samstag“ or the two letters of chart axes and calendar heads „Sa“ */
export function weekday(lang: Lang, iso: string, short = false): string {
  const long = new Intl.DateTimeFormat(loc(lang), { weekday: "long" }).format(parseDate(iso));
  return short ? long.slice(0, 2) : long;
}
