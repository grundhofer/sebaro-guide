# Agenten-Test 2026-10: fünf Probeaufgaben

Stand 28.10.2026, Guide 2.16.0. Geprüft wurde, ob ein fremder Agent mit dem, was der Guide ihm gibt, regelkonforme
sebaro-Oberflächen baut, und an welchen Texten es liegt, wenn nicht.

## Vorgehen

- **Fünf erfundene Aufgaben**, jede mit drei bis vier Bildschirmen, je in einem eigenen Ordner außerhalb des Repositorys,
  ausgehend von einer Vorlage:

  | Aufgabe | Art | Vorlage |
  |---|---|---|
  | „Musterapp Gewohnheiten“: Heute, Gewohnheit mit Heatmap, Formular, Einstellungen | Web-App ohne Fenster | `webapp-vite` |
  | „Musterverein Ruderclub“: Start, Termine, Mitglied werden, Kontakt | Website, nur Deutsch | `website-astro` |
  | „Musterapp Notizen“: Fenster mit Seitenleiste, Notiz mit Inspektor, Papierkorb, Einstellungen | Desktop (Tauri-Webview) | `desktop-tauri` |
  | „Musterapp Einkauf“: Listen, Liste, Artikel, Einstellungen | Web-App ohne Fenster, vor allem am Handy | `webapp-vite` |
  | „Musterapp Tagebuch“: Einträge, Eintrag, Schreiben, Einstellungen | Web-App ohne Fenster | `webapp-vite` |

- **Bauen:** je ein frischer Agent ohne Vorwissen. Im Projekt lag das eingefügte `AGENTS-snippet.md`; lesen durfte er
  nur eine Kopie von `docs/` (mit `llms.txt` und `rules.json`), `guide/RULES.md`, die Prüfliste und seine Vorlage,
  nicht `AGENTS.md` des Guides. Jeder endete mit grünem `npm ci && npm run build && npm test` und einer Übergabe mit
  allem, worin er unsicher war.
- **Prüfen:** je ein zweiter, unabhängiger Agent gegen alle 228 Regeln („eingehalten / verletzt / nicht betroffen“, mit
  Datei:Zeile und Herkunft „Vorlage“ oder „Agent“), dazu Bildschirmfotos hell und dunkel bei 390 und 1440&nbsp;px (Desktop
  480 und 1440&nbsp;px) und bei echten 200&nbsp;% Schrift, ein Tastaturlauf und axe. Danach liefen die Tests jeder Lösung
  noch einmal mit `CI=1` auf eigenem Port (siehe „Port“ unten).

## Ergebnis je Lösung

| Lösung | eingehalten | verletzt | davon aus der Vorlage | nicht betroffen | `npm test` (Wiederholung) |
|---|---|---|---|---|---|
| Gewohnheiten | 112 | 15 | 8 | 101 | 347 bestanden, Exit 0 |
| Verein | 107 | 10 | 1 | 111 | RERUN_VEREIN |
| Notizen | 117 | 16 | 5 | 95 | RERUN_NOTIZEN |
| Einkauf | 105 | 20 | 8 | 103 | 383 bestanden, Exit 0 |
| Tagebuch | 108 | 14 | 9 | 106 | RERUN_TAGEBUCH |

Alle fünf hielten die zehn Regeln von `AGENTS.md` §2 ein: eine Hauptaktion unten und zuletzt, Löschen mit Dialog,
Status als Zeichen und Wort, Ebenen mit Tintenlinie, Ortslinie, Links, nur Tokens. axe meldete nichts, keine Seite
scrollte bei 200&nbsp;% seitlich. 75 Verstöße insgesamt, 31 davon aus der Vorlage übernommen.

## Wiederholt verfehlt

Fehlerquote = Lösungen mit Verstoß / Lösungen, die die Regel betrifft. Belege nennen die Fundstelle in den
Probelösungen; die Ursache ist am Text des Guides belegt.

