#!/usr/bin/env python3
"""Fill the generated blocks of the guide pages and write the machine-readable outputs.

Pages in docs/*.html are hand-written. Shared parts sit between marker comments and are rewritten by this script:

    <!-- guide:og page="x" -->     … <!-- /guide:og -->        canonical, og:* and twitter:card of page x (D96, WEB-09),
                                                               from src/og/head/x.head.html (written by tools/og.mjs)
    <!-- guide:head -->            … <!-- /guide:head -->      fonts, tokens, sprite.css, sebaro.css, guide.css, scripts
    <!-- guide:sprite -->          … <!-- /guide:sprite -->    docs/sebaro/icons/sprite.svg, inlined (works from file://)
    <!-- guide:header page="x" --> … <!-- /guide:header -->    site header; page x gets aria-current
    <!-- guide:footer -->          … <!-- /guide:footer -->    site footer with sync state
    <!-- guide:tile id="novalis" size="48" --> … <!-- /guide:tile -->   brand/inline/tile-<id>[-small].svg
    <!-- guide:rules -->           … <!-- /guide:rules -->     regeln.html: every rule of rules/rules.json + its example
    <!-- guide:rules-toc -->       … <!-- /guide:rules-toc --> regeln.html: area list
    <!-- guide:stats -->           … <!-- /guide:stats -->     rule counts by status

Markers may nest at any depth: open and close markers are paired with a stack, and markers inside generated output
(a guide:tile in a rule fragment inside guide:rules) are filled as well. An unclosed or crossed marker stops the build.

Rule examples are fragments in src/rule-examples/<RULE-ID>.html. Outputs written besides the pages:
docs/rules.json (copy of rules/rules.json), guide/RULES.md (all rules as Markdown for agents), docs/llms.txt, and
src/og/pages.json: the share-image page list (D96 (a), brand/og/pages.schema.json of the export), written from the
pages themselves: per page its file, its <h1> as title and its meta description, nothing else (the pages state no
breadcrumb, reading time or date, so every image takes the start form). tools/og.mjs renders it with the exported
docs/sebaro/brand/og/render.mjs to docs/og/<id>.png and src/og/head/<id>.head.html; this script copies each snippet
into the page's guide:og block, without its meta description (the page writes its own). A page without a snippet
gets a placeholder and the build exits 1 (render first: node tools/og.mjs, then this script again).

    python3 tools/build.py          # rewrite blocks and outputs
    python3 tools/build.py --check  # exit 1 if anything would change (freshness gate)
    python3 tools/build.py docs/app.html   # only this page (safe while others edit other pages)
Standard library only.
"""
from __future__ import annotations

import argparse
import html
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
SEBARO = DOCS / "sebaro"
RULES = ROOT / "rules" / "rules.json"
EXAMPLES = ROOT / "src" / "rule-examples"
REPO_URL = "https://github.com/grundhofer/sebaro-guide"
SITE_URL = "https://grundhofer.github.io/sebaro-guide/"
OG_SRC = ROOT / "src" / "og"
OG_PAGES = OG_SRC / "pages.json"         # page list for render.mjs, written by outputs()
OG_HEAD = OG_SRC / "head"                # <id>.head.html + head.json, written by tools/og.mjs (never published)
OG_MISSING: list[str] = []               # pages whose snippet is missing (build exits 1)

