// strings.ts: every word the app shows, in one table per language (TEC-10, D87).
// index.html carries {{key}} markers; the Vite plugin in vite.config.ts fills them from this table at build time, so
// the page arrives finished (no flash of empty labels) and no word is built into the markup. main.ts takes the
// sentences it writes at run time from the same table (t()). The sebaro scripts bring their own German and English
// messages (sb-window.js, sb-menu.js, sb-tone.js …) and follow <html lang>.
// Voice (TXT-*): du, verb + thing, „…“ after a space, U+00A0 ( ) between number and unit, no sign inside a word
// for groups of people. All notes below are invented demo data (BEL-09: marked „Beispieldaten“ in the window).
// To add English: copy `de` to `en`, translate, and pick the table by <html lang> in t().

export const de = {
  "app.name": "Musterapp Desktop",
  "app.title": "{doc} · Musterapp Desktop",
  "app.titleSettings": "Einstellungen · Musterapp Desktop",
  "app.skip": "Zum Inhalt",
  "app.demo": "Beispieldaten",

  "win.place": "Ort: ",
  "win.notes": "Notizen",
  "win.tools": "Werkzeuge des Fensters",
  "tool.sidebar": "Seitenleiste",
  "tool.inspector": "Eigenschaften",
  "tool.palette": "Befehle",
  "tool.menu": "Menü",

  "menu.file": "Datei",
  "menu.edit": "Bearbeiten",
  "menu.view": "Darstellung",
  "menu.window": "Fenster",
  "menu.help": "Hilfe",
  "menu.newNote": "Neue Notiz",
  "menu.newWindow": "Neues Fenster",
  "menu.open": "Öffnen …",
  "menu.close": "Schließen",
  "menu.undo": "Widerrufen",
  "menu.redo": "Wiederholen",
  "menu.find": "Suchen",
  "menu.settings": "Einstellungen …",
  "menu.trash": "In den Papierkorb legen …",
  "menu.restore": "Zurücklegen",
  "menu.emptyTrash": "Papierkorb leeren …",
  "menu.sidebar": "Seitenleiste",
  "menu.inspector": "Inspektor",
  "menu.sidebarWidth": "Breite der Seitenleiste",
  "menu.narrow": "Schmal",
  "menu.normal": "Normal",
  "menu.wide": "Breit",
  "menu.theme": "Hell oder Dunkel",
  "menu.tone": "Farbton",
  "menu.motion": "Bewegung immer reduzieren",
  "menu.textBigger": "Schrift größer",
  "menu.textSmaller": "Schrift kleiner",
  "menu.palette": "Befehle …",
  "menu.nextArea": "Nächster Bereich",
  "menu.previousArea": "Vorheriger Bereich",
  "menu.back": "Zurück",
  "menu.forward": "Vor",
  "menu.tabForward": "Reiter nach vorn",
  "menu.tabBack": "Reiter nach hinten",
  "menu.shortcuts": "Tastaturkürzel",
  "menu.facts": "Fakten und Prüfungen",

  "choice.system": "Wie das System",
  "choice.light": "Hell",
  "choice.dark": "Dunkel",
  "choice.cool": "Kühl",
  "choice.warm": "Warm",

  "side.label": "Orte und Ordner",
  "side.all": "Alle Notizen",
  "side.recent": "Zuletzt",
  "side.search": "Notizen durchsuchen",
  "side.searchPlaceholder": "Suchen …",
  "side.folders": "Ordner",
  "side.trash": "Papierkorb",
  "side.trashTitle": "Hierher zieht man nichts: In den Papierkorb geht es über „In den Papierkorb legen …“ und den Dialog.",
  "side.settings": "Einstellungen",
  "side.width": "Breite der Seitenleiste",
  "side.noMatch": "Keine Notiz passt zu „{q}“.",

  "tabs.label": "Offene Notizen",
  "tabs.none": "Keine Notiz offen. Wähle eine im Ordner links.",
  "tabs.changed": ", geändert",
  "tabs.close": "Schließen",

  "insp.label": "Eigenschaften",
  "insp.width": "Breite des Inspektors",
  "insp.folder": "Ordner",
  "insp.created": "Angelegt",
  "insp.changed": "Geändert",
  "insp.words": "Wörter",
  "insp.size": "Größe",
  "insp.empty": "Keine Notiz gewählt.",
  "insp.noFolder": "keiner",
  "insp.bin": "Papierkorb",
  "insp.binNotes": "{n} Notizen",
  "insp.binOne": "1 Notiz",
  "insp.binEmpty": "leer",
  "insp.from": "Lag in",
  "insp.fromRoot": "keinem Ordner",
  "insp.restore": "Zurücklegen",
  "insp.emptyTrash": "Papierkorb leeren …",

  "status.unsaved": "nicht gesichert",
  "status.online": "nur online",
  "zone.saved": "Alles gesichert.",
  "zone.unsavedOne": "1 Notiz nicht gesichert.",
  "zone.unsavedMany": "{n} Notizen nicht gesichert.",
  "zone.words": "{n} Wörter",
  "zone.chars": "{n} Zeichen",
  "zone.newNote": "Neue Notiz",
  "zone.hint": "Bleibt auf diesem Gerät.",
  "zone.newNoteName": "Neue Notiz {n}",
  "zone.trashed": "„{name}“ liegt im Papierkorb.",
  "zone.restored": "„{name}“ liegt wieder in „{folder}“.",
  "zone.restoredRoot": "„{name}“ liegt wieder bei den Notizen.",
  "zone.emptied": "Der Papierkorb ist leer.",

  "doc.meta": "{folder} · geändert {when}",
  "doc.today": "heute, {time}",
  "doc.empty": "Noch leer. Schreib los, sobald die App einen Editor hat.",
  "doc.size": "{n} KB",

  "palette.label": "Befehle",
  "palette.search": "Befehl oder Einstellung suchen",
  "palette.groupFile": "Ablage",
  "palette.groupView": "Ansicht",
  "palette.groupLook": "Darstellung",
  "palette.groupPlaces": "Orte",
  "palette.toneWarm": "Farbton Warm",
  "palette.search2": "Suche",
  "palette.settings": "Einstellungen",
  "palette.move": "wechseln",
  "palette.run": "ausführen",
  "palette.close": "schließen",
  "palette.spokenUpDown": "Pfeil nach oben, Pfeil nach unten",
  "palette.spokenEnter": "Eingabe",
  "palette.spokenEscape": "Escape",

  "dlg.cancel": "Abbrechen",
  "dlg.trashTitle": "„{name}“ in den Papierkorb legen?",
  "dlg.trashText": "Die Notiz „{name}“ kommt in den Papierkorb. Von dort kannst du sie zurückholen.",
  "dlg.trashConfirm": "In den Papierkorb legen",
  "dlg.emptyTitle": "Papierkorb leeren?",
  "dlg.emptyTextOne": "Die Notiz „{name}“ im Papierkorb wird endgültig gelöscht. Das lässt sich nicht rückgängig machen.",
  "dlg.emptyTextMany": "Die {n} Notizen im Papierkorb werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.",
  "dlg.emptyConfirm": "Papierkorb leeren",
  "dlg.unsavedTitle": "Änderungen an „{name}“ sichern?",
  "dlg.unsavedText": "Ohne Sichern gehen die Änderungen seit {time} verloren. Die Notiz bleibt.",
  "dlg.discard": "Verwerfen",
  "dlg.save": "Sichern",
  "dlg.shortcutsTitle": "Tastaturkürzel",
  "dlg.shortcutsText": "Diese 15 Kürzel gelten in jeder sebaro-Desktop-App. Unter Windows und Linux steht Strg statt ⌘.",
  "dlg.shortcutsCaption": "Die festen Kürzel",
  "dlg.shortcutsKey": "Kürzel",
  "dlg.shortcutsWhat": "Was es tut",
  "dlg.close": "Schließen",

  "sc.palette": "Befehle öffnen",
  "sc.settings": "Einstellungen",
  "sc.new": "Hauptaktion: Neue Notiz",
  "sc.open": "Öffnen",
  "sc.find": "Suchen",
  "sc.sidebar": "Seitenleiste ein oder aus",
  "sc.inspector": "Inspektor ein oder aus",
  "sc.areas": "Nächster oder vorheriger Bereich",
  "sc.tabs": "Nächster oder vorheriger Reiter",
  "sc.close": "Reiter schließen",
  "sc.window": "Neues Fenster",
  "sc.undo": "Widerrufen und Wiederholen",
  "sc.trash": "In den Papierkorb legen …",
  "sc.text": "Schrift des Inhalts größer oder kleiner",
  "sc.history": "Zurück und Vor",

  "set.path": "Einstellungen",
  "set.back": "Zurück zu {doc}",
  "set.heading": "Einstellungen",
  "set.meta": "Gilt für alle Fenster von Musterapp Desktop. Jede Wahl wirkt sofort.",
  "set.groupLook": "Darstellung",
  "set.theme": "Hell oder Dunkel",
  "set.themeHelp": "„Wie das System“ folgt der Einstellung deines Rechners.",
  "set.tone": "Farbton",
  "set.toneHelp": "Warm färbt nur Grund, Text und Linien, alles andere bleibt.",
  "set.motion": "Bewegung immer reduzieren",
  "set.motionHelp": "Neues erscheint dann ohne Bewegung, es wird nur eingeblendet. Gilt auch, wenn das System Bewegung zulässt.",
  "set.groupNotes": "Notizen",
  "set.autosave": "Beim Schließen sichern",
  "set.autosaveHelp": "Schließt du einen Reiter mit Änderungen, sichert die App ohne zu fragen.",
} as const;