| Regel | Fehlerquote | Ursache | Änderung |
|---|---|---|---|
| TEC-06 `CHECKS.md` | 5/5 (eine Prüfung zählte die Übergabe als Ersatz) | Snippet sagt es nicht: `CHECKS.md` steht nur in `RULES.md`, in keiner Vorlage, nicht in Snippet, Prüfliste oder einer README. | Snippet (Liste „Easily missed“), Prüfliste „Done“, alle drei READMEs |
| TXT-04 U+00A0 | 4/5 | Vorlage zeigt es nicht sichtbar: `webapp-vite/src/strings.ts` schreibt „200 % Schrift“ mit einem unsichtbaren U+00A0; wer den Satz neu tippt, verliert es (Einkauf `strings.ts:181`, Tagebuch `strings.ts:143`, Gewohnheiten). Snippet nennt U+00A0 nicht. | Snippet und Prüfliste: ` ` schreiben, grep-Befehl; README `webapp-vite` |
| EBE-05 Kurzmeldung | 4/4 | Vorlage zeigt es falsch: „Alle Beispiele sind schon da.“ meldet, dass nichts geschah, und ihr „Rückgängig“ bleibt sichtbar, weil `action.hidden` gegen `display` von `.sb-toast__action` verliert (`webapp-vite/src/main.ts:170`). Drei Lösungen übernahmen es; Notizen nahm eine Kurzmeldung für ein gesichertes Schlagwort (Widerspruch AKT-08 / DSK-15, siehe Vorschläge). | Snippet, Prüfliste, README `webapp-vite` |
| BEL-10 Datenweg-Zeile | 4/5 | Vorlage zeigt es nicht: keine Zeile unter „Sichern“ im Dialog (`webapp-vite/src/views/form.ts:70`), Abstand 0 (`app.css:28`), keine unter „Neue Notiz“ (`desktop-tauri/index.html`); auch die Fenster auf `docs/desktop.html` zeigen keine. | Snippet, Prüfliste, READMEs `webapp-vite` und `desktop-tauri` |
| NAV-06 Kopf, ⌘K | 4/4 | Widerspruch zwischen Texten: NAV-06 „⌘K öffnet auch dort die Befehlspalette“, README `webapp-vite` „gehört zur Web-App mit Fenster“, NAV-09 nur „mit Fenster“; drei Web-Apps bauten keine. Verein: die festen Wörter „Apps / Projekte“ passen nicht zu einer Vereinsseite (Regel selbst, siehe Vorschläge). | README `webapp-vite` berichtigt; Snippet: Tabelle je Produktart |
| WEB-09, WEB-11, STR-01, TEC-02 | 3–4/4 | Regel unklar für eine Web-App mit einer Hülle; die Vorlage baut keins davon; die Prüfungen urteilten verschieden (Verein: eingehalten, Web-Apps: verletzt). | README `webapp-vite` und `desktop-tauri` nennen die Lücke als Frage an den Inhaber |
| TXT-03 Titel | 3/5 | Vorlage zeigt es falsch: „Diesen Eintrag gibt es nicht“, „Diese Ansicht gibt es nicht“ (`webapp-vite/src/strings.ts:134`, `:200`), dem Muster nach kopiert. | Snippet, Prüfliste, README `webapp-vite` |
| ZUG-07 Barrierefreiheit | 3/4 | Vorlage zeigt einen Platzhalter, der auf der Seite „(ZUG-07)“ zeigt; die sechs Teile nennt nur `RULES.md`. | Snippet, Prüfliste, README `webapp-vite` |
| BEL-09 Beispieldaten | 3/5 | Regel schwer zu finden: „neben dem Titel“ steht nur in der Langfassung; Snippet und Prüfliste nennen den Marker nicht. | Snippet, Prüfliste |
| RAU-07 Abstand am Kind | 3/5 | Vorlage zeigt es falsch: `.app-view-title { margin-block-start }` (`webapp-vite/src/app.css:8`), nachgebaut als `.app-title-row` und im Papierkorb. | Snippet, README `webapp-vite` |
| DAT-02 Erledigtes | 2/3 | Widerspruch zwischen Regeln: EIN-03 macht eine abgehakte Beschriftung kräftig, DAT-02 lässt erledigte Zeilen zurücktreten; kein Muster für eine Abhakliste. | keine (Vorschlag) |
| ZEI-03 | 2/2 | Vorlage und Auftrag verlangen die Platzhalter-Kachel; kein Fehler der Agenten. | keine |