# file, label, icon (sprite id), one line for llms.txt
PAGES = [
    ("index.html", "Start", "home", "Einstieg: was sebaro ist, der Kern in neun Sätzen, Wege durch den Guide"),
    ("regeln.html", "Regeln", "check", "Alle Gestaltungsregeln mit ID, Begründung, Prüfung und Live-Beispiel (richtig/falsch)"),
    ("grundlagen.html", "Grundlagen", "board", "Farben, Schrift, Raum, Form, Linien, Ebenen, Bewegung: alle Tokens mit Werten"),
    ("bauteile.html", "Bauteile", "copy", "Alle Komponenten mit Zuständen und Markup"),
    ("daten.html", "Daten", "chart-bar", "Jede Datenart einmal dargestellt: Text, Zahlen, Zeit, Status, Listen, Tabellen, Diagramme, Code …"),
    ("plattformen.html", "Plattformen", "smartphone", "Übersicht der vier Plattformseiten Web, App, iOS und Desktop und was je Plattform anders ist"),
    ("web.html", "Web", "globe", "Beispiel-Website mit allen typischen Seiten und Fällen"),
    ("app.html", "App", "file", "Beispiel-App am Handy: alle typischen Bildschirme und Zustände"),
    ("ios.html", "iOS", "smartphone", "Dieselbe App auf dem iPhone: SwiftUI-Bausteine, Systemleisten, Sheet, Dynamic Type"),
    ("desktop.html", "Desktop", "folder", "Beispiel-Desktop-App (Tauri/macOS): Fenster, Seitenleiste, Tabellen, Menüs, Tastatur"),
    ("gedanken.html", "Gedanken", "book", "Die Gedanken dahinter: Haltung, Geschichte, Entscheidungen, Abwägungen"),
    ("ausblick.html", "Ausblick", "arrow-right", "Was auf eine Wahl des Inhabers wartet, was offen ist, später kommt oder erledigt ist"),
]

# D92 (6): the header groups the four platform pages under „Plattformen“ (a link to the overview page, no menu
# button: spec/03 §6.1 keeps every header word visible at 390 px). On a platform page „Plattformen“ carries
# aria-current="true" (current item of the set, not the page itself). Footer and llms.txt keep listing every page.
PLATFORM_GROUP = "plattformen.html"
PLATFORM_PAGES = ("web.html", "app.html", "ios.html", "desktop.html")

STATUS_LABEL = {"entschieden": ("check--16", "Entschieden"), "vorläufig": ("clock--16", "Vorläufig"),
                "offen": ("help", "Offen")}
PLATFORM_LABEL = {"web": "Web", "mobile": "App", "desktop": "Desktop", "alle": "Alle Plattformen"}


def esc(s: str) -> str:
    return html.escape(s or "", quote=True)


# Characters the shipped font subsets do not contain: rendering them would pull in a system font (D22, FNT3).
# rules.json keeps the exact characters for agents; the HTML gets words or icons instead. Key glyphs (⌘ ⇧ ⌥ ⌃ ↩ ⎋ ⌫
# ⇥) are real characters of sebaro Sans/Mono since D68 and stay. Arrows in prose stay icons (ICO-06).
GLYPH_WORDS = {"≥": "ab", "≤": "bis", "Δ": "Delta-", "↗": "U+2197"}
GLYPH_ICONS = {"→": ("arrow-right--16", "zu"), "←": ("arrow-left--16", "links"), "↑": ("arrow-up--16", "hoch"),
               "↓": ("arrow-down--16", "runter")}


GLYPH_WORDS_EN = {**GLYPH_WORDS, "≥": "at least", "≤": "at most"}


def _plain(s: str, lang: str) -> str:
    out = esc(s)
    for ch, word in (GLYPH_WORDS_EN if lang == "en" else GLYPH_WORDS).items():
        out = out.replace(ch, word)
    for ch, (name, label) in GLYPH_ICONS.items():
        out = out.replace(ch, f'<svg class="sb-icon sb-icon--16" role="img" aria-label="{label}" focusable="false">'
                              f'<use href="#{name}"/></svg>')
    return out.replace("Delta- ", "Delta-")


# Machine values inside rule text (D101 (6), (10), TXT-08): rules.json keeps plain text for agents; the HTML marks a
# file name or path as <code class="sb-file-name"> with <wbr> after - . _ / (it breaks only there, never with a
# hyphen), and a markup fragment or an attribute as <code>, so sb-fit.js never hyphenates them (D102 lane narrow, OVF6).
_FILE_RE = (r"(?<![\w/.-])(?:[\w-]+/)*[\w-]+(?:\.[\w-]+)*\."
            r"(?:py|mjs|js|json|css|html|md|kt|swift|txt|sh|toml|rs|svg|png|webp|woff2|webm)(?![\w/])")
