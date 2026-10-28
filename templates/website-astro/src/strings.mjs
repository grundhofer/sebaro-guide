// strings.mjs: every word the website shows, per language (TEC-10). Pages and components read only from here.
// German follows the voice rules of sebaro (TXT-01 to TXT-17): „du“, verb + thing, „…“ after a space, U+00A0 (written
//  ) between number and unit, German quotes, no gender signs. Fragments with markup (links, footnote digits)
// are HTML strings and are rendered with set:html; they hold no user input.
// Everything here is example content of a fictive site („Beispielseite“, „Alex Beispiel“, example.org): replace it.
// Plain JavaScript (not TypeScript) so scripts/og.mjs can read the same titles with Node alone.

export const SITE = {
  name: "Beispielseite",
  origin: "https://example.org",
  /** product id of the share images (WEB-09): the umbrella sign of sebaro as a placeholder, see README */
  product: "studio",
};

const nb = " ";

export const strings = {
  de: {
    skip: "Zum Inhalt",
    titleSuffix: " · Beispielseite",
    wordmark: "Beispiel\u00adseite",
    nav: { label: "Hauptmenü", apps: "Apps", projects: "Projekte", about: "Über", contact: "Kontakt" },
    language: { label: "Sprache", missing: ": diese Seite gibt es nicht auf Englisch" },
    theme: "Hell oder Dunkel",
    breadcrumb: "Brotkrumen",
    demo: "Beispieldaten",
    footer: {
      copyright: "© 2026 Alex Beispiel · sebaro",
      links: { imprint: "Impressum", privacy: "Datenschutz", accessibility: "Barrierefreiheit" },
      display: "Darstellung",
      tone: "Farbton",
      cool: "Kühl",
      warm: "Warm",
    },
    notePopover: { close: "Schließen" },
    codeCopy: "Kopieren",
    pages: {
      start: {
        title: "Kleine Werkzeuge, ruhig gebaut.",
        description: "Projekte und Notizen von Alex Beispiel, gebaut mit sebaro.",
        lead: "Auf dieser Seite stelle ich meine Projekte vor und schreibe auf, wie sie gebaut sind.",
        secondary: "Über mich",
        primary: "Projekte ansehen",
        recentTitle: "Zuletzt geschrieben",
        recentEnd: "Mehr steht noch nicht hier.",
      },
      apps: {
        title: "Apps",
        description: "Die Apps von Alex Beispiel.",
        emptyTitle: "Noch keine App",
        emptyText: "Sobald die erste App erscheint, steht sie hier mit ihrer Kachel, ihren Plattformen und ihren Fakten.",
      },
      projects: {
        title: "Projekte",
        description: "Notizen dazu, wie Alex Beispiel kleine Werkzeuge baut.",
        lead: "Notizen dazu, wie ich baue. Das Neueste steht oben.",
        listTitle: "Alle Notizen",
        end: "Das ist bisher alles.",
      },
      article: {
        title: "Eine Liste als CSV-Datei sichern",
        crumb: "Liste als CSV",
        description: "Wie eine Liste zur CSV-Datei wird, die jede Tabellenkalkulation öffnet.",
        readingMinutes: 5,
        date: "2026-10-20",
        dateText: "20.10.2026",
        meta: (minutes) => `${minutes}${nb}Min. Lesezeit · aktualisiert am `,
        tocLabel: "Inhalt dieses Artikels",
        tocTitle: "Inhalt",
        sections: [
          { id: "worum", title: "Worum es geht" },
          { id: "aufbau", title: "Wie die Datei aussieht" },
          { id: "umlaute", title: "Umlaute und Trennzeichen" },
          { id: "offen", title: "Was offen bleibt" },
        ],
        intro: [
          "Eine CSV-Datei ist eine Tabelle als reiner Text: eine Zeile je Eintrag, die Werte durch ein Zeichen getrennt. " +
            "Fast jedes Programm kann sie lesen, auch in zehn Jahren noch." +
            '<a class="sb-note-ref" id="fnref-1" href="#fn-1" role="doc-noteref" aria-label="Fußnote 1">1</a>',
          "Darum biete ich in jedem Werkzeug, das Listen führt, den Export als CSV an. Hier steht, worauf ich dabei achte.",
        ],
        aufbau: [
          "Die erste Zeile nennt die Spalten, jede weitere ist ein Eintrag. Ein Wert, der selbst ein Trennzeichen oder " +
            "einen Zeilenumbruch enthält, steht in doppelten Anführungszeichen.",
        ],
        codeLang: "JavaScript",
        codeLabel: "Beispiel: eine Zeile der CSV-Datei schreiben",
        // the code as tokens: [look, text]; looks are the five of TXT-10 (keyword, string, constant, comment, plain)
        code: [
          [["comment", "// eine Zeile je Eintrag, die Werte mit Semikolon getrennt"]],
          [["keyword", "const"], ["plain", " zeile = (eintrag) => ["], ["plain", "eintrag.datum, eintrag.name, eintrag.menge"], ["plain", "].join("], ["string", "\";\""], ["plain", ");"]],
          [["keyword", "const"], ["plain", " kopf = "], ["string", "\"datum;name;menge\""], ["plain", ";"]],
          [["keyword", "const"], ["plain", " maximal = "], ["constant", "10000"], ["plain", ";"]],
        ],
        umlaute: [
          "Die Datei ist in UTF-8 gespeichert, damit „Größe“ und „Straße“ so ankommen, wie du sie geschrieben hast." +
            '<a class="sb-note-ref" id="fnref-2" href="#fn-2" role="doc-noteref" aria-label="Fußnote 2">2</a>',
          "Als Trennzeichen nehme ich das Semikolon, weil das Komma in deutschen Zahlen schon vorkommt: „12,90“ " +
            "bliebe sonst nicht eine Zahl." +
            '<a class="sb-note-ref" id="fnref-1-2" href="#fn-1" role="doc-noteref" aria-label="Fußnote 1">1</a>',
        ],
        calloutTitle: "Hinweis",
        calloutText: "Öffnet eine Tabellenkalkulation die Datei in einer einzigen Spalte, wähl beim Öffnen das Semikolon als Trennzeichen.",
        offen: [
          "Noch nicht gelöst ist ein Export, der Formeln mitnimmt. Eine CSV-Datei kennt nur Werte; wer Formeln braucht, " +
            "braucht ein anderes Format.",
        ],
        quote: "„Ich will meine Liste auch ohne die App öffnen können.“",
        quoteSource: "Rückmeldung per E-Mail, Oktober 2026",
        notesTitle: "Fußnoten",
        notes: [
          {
            id: "fn-1",
            backs: [
              { href: "#fnref-1", label: "Zurück zur Stelle 1", text: "1" },
              { href: "#fnref-1-2", label: "Zurück zur Stelle 1 (2)", text: "1b" },
            ],
            html: 'Das Format beschreibt <a href="https://www.rfc-editor.org/rfc/rfc4180">RFC 4180<svg class="sb-icon sb-icon--16" aria-hidden="true" focusable="false"><use href="#external-link--16"/></svg></a>; es legt das Komma fest, viele Programme lesen aber auch das Semikolon.',
          },
          {
            id: "fn-2",
            backs: [{ href: "#fnref-2", label: "Zurück zur Stelle 2", text: "2" }],
            html: "Manche ältere Programme erkennen UTF-8 nur mit einer Markierung am Dateianfang.",
          },
        ],
        pagerLabel: "Weiter:",
        pagerTitle: "Wer diese Seite schreibt",
      },
      about: {
        title: "Über",
        description: "Wer die Beispielseite schreibt und wie.",
        heading: "Über mich",
        personName: "Alex Beispiel",
        initials: "AB",
        text: [
          "Ich heiße Alex Beispiel und baue kleine Werkzeuge für den Alltag: Listen, Zähler, Notizen.",
          "Ich schreibe hier mit „ich“, weil hinter dieser Seite eine Person steht und keine Firma.",
        ],
        factsTitle: "Kurz",
        facts: [
          ["Ort", "Beispielstadt"],
          ["Sprachen", "Deutsch, Englisch"],
          ["Schwerpunkt", "Apps ohne Konto"],
        ],
      },
      contact: {
        title: "Kontakt",
        description: "So erreichst du Alex Beispiel.",
        text: `Schreib mir eine E-Mail. Ich antworte meist innerhalb von 3${nb}Werktagen.`,
        mailLabel: "E-Mail schreiben",
        mail: "example@example.org",
        hint: "Nur auf deinen Befehl. Ziel: dein E-Mail-Programm, dann mein Postfach.",
      },
      imprint: {
        title: "Impressum",
        description: "Pflichtangaben zur Beispielseite.",
        legalTitle: "Angaben nach § 5 Digitale-Dienste-Gesetz (DDG)",
        address: ["Alex Beispiel", "Musterweg 1", "12345 Beispielstadt", "Deutschland"],
        contactTitle: "Kontakt",
        mailPrefix: "E-Mail: ",
        mail: "example@example.org",
        disputeTitle: "Streitbeilegung",
        dispute: "Ich nehme nicht an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teil.",
        notice: "Alle Angaben sind erfunden. Was ins Impressum gehört, entscheidet das Recht, nicht diese Vorlage; sie ist keine Rechtsberatung.",
      },
      privacy: {
        title: "Datenschutz",
        description: "Was beim Besuch der Beispielseite wohin geht und wie lange es bleibt.",
        stand: "Stand 20.10.2026",
        responsible: "Verantwortlich: Alex Beispiel, Anschrift im Impressum.",
        tableTitle: "Was beim Besuch passiert",
        caption: "Daten, Zweck und Speicherdauer",
        head: ["Was", "Wozu", "Wie lange"],
        rows: [
          ["IP-Adresse, Zeit, aufgerufene Seite", "Betrieb des Servers, Abwehr von Angriffen", `7${nb}Tage`],
          ["Wahl „Hell oder Dunkel“ und Farbton", "nur in deinem Browser, nie auf dem Server", "bis du sie löschst"],
        ],
        rightsTitle: "Deine Rechte",
        rights: "Du kannst fragen, was ich über dich gespeichert habe, und verlangen, dass ich es berichtige oder lösche. Schreib dafür an die Adresse im Impressum.",
        notice: "Alle Angaben sind erfunden. Was eine Datenschutzerklärung enthalten muss, entscheidet das Recht, nicht diese Vorlage.",
      },
      accessibility: {
        title: "Barrierefreiheit",
        description: "Wie barrierefrei die Beispielseite ist und was noch fehlt.",
        stand: "Stand 20.10.2026",
        whatTitle: "Was diese Seite ist",
        what: "Die Seite stellt Projekte vor. Man kann dort nichts kaufen und kein Konto anlegen.",
        useTitle: "So benutzt du die Seite",
        use: "Jede Seite hat oben einen Sprunglink „Zum Inhalt“. Mit der Tabulatortaste erreichst du jeden Link und jede Taste; der Fokus ist ein Ring in Kobalt. „Hell oder Dunkel“ wechselt die Darstellung, ohne dass sich sonst etwas ändert.",
        checksTitle: "Wie die Seite die Anforderungen erfüllt",
        checksIntro: "Ziel ist WCAG 2.2 Stufe AA. Geprüft wurde:",
        checks: [
          { state: "passed", word: "bestanden", title: "axe in Chromium auf jeder Seite, hell und dunkel", meta: "bestanden am 20.10.2026 · Eigene Prüfung, automatisch" },
          { state: "passed", word: "bestanden", title: `Doppelte Schriftgröße bei 320, 390 und 1440${nb}px`, meta: "bestanden am 20.10.2026 · Eigene Prüfung, automatisch" },
          { state: "skipped", word: "übersprungen", title: "Bildschirmleser auf dem Telefon", meta: "übersprungen am 20.10.2026 · Eigene Prüfung, von Hand", reason: "Grund: Kein Testgerät verfügbar." },
          { state: "open", word: "offen", title: `Vergrößerung auf 400${nb}%`, meta: "noch nicht gelaufen · Eigene Prüfung, von Hand" },
        ],
        limitsTitle: "Bekannte Einschränkungen",
        limits: "Mit einem Bildschirmleser auf dem Telefon ist die Seite noch nicht geprüft; ob dort jede Ansage stimmt, ist offen.",
        feedbackTitle: "Rückmeldung",
        feedbackPrefix: "Findest du eine Barriere, schreib an ",
        feedbackSuffix: `. Ich antworte innerhalb von 2${nb}Wochen.`,
        mail: "example@example.org",
        authorityTitle: "Zuständige Behörde",
        authority: "Marktüberwachungsstelle der Länder für die Barrierefreiheit von Produkten und Dienstleistungen (MLBF).",
        notice: "Alle Angaben sind Beispiele. Eine echte Erklärung nennt nur, was wirklich geprüft wurde.",
      },
      notFound: {
        title: "Diese Seite gibt es nicht",
        text: "Unter dieser Adresse liegt nichts. Vielleicht ein Tippfehler: Alle Seiten erreichst du über das Menü oben.",
        details: "Technische Angaben",
        status: "Status ",
        primary: "Zur Startseite",
      },
    },
  },
  en: {
    skip: "Skip to content",
    titleSuffix: " · Beispielseite",
    wordmark: "Beispiel\u00adseite",
    nav: { label: "Main menu", apps: "Apps", projects: "Projects", about: "About", contact: "Contact" },
    language: { label: "Language", missing: ": this page does not exist in German" },
    theme: "Light or dark",
    breadcrumb: "Breadcrumbs",
    demo: "Sample data",
    footer: {
      copyright: "© 2026 Alex Beispiel · sebaro",
      links: { imprint: "Imprint", privacy: "Privacy", accessibility: "Accessibility" },
      display: "Display",
      tone: "Colour tone",
      cool: "Cool",
      warm: "Warm",
    },
    notePopover: { close: "Close" },
    codeCopy: "Copy",
    germanOnly: "in German",
    pages: {
      start: {
        title: "Small tools, built calmly.",
        description: "Projects and notes by Alex Beispiel, built with sebaro.",
        lead: "On this site I present my projects and write down how they are built.",
        secondary: "About me",
        primary: "See projects",
        recentTitle: "Recently written",
        recentEnd: "Nothing more here yet.",
        articleMeta: (minutes) => `${minutes}${nb}min read · updated `,
        articleDate: "2026-10-20",
      },
    },
  },
};

/** Every page with a title of its own, for the share images (WEB-09) and the navigation. */
export const PAGES = [
  { id: "start", lang: "de", url: "/", key: "start", type: "website" },
  { id: "start-en", lang: "en", url: "/en/", key: "start", type: "website" },
  { id: "apps", lang: "de", url: "/apps/", key: "apps", nav: "apps" },
  { id: "projekte", lang: "de", url: "/projekte/", key: "projects", nav: "projects" },
  { id: "csv", lang: "de", url: "/projekte/liste-als-csv/", key: "article", nav: "projects" },
  { id: "ueber", lang: "de", url: "/ueber/", key: "about", nav: "about" },
  { id: "kontakt", lang: "de", url: "/kontakt/", key: "contact", nav: "contact" },
  { id: "impressum", lang: "de", url: "/impressum/", key: "imprint" },
  { id: "datenschutz", lang: "de", url: "/datenschutz/", key: "privacy" },
  { id: "barrierefreiheit", lang: "de", url: "/barrierefreiheit/", key: "accessibility" },
];