Einzelfälle (je eine Lösung): AKT-04, AKT-08, BEL-01, BEL-06, BEL-08, DAT-01, DAT-07, DAT-15, DAT-17, DSK-03, DSK-06,
DSK-12, FAR-07, HAL-04, NAV-07, NAV-09, RAU-01, RAU-05, STA-05, TEC-01, TXT-16, WEB-10, ZEI-13, ZUG-06, ZUG-08, ZUG-09.
Davon in die READMEs übernommen, weil die Vorlage sie nahelegt: DSK-06, DSK-12, ZUG-06, ZUG-09 (`sbFit.refresh` nach
dem Neuzeichnen), HAL-04 (`desktop-tauri`); BEL-01, ZUG-08 „übersprungen“, DAT-15, NAV-06/NAV-07, WEB-10
(`website-astro`).

## Nicht als Verstoß gezählt, aber in jeder Web-App

- **Hell oder Dunkel und Sprache in den Einstellungen:** alle drei Web-App-Aufträge verlangten es, NAV-06 verbietet die
  Taste dort. Alle drei Agenten folgten NAV-06, mussten es aber aus dem Regeltext herleiten; das Snippet nannte für eine
  Web-App ohne Fenster keinen Ort. Änderung: Tabelle je Produktart als erster Punkt des Snippets, Satz in `AGENTS.md` §3.
- **Port:** die Tests aller Vorlagen nutzen außerhalb der CI einen Server, der auf ihrem Port schon läuft. Drei Agenten
  prüften so zuerst eine fremde App und hielten das für grün. Änderung: Snippet, Prüfliste, `templates/README.md`, alle
  drei READMEs (`CI=1`).
- **„Einen Beleg öffnen“ (ZUG-08):** drei Apps ohne Belege konnten die vierte feste Aufgabe nicht bauen (Vorschlag).

## Vorschläge an den Inhaber (Regeltexte nicht geändert)

1. NAV-06: die festen Wörter „Apps“, „Projekte“, „Über“, „Kontakt“ und „DE / EN“ für Websites, die nicht vom Studio
   sind (Verein, Produktseite nur auf Deutsch).
2. NAV-06 gegen NAV-09: gilt ⌘K in einer Web-App ohne Fenster? Wenn ja, NAV-09 um sie erweitern und der Vorlage die
   Palette geben.
3. TXT-01 „nie wir“: eine Website, auf der eine Gruppe von sich spricht (Verein).
4. ZUG-08: die vierte Aufgabe für ein Produkt ohne Belege.
5. DAT-02 gegen EIN-03: ein Muster für Abhaklisten (Einkauf).
6. AKT-08 gegen DSK-15 und EBE-05: ein gesichertes Schlagwort im Inspektor entfernen, Dialog oder Kurzmeldung.
7. WEB-09, WEB-11, STR-01, TEC-02 für eine Web-App mit einer Hülle und eine Tauri-Oberfläche mit Vite (Module).
8. BEL-10 im Fenster: die Fenster auf `docs/desktop.html` zeigen die Zeile unter „Neue Notiz“ nicht.
9. DAT-17 „In Karten öffnen“ in einem privaten Tagebuch (sendet den Ort an einen fremden Dienst).
10. WEB-05 ohne Server (ein Formular, das eine E-Mail öffnet).
11. Für die Werkstatt: `.sb-toast__action[hidden]` in `sebaro.css`; eine Listenzeile mit Link und Taste am Ende
    (`sb-list-row__link::after` deckt die Taste ab); `min-inline-size: 0` für `.sb-chart__data` und `.sb-checkbox`
    in schmalen Zeilen bei 200&nbsp;%; Enter im Eingabedialog löst „Abbrechen“ aus, weil es zuerst steht.

## Nicht geprüft

Die Prüfungen sind Urteile von Agenten mit Belegen, nicht von Menschen, und nicht immer einheitlich (TEC-06, TEC-02,
WEB-09). Nur Chromium, kein Screenreader, kein echtes Handy, kein Tauri-Fenster und kein Rust-Build. Die Lösungen und
Rohdaten liegen nicht im Repository. Ob die geänderten Texte die Fehler wirklich verhindern, zeigt erst ein zweiter
Durchgang mit frischen Agenten.
