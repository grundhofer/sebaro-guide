# Änderungsprotokoll

Eine Version gilt für den Guide und den Regelkatalog zusammen (`rules/rules.json` → `version`). Jede Regel trägt
das Datum ihrer letzten Änderung (`changed`). Jede veröffentlichte Version liegt als Abzug in `rules/releases/`.
`tools/check_site.py` vergleicht den Katalog mit dem letzten Abzug: Jede neue, geänderte oder entfernte Regel muss
unter „Unveröffentlicht“ stehen, sonst schlägt die Prüfung fehl. `python3 tools/release.py <version>` macht daraus
eine Version.

Versionsregeln: **Hauptversion**, wenn eine Regel entfällt oder ihre Aussage umkehrt; **Nebenversion** für neue
Regeln, geänderte Werte und neue Seiten; **Korrektur** für Wortlaut, Beispiele und Fehler ohne neue Aussage.

## Unveröffentlicht

## 1.1.0 · 2026-10-20

Übernahme von D67–D71 aus der Werkstatt: nur noch sebaro Sans und sebaro Mono, eigene Tastenzeichen, Codefarben.

- Neu: TXT-10 (fünf Arten für Code), TXT-11 (Fehler und Unterschiede im Code), DSK-03 (Markdown und Code im Editor), TEC-08 (Werkzeuge für die Hervorhebung), alle vorläufig.
- Geändert: FAR-11 (Codefarben Indigo, Waldgrün, Himbeere, D69), SCH-01 und SCH-02 (Schriftpaar, D68, D71), SCH-05 (Mono 500, D70), TXT-08 (Code mit Hervorhebung), ZEI-09 (Wortmarke aus sebaro Sans), ICO-02 (gemessene Strichstärke), ICO-06 (Pfeile der Schrift nur für Kürzel), ICO-08 (Tastenzeichen aus der Schrift, jetzt entschieden).

## 1.0.0 · 2026-10-19

Erste Veröffentlichung: 160 Regeln mit Beispielen, Seiten Grundlagen, Bauteile, Daten, Web, App, Desktop, Gedanken, Ausblick.
