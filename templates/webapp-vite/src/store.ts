// store.ts: the app's entries, kept in localStorage on this device only (BEL-10: „Bleibt auf diesem Gerät.“).
// The first start writes example entries (BEL-09: the list marks them „Beispieldaten“ until you change them).
import { STRINGS, type Lang } from "./strings";

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
  /** which example of SEED this is (only while demo is true it counts as that example) */
  sample?: number;
};

const KEY = "musterapp-entries";

// the example entries: their words are in strings.ts (`samples`, same order); the user's own entries are never translated
const SEED: Array<[Category, string, number, State]> = [
  ["health", "2026-10-30", 5, "open"],
  ["garden", "2026-11-02", 45, "open"],
  ["work", "", 90, "done"],
  ["home", "2026-11-08", 60, "open"],
];

function example(lang: Lang, i: number, id: string): Entry {
  const [category, due, effort, state] = SEED[i];
  const { title, note } = STRINGS[lang].samples[i];
  return { id, title, category, due, effort, note, steps: [], state, created: "2026-10-10", demo: true, sample: i };
}

export function seed(lang: Lang): Entry[] {
  return SEED.map((_, i) => example(lang, i, String(i + 1)));
}

/** The examples that are missing (deleted, or changed and so the user's own), added after the user's entries with new
 *  ids. Nothing is removed or replaced, so this asks nothing (AKT-08 is about destroying data). */
export function missingExamples(entries: Entry[], lang: Lang): Entry[] {
  const present = new Set(entries.filter((e) => e.demo).map((e) => e.sample));
  const added: Entry[] = [];
  SEED.forEach((_, i) => {
    if (!present.has(i)) added.push(example(lang, i, nextId([...entries, ...added])));
  });
  return added;
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