_MARKUP_RE = r"<[a-z][^<>]*>(?:[^<>]*</[a-z]+>)?|[a-z][\w:-]*=(?:\"[^\"]*\"|'[^']*')"
_MACHINE = re.compile(f"(?P<file>{_FILE_RE})|(?P<markup>{_MARKUP_RE})")


def _extension_dot(s: str) -> int:
    """Index of the dot before an extension of one to four letters or digits („.csv“, „.md“), else -1: no break goes
    there, so the extension stays with the last part (the workshop's sbExtensionDot, spec/02 §3.11)."""
    dot = s.rfind(".")
    if dot <= 0:
        return -1
    ext = s[dot + 1:]
    return dot if 1 <= len(ext) <= 4 and all(c.isalnum() for c in ext) else -1


def _file_name(s: str) -> str:
    out = []
    dot = _extension_dot(s)
    for i, ch in enumerate(s):
        out.append(esc(ch))
        if ch in "-._/" and i < len(s) - 1 and i != dot:
            out.append("<wbr>")
    return '<code class="sb-file-name">' + "".join(out) + "</code>"


def text(s: str, lang: str = "de") -> str:
    """Escape rule text for HTML, mark file names and markup as code, and replace characters the fonts lack."""
    s = s or ""
    out, pos = [], 0
    for m in _MACHINE.finditer(s):
        out.append(_plain(s[pos:m.start()], lang))
        out.append(_file_name(m.group("file")) if m.group("file") else f"<code>{esc(m.group('markup'))}</code>")
        pos = m.end()
    out.append(_plain(s[pos:], lang))
    return "".join(out)


def icon(name: str, size: int = 16) -> str:
    return (f'<svg class="sb-icon sb-icon--{size}" aria-hidden="true" focusable="false">'
            f'<use href="#{name}"/></svg>')


def sync_state() -> dict:
    p = DOCS / "GUIDE-SYNC.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.is_file() else {}


def rules_data() -> dict:
    return json.loads(RULES.read_text(encoding="utf-8")) if RULES.is_file() else {"areas": [], "rules": []}


# ------------------------------------------------------------------ blocks

def page_id(file: str) -> str:
    return file[:-len(".html")]


