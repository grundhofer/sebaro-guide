# sebaro Guide

Der Gestaltungsleitfaden für alles, was sebaro baut: Apps am Handy, Websites und Desktop-Programme. Farben, Formen,
Verhalten, Funktion und die Gedanken dahinter, jede Regel mit Beispiel.

**Ansehen:** <https://grundhofer.github.io/sebaro-guide/>

| Seite | Inhalt |
|---|---|
| [Start](https://grundhofer.github.io/sebaro-guide/) | der Kern in sieben Sätzen, Wege durch den Guide |
| [Regeln](https://grundhofer.github.io/sebaro-guide/regeln.html) | alle Regeln mit ID, Begründung, Prüfung und Beispiel (richtig/falsch) |
| [Grundlagen](https://grundhofer.github.io/sebaro-guide/grundlagen.html) | Farben, Schrift, Raum, Form, Ebenen, Bewegung mit den echten Token-Werten |
| [Bauteile](https://grundhofer.github.io/sebaro-guide/bauteile.html) | jede Komponente mit allen Zuständen und Markup |
| [Daten](https://grundhofer.github.io/sebaro-guide/daten.html) | jede Datenart einmal dargestellt |
| [Web](https://grundhofer.github.io/sebaro-guide/web.html) · [App](https://grundhofer.github.io/sebaro-guide/app.html) · [Desktop](https://grundhofer.github.io/sebaro-guide/desktop.html) | Beispielseiten mit allen typischen Fällen je Plattform |
| [Gedanken](https://grundhofer.github.io/sebaro-guide/gedanken.html) | Haltung, Geschichte, Entscheidungen, Abwägungen |
| [Ausblick](https://grundhofer.github.io/sebaro-guide/ausblick.html) | Vorschläge zur Weiterentwicklung und offene Fragen |

## Für Agenten

Claude, Codex und andere Agenten beginnen bei [AGENTS.md](AGENTS.md) (`CLAUDE.md` verweist dorthin). Die Regeln stehen
maschinenlesbar in [rules/rules.json](rules/rules.json) und als Markdown in [guide/RULES.md](guide/RULES.md). Für ein
neues Projekt gibt es [Vorlagen](templates/README.md), darunter einen Abschnitt zum Einfügen in die `AGENTS.md` eines
Produkts.

## Woher die Werte kommen

Die Quellen von sebaro (Paletten, Verträge, Generatoren, Prüfungen und das Entscheidungsprotokoll D1–D71) liegen in
der Werkstatt **sebaroDesign**. Dieser Guide schreibt keine Farbe, Schrift und kein Icon ab: `docs/sebaro/` ist ein
geprüfter Export (`tools/sync_from_design.py`), jede Datei mit Prüfsumme. Regeln ändern sich nur in
`rules/rules.json`; `tools/build.py` erzeugt daraus die Regelseite, `guide/RULES.md` und `docs/llms.txt`.

```sh
python3 tools/sync_from_design.py   # sebaro neu aus sebaroDesign holen
python3 tools/build.py              # Seitenblöcke und Ausgaben erzeugen
python3 tools/check_site.py         # Seiten, Links, keine fremden Server, nur Tokens, Regeln
python3 -m http.server -d docs 8000 # lokal ansehen
```

Alle Beispieldaten sind erfunden. Geprüft ist im Browser (Chromium) in Hell und Dunkel bei 390 und 1440 px; echte
Geräte, Windows, WebKit und Screenreader stehen noch aus. Lizenzen: [LICENSE.md](LICENSE.md).
