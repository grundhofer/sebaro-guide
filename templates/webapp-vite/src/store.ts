// store.ts: the app's entries, kept in localStorage on this device only (BEL-10: „Bleibt auf diesem Gerät.“).
// The first start writes example entries (BEL-09: the list marks them „Beispieldaten“ until you change them).
import type { Lang } from "./strings";

export type Category = "none" | "home" | "work" | "garden" | "health";
export type State = "open" | "done" | "closed";

export type Entry = {
  id: string;
  title: string;
  category: Category;
  due: string; // ISO date, "" when none
  effort: number; // minutes
  note: string;
  steps: string[];
  state: State;
  created: string; // ISO date
  demo: boolean;
};

const KEY = "musterapp-entries";

// example content in both languages; the user's own entries are never translated
const SEED: Record<Lang, Array<[string, Category, string, number, string, State]>> = {
  de: [
    ["Wasser trinken", "health", "2026-10-30", 5, "", "open"],
    ["Rosen schneiden", "garden", "2026-11-02", 45, "Vor dem ersten Frost, mit der scharfen Schere.", "open"],
    ["Steuerunterlagen sortieren", "work", "", 90, "", "done"],
    ["Fenster putzen", "home", "2026-11-08", 60, "", "open"],
  ],
  en: [
    ["Drink water", "health", "2026-10-30", 5, "", "open"],
    ["Prune the roses", "garden", "2026-11-02", 45, "Before the first frost, with the sharp shears.", "open"],
    ["Sort tax papers", "work", "", 90, "", "done"],
    ["Clean the windows", "home", "2026-11-08", 60, "", "open"],
  ],
};

export function seed(lang: Lang): Entry[] {
  return SEED[lang].map(([title, category, due, effort, note, state], i) => ({
    id: String(i + 1),
    title,
    category,
    due,
    effort,
    note,
    steps: [],
    state,
    created: "2026-10-10",
    demo: true,
  }));
}

export function load(lang: Lang): Entry[] {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return JSON.parse(raw) as Entry[];
  } catch {
    // storage blocked or broken: start with the examples, keep nothing
  }
  const fresh = seed(lang);
  save(fresh);
  return fresh;
}

export function save(entries: Entry[]): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(entries));
  } catch {
    // storage blocked (private mode): the entries live until the tab closes
  }
}

export function nextId(entries: Entry[]): string {
  return String(entries.reduce((m, e) => Math.max(m, Number(e.id) || 0), 0) + 1);
}