export type Key = keyof typeof de;

const tables: Record<string, Record<Key, string>> = { de };

/** The word or sentence for `key` in the page's language, with {name} placeholders filled. */
export function t(key: Key, values: Record<string, string | number> = {}): string {
  const lang = (document.documentElement.lang || "de").split("-")[0];
  const text = (tables[lang] ?? de)[key];
  return text.replace(/\{(\w+)\}/g, (_, name: string) => String(values[name] ?? `{${name}}`));
}

// Demo notes (invented, BEL-09). A real app reads its documents instead; their text is data, not UI words.
export type Note = {
  id: string;
  name: string;
  folder: "projekte" | "journal" | null;
  created: string;
  changed: string;
  paragraphs: string[];
  unsaved?: boolean;
  online?: boolean;
  /** in the bin: out of its folder, back with „Zurücklegen“, gone for good with „Papierkorb leeren …“ (AKT-08) */
  trashed?: boolean;
};

export const folders = [
  { id: "projekte", name: "Projekte", open: true },
  { id: "journal", name: "Journal", open: false },
] as const;

export const demoNotes: Note[] = [
  {
    id: "wochenplan", name: "Wochenplan", folder: "projekte", created: "2026-09-02", changed: "2026-10-28T09:40", unsaved: true,
    paragraphs: [
      "Diese Woche bleibt ruhig. Zwei Termine stehen fest, der Rest ist Platz für Liegengebliebenes.",
      "Montag: Unterlagen sortieren, danach das Fahrrad zur Werkstatt. Mittwoch: 45 Min. laufen. Freitag: Einkauf für 4 Personen.",
      "Offen von letzter Woche: die Gartenplanung und zwei Rückrufe. Beides passt gut auf Donnerstag.",
    ],
  },
  {
    id: "umzug", name: "Umzug Checkliste", folder: "projekte", created: "2026-08-14", changed: "2026-10-21T18:05",
    paragraphs: ["Kartons beschriften, Zählerstände notieren, die neue Adresse an 6 Stellen melden."],
  },
  {
    id: "garten", name: "Gartenplan für das Frühjahr mit Beeten und Pflanzzeiten", folder: "projekte", created: "2026-07-30", changed: "2026-10-12T07:15",
    paragraphs: ["Drei Beete, je 1,2 m breit. Bohnen an den Zaun, Kräuter ans Haus."],
  },
  {
    id: "oktober", name: "27. Oktober", folder: "journal", created: "2026-10-27", changed: "2026-10-27T21:30",
    paragraphs: ["Ein ruhiger Tag. Abends 30 Min. gelesen."],
  },
  {
    id: "einkauf", name: "Einkauf", folder: null, created: "2026-10-01", changed: "2026-10-26T12:00", online: true,
    paragraphs: ["Brot, Äpfel, 2 l Milch, Kaffee."],
  },
];
