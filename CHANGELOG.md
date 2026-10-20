# Änderungsprotokoll

Eine Version gilt für den Guide und den Regelkatalog zusammen (`rules/rules.json` → `version`). Jede Regel trägt
das Datum ihrer letzten Änderung (`changed`). Jede veröffentlichte Version liegt als Abzug in `rules/releases/`.
`tools/check_site.py` vergleicht den Katalog mit dem letzten Abzug: Jede neue, geänderte oder entfernte Regel muss
unter „Unveröffentlicht“ stehen, sonst schlägt die Prüfung fehl. `python3 tools/release.py <version>` macht daraus
eine Version.

Versionsregeln: **Hauptversion**, wenn eine Regel entfällt oder ihre Aussage umkehrt; **Nebenversion** für neue
Regeln, geänderte Werte und neue Seiten; **Korrektur** für Wortlaut, Beispiele und Fehler ohne neue Aussage.

## Unveröffentlicht

## 2.0.0 · 2026-10-20

Übernahme von D72–D90 aus der Werkstatt (Antworten des Inhabers vom 2026-10-20) und der in Runde 6 gebauten Bausteine
(Fenster, Baum, Befehlspalette, Fensterdichte, Layout-Bausteine, Überschriften-Rollen, Container-Abfragen). Eine Regel
entfällt, und „Hell oder Dunkel“ ist für Apps umgekehrt (D75); deshalb eine Hauptversion.