class _Lead(HTMLParser):
    """The first <h1> text and the meta description of a page (entities decoded, white space collapsed)."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.h1: list[str] | None = None
        self.done = False
        self.description = ""

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "meta" and a.get("name") == "description" and not self.description:
            self.description = a.get("content") or ""
        if tag == "h1" and self.h1 is None:
            self.h1 = []

    def handle_endtag(self, tag):
        if tag == "h1" and self.h1 is not None:
            self.done = True

    def handle_data(self, data):
        if self.h1 is not None and not self.done:
            self.h1.append(data)


def page_lead(path: Path) -> tuple[str, str]:
    p = _Lead()
    p.feed(path.read_text(encoding="utf-8"))
    title = " ".join("".join(p.h1 or []).split())
    return title, " ".join(p.description.split())


def og_pages() -> str:
    """src/og/pages.json: one entry per page, its words taken from the page (D96 (a)). Only the start page is
    og:type website; the others keep the default article. No path, reading time or date: no page states them."""
    site = urlsplit(SITE_URL)
    pages = []
    for file, _label, _icon, _desc in PAGES:
        title, description = page_lead(DOCS / file)
        entry = {"id": page_id(file), "url": site.path + ("" if file == "index.html" else file), "title": title}
        if description:
            entry["description"] = description
        if file == "index.html":
            entry["type"] = "website"
        pages.append(entry)
    doc = {
        "$schema": "../../docs/sebaro/brand/og/pages.schema.json",
        "$comment": "written by tools/build.py from the pages (h1, meta description); do not edit. "
                    "tools/og.mjs renders it with docs/sebaro/brand/og/render.mjs (D96 (a), WEB-09).",
        "site": {"product": "studio", "name": "sebaro Guide", "origin": f"{site.scheme}://{site.netloc}",
                 "lang": "de", "imageBase": site.path + "og/"},
        "pages": pages,
    }
    return json.dumps(doc, ensure_ascii=False, indent=2) + "\n"


def block_og(attrs: dict) -> str:
    pid = attrs.get("page", "")
    snippet = OG_HEAD / f"{pid}.head.html"
    if not snippet.is_file():
        OG_MISSING.append(pid)
        return f"<!-- no share image for {esc(pid)} yet: run node tools/og.mjs, then python3 tools/build.py -->"
    # the page writes its own meta description (the page list took it from there); keep every other tag
    lines = [ln for ln in snippet.read_text(encoding="utf-8").strip().splitlines()
             if not ln.startswith('<meta name="description" ')]
    return "\n".join(lines)


def block_head(_attrs: dict) -> str:
    return "\n".join([
        '<meta name="color-scheme" content="light dark">',
        '<script src="sebaro/js/theme-init.js"></script>',
        '<link rel="stylesheet" href="sebaro/fonts/fonts.css">',
        '<link rel="stylesheet" href="sebaro/tokens.css">',
        '<link rel="stylesheet" href="sebaro/icons/sprite.css">',
        '<link rel="stylesheet" href="sebaro/css/sebaro.css">',
        '<link rel="stylesheet" href="assets/vendor/demo.css">',
        '<link rel="stylesheet" href="assets/vendor/pages.css">',
        '<link rel="stylesheet" href="assets/guide.css">',
        '<link rel="icon" href="sebaro/brand/site-root/favicon.ico" sizes="32x32">',
        '<link rel="icon" href="sebaro/brand/site-root/icon.svg" type="image/svg+xml">',
        '<script defer src="sebaro/js/theme-button.js"></script>',
        # D91 Z3a/C4c: the footer choice „Farbton: Kühl · Warm“; W8a: paper is always light (theme-init.js applies a
        # stored tone before first paint)
        '<script defer src="sebaro/js/sb-tone.js"></script>',
        '<script defer src="sebaro/js/sb-print.js"></script>',
        '<script defer src="assets/guide.js"></script>',
        # D100 (3), (5), D101 (1), (9), (11): large text (segments to a select, short steps, facts list, series legend,
        # a hyphen only for an overlong word); deferred after guide.js, so it measures the finished chrome
        '<script defer src="sebaro/js/sb-fit.js"></script>',
    ])


def block_sprite(_attrs: dict) -> str:
    return (SEBARO / "icons" / "sprite.svg").read_text(encoding="utf-8").strip()


def tile_svg(product: str, size: str) -> str:
    suffix = "-small" if size == "32" else ""
    svg = (SEBARO / "brand" / "inline" / f"tile-{product}{suffix}.svg").read_text(encoding="utf-8").strip()
    return svg


def block_tile(attrs: dict) -> str:
    return tile_svg(attrs["id"], attrs.get("size", "48"))


def block_header(attrs: dict) -> str:
    current = attrs.get("page", "")
    links = []
    for file, label, _icon, _desc in PAGES:
        if file in PLATFORM_PAGES:
            continue
        cur = ' aria-current="page"' if file == current else ""
        if file == PLATFORM_GROUP and current in PLATFORM_PAGES:
            cur = ' aria-current="true"'
        links.append(f'<a href="{file}"{cur}>{esc(label)}</a>')
    return "\n".join([
        '<a class="sb-skip-link" href="#inhalt">Zum Inhalt</a>',
        '<header class="sb-site-header g-header">',
        '  <a class="sb-lockup" href="index.html">',
        f'    <span class="sb-sign-tile sb-sign-tile--32" aria-hidden="true">{tile_svg("studio", "32")}</span>',
        # D100 (5): at 200 % text on 320 px „Guide“ goes under „sebaro“ instead of pushing the page sideways
        '    <span class="g-header__name"><span class="sb-wordmark">sebaro</span><span class="g-header__suffix">Guide</span></span>',
        '  </a>',
        # NAV-07: DOM order lockup, navigation, language, theme button; the guide is German only, so no language switch
        '  <div class="sb-site-header__links">',
        '    <nav class="sb-site-nav g-nav" aria-label="Hauptmenü">',
        "      " + " ".join(links),
        '    </nav>',
        '  </div>',
        '  <button class="sb-theme-button" type="button" data-sb-theme-button>Hell oder Dunkel</button>',
        '  <span class="sb-visually-hidden" role="status" data-sb-theme-status></span>',
        '</header>',
    ])


def block_footer(_attrs: dict) -> str:
    st = sync_state()
    commit = (st.get("sebaroDesignCommit") or "")[:7]
    contracts = st.get("contracts") or {}
    pages = [f'    <li><a href="{file}">{esc(label)}</a></li>' for file, label, _icon, _desc in PAGES]
    return "\n".join([
        '<footer class="sb-site-footer g-footer">',
        # D92 (6): the header groups the platform pages, so the footer lists every page directly
        '  <nav class="g-footer__pages" aria-label="Alle Seiten">',
        '  <ul class="sb-site-footer__links">',
        *pages,
        '  </ul>',
        '  </nav>',
        f'  <p>sebaro Guide <a href="{REPO_URL}/blob/main/CHANGELOG.md">Version {esc(rules_data().get("version", "?"))}{icon("external-link--16")}</a> · '
        f'System sebaro, Token-Vertrag {esc(str(contracts.get("tokens", "?")))} · '
        f'aus sebaroDesign <code class="sb-code-inline">{esc(commit)}</code> · '
        # D96 (a), WEB-09: the share images end with the host; the page says it too (no text the page lacks)
        # the host is a name (D101 (10)): it breaks at the line end without a hyphen, here after the slash first
        f'online unter <span translate="no">{esc(SITE_URL.split("://", 1)[1].rstrip("/")).replace("/", "/<wbr>")}</span></p>',
        '  <ul class="sb-site-footer__links">',
        '    <li><a href="rules.json">rules.json</a></li>',
        '    <li><a href="llms.txt">llms.txt</a></li>',
        f'    <li><a href="{REPO_URL}">GitHub{icon("external-link--16")}</a></li>',
        f'    <li><a href="{REPO_URL}/blob/main/AGENTS.md">Für Agenten{icon("external-link--16")}</a></li>',
        '  </ul>',
        # D91 Z3a: websites put „Farbton“ in the footer under „Darstellung“ (sb-tone.js shows the hidden group). The
        # <form> keeps these radios a group of their own: rule examples on regeln.html carry name="sb-tone" too.
        '  <section class="sb-site-footer__display" aria-labelledby="g-footer-display-h" data-sb-tone-choice hidden>',
        '    <h2 id="g-footer-display-h">Darstellung</h2>',
        '    <form class="g-footer__tone">',
        '      <fieldset class="sb-segmented"><legend>Farbton</legend>',
        '        <div class="sb-segmented__options">',
        f'          <label class="sb-segmented__option"><input type="radio" name="sb-tone" value="cool" checked>'
        f'<span class="sb-segmented__face">{icon("check--16")}Kühl</span></label>',
        f'          <label class="sb-segmented__option"><input type="radio" name="sb-tone" value="warm">'
        f'<span class="sb-segmented__face">{icon("check--16")}Warm</span></label>',
        '        </div>',
        '      </fieldset>',
        '    </form>',
        '  </section>',
        '  <p class="sb-visually-hidden" role="status" data-sb-tone-status></p>',
        '</footer>',
    ])


def render_rule(r: dict, area_title: str) -> str:
    st_icon, st_label = STATUS_LABEL.get(r.get("status", ""), ("info", r.get("status", "")))
    platforms = " ".join(f'<span class="sb-tag">{esc(PLATFORM_LABEL.get(p, p))}</span>' for p in r.get("platforms", []))
    decisions = ", ".join(r.get("decisions", [])) or "–"
    ex_path = EXAMPLES / f"{r['id']}.html"
    # fragments may carry their own guide:tile blocks; fill them before nesting into the rules block
    example = fill(ex_path.read_text(encoding="utf-8")).strip() if ex_path.is_file() else ""
    parts = [
        f'<article class="g-rule" id="{esc(r["id"])}" data-status="{esc(r.get("status", ""))}" '
        f'data-platforms="{esc(" ".join(r.get("platforms", [])))}" aria-labelledby="{esc(r["id"])}-h">',
        '  <header class="g-rule__head">',
        f'    <a class="g-rule__id" href="#{esc(r["id"])}">{esc(r["id"])}</a>',
        f'    <h3 class="g-rule__title" id="{esc(r["id"])}-h">{text(r["title"])}</h3>',
        f'    <p class="g-rule__meta"><span class="g-rule__status g-rule__status--{esc(r.get("status", ""))}">'
        f'{icon(st_icon)}{esc(st_label)}</span> {platforms}</p>',
        '  </header>',
        f'  <p class="g-rule__text">{text(r["rule"])}</p>',
    ]
    if example:
        parts.append(f'  <div class="g-rule__example">\n{example}\n  </div>')
    parts += [
        '  <details class="g-rule__more">',
        '    <summary>Warum, Werte und Prüfung</summary>',
        '    <dl class="sb-meta-list g-rule__facts">',
        f'      <div><dt>Warum</dt><dd>{text(r.get("why", ""))}</dd></div>',
        f'      <div><dt>So</dt><dd>{text(r.get("do", ""))}</dd></div>',
        f'      <div><dt>Nicht so</dt><dd>{text(r.get("dont", ""))}</dd></div>',
    ]
    if r.get("numbers"):
        parts.append(f'      <div><dt>Werte</dt><dd>{text(r["numbers"])}</dd></div>')
    if r.get("note"):
        parts.append(f'      <div><dt>Hinweis</dt><dd>{text(r["note"])}</dd></div>')
    parts += [
        f'      <div><dt>Prüfung</dt><dd>{text(r.get("check", ""))}</dd></div>',
        f'      <div><dt>Entscheidung</dt><dd>{esc(decisions)}</dd></div>',
        f'      <div><dt>Geändert</dt><dd>{esc(r.get("changed", ""))}</dd></div>',
        f'      <div><dt>Quelle</dt><dd><code class="sb-code-inline">{esc(r.get("source", ""))}</code></dd></div>',
        f'      <div><dt lang="en">Agent</dt><dd lang="en">{text(r.get("rule_en", ""), "en")}</dd></div>',
        '    </dl>',
        '  </details>',
        '</article>',
    ]
    return "\n".join(parts)


def block_rules(_attrs: dict) -> str:
    data = rules_data()
    out = []
    for area in data.get("areas", []):
        rules = [r for r in data["rules"] if r.get("area") == area["id"]]
        if not rules:
            continue
        out.append(f'<section class="sb-section g-area" id="bereich-{esc(area["id"])}" '
                   f'aria-labelledby="bereich-{esc(area["id"])}-h">')
        out.append(f'<h2 class="sb-section__title" id="bereich-{esc(area["id"])}-h">{esc(area["title"])} '
                   f'<span class="g-area__count">{len(rules)}</span></h2>')
        if area.get("intro"):
            out.append(f'<p class="g-area__intro">{esc(area["intro"])}</p>')
        out.extend(render_rule(r, area["title"]) for r in rules)
        out.append('</section>')
    return "\n".join(out)


def block_rules_toc(_attrs: dict) -> str:
    data = rules_data()
    items = []
    for area in data.get("areas", []):
        n = sum(1 for r in data["rules"] if r.get("area") == area["id"])
        if n:
            items.append(f'<li><a href="#bereich-{esc(area["id"])}">{esc(area["title"])}</a> '
                         f'<span class="g-toc__count">{n}</span></li>')
    return '<ol>\n' + "\n".join(items) + "\n</ol>"


def block_stats(_attrs: dict) -> str:
    rules = rules_data().get("rules", [])
    n = {k: sum(1 for r in rules if r.get("status") == k) for k in ("entschieden", "vorläufig", "offen")}
    return "\n".join([
        '<ul class="sb-stats g-stats">',
        f'  <li class="sb-stat"><p class="sb-stat__label">Regeln</p><p class="sb-stat__value">{len(rules)}</p></li>',
        f'  <li class="sb-stat"><p class="sb-stat__label">entschieden</p><p class="sb-stat__value">{n["entschieden"]}</p></li>',
        f'  <li class="sb-stat"><p class="sb-stat__label">vorläufig</p><p class="sb-stat__value">{n["vorläufig"]}</p></li>',
        f'  <li class="sb-stat"><p class="sb-stat__label">offen</p><p class="sb-stat__value">{n["offen"]}</p></li>',
        '</ul>',
    ])


BLOCKS = {"og": block_og, "head": block_head, "sprite": block_sprite, "header": block_header, "footer": block_footer,
          "tile": block_tile, "rules": block_rules, "rules-toc": block_rules_toc, "stats": block_stats}
# one pattern for open and close markers; pairs are matched with a stack, so markers may nest at any depth
MARKER = re.compile(r'<!-- (?P<close>/)?guide:(?P<name>[a-z-]+)(?P<attrs>(?:\s+[a-z]+="[^"]*")*)\s*-->')
ATTR = re.compile(r'([a-z]+)="([^"]*)"')
MAX_DEPTH = 8


def fill(text: str, depth: int = 0) -> str:
    """Rewrite every outermost marker block; markers inside the generated output (for example guide:tile in a rule
    fragment inside guide:rules) are filled too, at any depth. A body is always regenerated, never kept."""
    if depth > MAX_DEPTH:
        raise SystemExit(f"guide markers nested deeper than {MAX_DEPTH} levels")
    out, pos, stack = [], 0, []
    for m in MARKER.finditer(text):
        name = m.group("name")
        if not m.group("close"):
            stack.append(m)
            continue
        if not stack or stack[-1].group("name") != name:
            line = text.count("\n", 0, m.start()) + 1
            raise SystemExit(f"line {line}: <!-- /guide:{name} --> without a matching open marker")
        start = stack.pop()
        if stack:
            continue  # inner pair: its outermost block is regenerated as a whole
        if name not in BLOCKS:
            raise SystemExit(f"unknown block guide:{name}")
        attrs_raw = start.group("attrs") or ""
        body = fill(BLOCKS[name](dict(ATTR.findall(attrs_raw))), depth + 1)
        out.append(text[pos:start.start()])
        out.append(f'<!-- guide:{name}{attrs_raw} -->\n{body}\n<!-- /guide:{name} -->')
        pos = m.end()
    if stack:
        line = text.count("\n", 0, stack[-1].start()) + 1
        raise SystemExit(f"line {line}: <!-- guide:{stack[-1].group('name')} --> is never closed")
    out.append(text[pos:])
    return "".join(out)


# ------------------------------------------------------------------ outputs

def rules_markdown() -> str:
    data = rules_data()
    lines = ["# sebaro rules", "",
             "Generated by `tools/build.py` from `rules/rules.json`; do not edit. "
             f"{len(data.get('rules', []))} rules. Live examples: {SITE_URL}regeln.html", "",
             "Status: **entschieden** = owner decision (binding), **vorläufig** = agent decision, changeable by the "
             "owner, **offen** = proposal, not yet a rule. `D<n>` = row n of sebaroDesign/DECISIONS.md.", ""]
    for area in data.get("areas", []):
        rules = [r for r in data["rules"] if r.get("area") == area["id"]]
        if not rules:
            continue
        lines += [f"## {area['title']} ({area['prefix']})", ""]
        if area.get("intro"):
            lines += [area["intro"], ""]
        for r in rules:
            lines += [f"### {r['id']} {r['title']}  ·  {r.get('status', '')}  ·  {', '.join(r.get('platforms', []))}", "",
                      r["rule"], "", f"*EN:* {r.get('rule_en', '')}", "",
                      f"- **Warum:** {r.get('why', '')}",
                      f"- **So:** {r.get('do', '')}",
                      f"- **Nicht so:** {r.get('dont', '')}"]
            if r.get("numbers"):
                lines.append(f"- **Werte:** {r['numbers']}")
            lines += [f"- **Prüfung:** {r.get('check', '')}",
                      f"- **Entscheidung:** {', '.join(r.get('decisions', [])) or '–'} · **Quelle:** `{r.get('source', '')}`",
                      ""]
    return "\n".join(lines).rstrip() + "\n"


def llms_txt() -> str:
    lines = ["# sebaro Guide", "",
             "> The design guide of every sebaro app, website and desktop app: colour jobs, type, space, shape, "
             "behaviour, components, data display and the reasoning behind them. German UI language (du).", "",
             f"Machine-readable rules: {SITE_URL}rules.json · Markdown: {REPO_URL}/blob/main/guide/RULES.md · "
             f"Agent entry: {REPO_URL}/blob/main/AGENTS.md", "",
             "## Building a product", "",
             f"- [Agent snippet]({REPO_URL}/blob/main/templates/AGENTS-snippet.md): paste into the product's AGENTS.md; "
             "its first item says per product kind where light/dark, language, tone and the ⌘K palette go",
             f"- [Starters]({REPO_URL}/blob/main/templates/README.md): website (Astro), web app (Vite), desktop (Tauri), "
             "Android (Compose); each README lists what the starter itself does not do yet",
             f"- [Screen checklist]({REPO_URL}/blob/main/templates/screen-checklist.md): walk it before a screen is done; "
             "record every check in CHECKS.md (TEC-06)",
             f"- [Agent test 2026-10]({REPO_URL}/blob/main/docs/agenten-test-2026-10.md): the rules agents missed most "
             "(TEC-06, TXT-04 U+00A0, EBE-05, BEL-10, NAV-06) and why",
             "", "## Pages", ""]
    for file, label, _icon, desc in PAGES:
        lines.append(f"- [{label}]({SITE_URL}{file}): {desc}")
    lines += ["", "## System files (generated, never edit)", "",
              f"- [tokens.css]({SITE_URL}sebaro/tokens.css): every --sb-* custom property, light and dark",
              f"- [sebaro.css]({SITE_URL}sebaro/css/sebaro.css): reference components (sb-*)",
              f"- [sprite.svg]({SITE_URL}sebaro/icons/sprite.svg): icon sprite",
              f"- [fonts.css]({SITE_URL}sebaro/fonts/fonts.css): self-hosted sebaro Sans + sebaro Mono", ""]
    return "\n".join(lines)


def outputs() -> dict[Path, str]:
    out = {}
    if RULES.is_file():
        out[DOCS / "rules.json"] = RULES.read_text(encoding="utf-8")
        out[ROOT / "guide" / "RULES.md"] = rules_markdown()
    out[DOCS / "llms.txt"] = llms_txt()
    out[OG_PAGES] = og_pages()
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("pages", nargs="*", help="only these docs/*.html files (no other outputs); default: everything")
    args = ap.parse_args()
    stale = []
    files = [Path(p).resolve() for p in args.pages] if args.pages else sorted(DOCS.glob("*.html"))
    if not args.pages:
        # keep the guide:tile blocks inside rule fragments fresh too (they are inlined into regeln.html)
        files += sorted(EXAMPLES.glob("*.html"))
    targets = {p: fill(p.read_text(encoding="utf-8")) for p in files}
    if not args.pages:
        targets.update(outputs())
    for path, new in targets.items():
        old = path.read_text(encoding="utf-8") if path.is_file() else None
        if old != new:
            stale.append(path.relative_to(ROOT).as_posix())
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(new, encoding="utf-8")
    for pid in sorted(set(OG_MISSING)):
        print(f"error: no share-image snippet src/og/head/{pid}.head.html (render: node tools/og.mjs, then build again)")
    if args.check:
        for s in stale:
            print(f"stale: {s}")
        print(f"build --check: {len(stale)} stale of {len(targets)}")
        return 1 if stale or OG_MISSING else 0
    print(f"build: wrote {len(stale)} of {len(targets)} files")
    return 1 if OG_MISSING else 0


if __name__ == "__main__":
    sys.exit(main())