- Neu, entschieden: FAR-12 (Kategorie und Markierung als eigene Farbaufgaben, Töne noch offen, D73), SCH-07 (Überschriften-Rollen als Klassen, D80), RAU-07 (Stapel, Reihe, Formularraster, D80), FOR-06 (Pillenradius nur für vier Dinge, D85), AKT-11 (Hauptaktion zuletzt in jeder Aktionsgruppe, D83), DAT-09 (Bewertung mit einem Stern und der Zahl, D82), DAT-10 (mehrere Reihen und Skalen im Diagramm, D83), TXT-12 (Geldbeträge, D82), TXT-13 (Ränge und „etwa“, D82), TXT-14 („keine“ und „keine Angabe“, D82), TXT-15 (Fließtext ohne automatische Silbentrennung, D82), TXT-16 (Menüpfade „Einstellungen, dann Über“ und Brotkrumen, D82), ZEI-12 (Zeichenprüfung gegen Formen, D86), BIL-05 (Markenfigur erlaubt, D90), ZUG-08 (vier feste Aufgaben nur mit Tastatur, D79), DSK-04 (Fensterteile ausblendbar, Inhalt mindestens 480 px, D81), DSK-05 (Hell oder Dunkel im Menü „Darstellung“, D75), TEC-09 (Lizenz MIT, Schriften OFL, Marke vorbehalten, D76), TEC-10 (für mehrere Sprachen planen, D87), TEC-11 (Versionen und Abgleich, D88).
- Neu, vorläufig: FAR-13 (Farbfelder auf Nachschlageseiten, feste Ausnahme ohne eigene Inhaber-Zeile), NAV-11 (Baum nach ARIA-Muster, D80).
- Geändert: STA-07 (Statussumme einmal, in der Aktionszone; war offen, D72), EBE-08 (Aktionszone mit der einen Summe, sb-window, D72, D74), AKT-01 (Hauptaktion unten am Bereich, auf den sie wirkt, D74), AKT-09 (Hell oder Dunkel je Produktart, D75), WEB-02 (Taste nur noch auf Websites, Ansage je Sprache, D75, D87), MOB-04 (Wahl in den Einstellungen der Handy-App, D75), DSK-02 (Einstellungen mit Hell oder Dunkel, D75), EBE-05 (erlaubte Fälle, 6 s, bleibt bei Fokus, nie für Fehler, sb-toast__action, D78), SCH-02 (Tauri lädt überall die WOFF2, D77), TEC-07 (Übernahme zuerst in novalis, D77, D89), ZEI-07 (Kürzel ja, Wörter und Namen nie in der Kachel, D85), ZEI-03 (drei Buchstaben bestätigt, D85), ZEI-08 (Kapazität neu gemessen, Markenrecherche vor Veröffentlichung, D85, D86, D88), ZEI-10 (Favicon-Kontraste 3,05–3,37 : 1, D85), DAT-02 (erledigte Zeilen mit unsichtbarem „erledigt:“, D83), AKT-05 (Fehlergrund in Textfarbe mit Fehlerglyphe, D83), FOR-05 und EBE-02 (Kartenrand 1 px für viele gleiche Karten im Fenster, 2 px für gruppierende Karten, Radius 12, D83), FOR-01 (Radius 12 für beide Kartenformen, Pille nach FOR-06, D83, D85), NAV-06 und NAV-07 (Website-Kopf bei 390 px neu gemessen, D83), AKT-04 („Weiter: Ziel“ in Einführungen, D83), AKT-02 (Hauptaktion auf Websites 56 px, D83), AKT-08 (Papierkorb-Satz nur mit Papierkorb, D83), RAU-05 und RAU-06 (Fensterzeilen 32/48/64 px, D83), DAT-04 (mehrere Reihen nach DAT-10, D83), NAV-09 (⌘K / Strg+K in allen Apps, sb-command-palette, D84), FAR-01 (zwei neue Farbaufgaben, D73), FAR-02 (Diff-Zeilen als einzige Ausnahme, D85), FAR-05 (Blautönung bleibt, kein Abstandsziel, D85), STR-01 (Start im Web einmal je Browser-Tab, D85), MOB-03 (Haptik nur bei Touch, D85), TEC-02 (Zustandsattribute vereinheitlicht: data-sb-state, D85), TXT-01 („unser“ nur in der Doku des Systems, D85), TXT-02 (Serverort ohne Stadt mit Anbieter und Rechtsraum, D90), BIL-04 (Bilder bleiben vorerst im Git, D90), BEL-01 (Serverort nach D90), TXT-04 (Zahlen und Daten je Sprache, D87), TXT-05 (Wochentage mit zwei Buchstaben an Achsen und in Kalendern, D82), NAV-08 (Brotkrumen mit Chevron-Icon, Pfeiltasten in Reitern, D80, D82), ZUG-05 (kein eigenes Hochkontrast-Schema, D88, ändert D7), RAU-03 (Breakpoints nur noch 640 und 1024, sonst Container-Abfragen, D80), DSK-01 (Fenstergerüst sb-window, D80), STA-08, DAT-08, NAV-10, TXT-09, AKT-10, EBE-06, EBE-07, BEW-01, BEW-04, TEC-04, TEC-05, STA-03, NAV-04 (gebaute Bausteine und Skripte statt Nachbau, D80, D81), HAL-03 (eigener Grundsatz, D85), SCH-06 (Hinweis auf TXT-15).
- Entfällt: FAR-10 (Abstand der Dunkelgründe zu Fremdprodukten; das Ziel aus D26 hat der Inhaber gestrichen, D85).
- Status vorläufig → entschieden: HAL-04 („Fehlschläge sichtbar lassen“ als Grundsatz, D85), HAL-09, ZUG-01, ZUG-02 (Fokusring 2 px), BIL-01, ICO-01, TXT-01, TXT-04, BEL-01 (die bestätigten Grundsätze D5, D6, D9, D10, D11, D18, D20, D21, D22; D85), TXT-10, TXT-11, DSK-03, TEC-08 (die vier Code-Regeln, D85), DAT-02 (D83), RAU-03 (D80), MOB-04 (D75), TEC-02 (D85). Status offen → entschieden: STA-07 (D72).
- Beispiele: Fenster, Baum, Befehlspalette, Mehrfachauswahl, Fensterzeilen, Karten und Menüs zeigen jetzt die Klassen des Systems statt eines Nachbaus; die Markierung „Vorschlag, noch nicht im System“ entfällt dort.
- Seiten: Grundlagen, Bauteile und Daten zeigen die neuen Klassen (Fenster, Baum, Befehlspalette, Fensterdichte, Layout-Bausteine, Überschriften-Rollen, Container-Abfragen) und die Skripte für Bedienung; Desktop ist neu gebaut, App und Web sind nachgezogen. Was auf die Wahl des Inhabers wartet (Farbtöne für Kategorie und Markierung, warme Palette, fehlende Bauteile, Website-Muster, Diagramme jenseits der Balken, iOS, übrige Fensterfragen), ist als „Skizziert, wartet auf die Wahl des Inhabers“ gekennzeichnet. Start, Gedanken und Ausblick stehen auf D1–D90; der Ausblick ist neu gegliedert.
- Guide: Kopf in der Reihenfolge Kachel, Navigation, Taste (NAV-07); gemeinsames Muster für Tabellen, die sich unter 560 px stapeln; Farbfelder (FAR-13); absichtliche Fehlbeispiele (`g-ex--dont`); Lizenzdatei nach D76.
- Werkzeuge: `check_site.py` prüft jetzt auch Tokens (TOKEN), Farbfelder (SWATCH) und die Lizenzdatei (LICENSE); Marker-Blöcke dürfen ineinander stehen; `sync_from_design.py` kann einen fertigen Export übernehmen und prüft auf ausgeschlossene Produkte; der Abgleich mit der Werkstatt kommt als Pull Request (D88).

## 1.1.0 · 2026-10-20

Übernahme von D67–D71 aus der Werkstatt: nur noch sebaro Sans und sebaro Mono, eigene Tastenzeichen, Codefarben.

- Neu: TXT-10 (fünf Arten für Code), TXT-11 (Fehler und Unterschiede im Code), DSK-03 (Markdown und Code im Editor), TEC-08 (Werkzeuge für die Hervorhebung), alle vorläufig.
- Geändert: FAR-11 (Codefarben Indigo, Waldgrün, Himbeere, D69), SCH-01 und SCH-02 (Schriftpaar, D68, D71), SCH-05 (Mono 500, D70), TXT-08 (Code mit Hervorhebung), ZEI-09 (Wortmarke aus sebaro Sans), ICO-02 (gemessene Strichstärke), ICO-06 (Pfeile der Schrift nur für Kürzel), ICO-08 (Tastenzeichen aus der Schrift, jetzt entschieden).

## 1.0.0 · 2026-10-19

Erste Veröffentlichung: 160 Regeln mit Beispielen, Seiten Grundlagen, Bauteile, Daten, Web, App, Desktop, Gedanken, Ausblick.
