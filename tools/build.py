#!/usr/bin/env python3
"""Fill the generated blocks of the guide pages and write the machine-readable outputs.

Pages in docs/*.html are hand-written. Shared parts sit between marker comments and are rewritten by this script:

    <!-- guide:head -->            … <!-- /guide:head -->      fonts, tokens, sprite.css, sebaro.css, guide.css, scripts
    <!-- guide:sprite -->          … <!-- /guide:sprite -->    docs/sebaro/icons/sprite.svg, inlined (works from file://)
    <!-- guide:header page="x" --> … <!-- /guide:header -->    site header; page x gets aria-current
    <!-- guide:footer -->          … <!-- /guide:footer -->    site footer with sync state
    <!-- guide:tile id="novalis" size="48" --> … <!-- /guide:tile -->   brand/inline/tile-<id>[-small].svg
    <!-- guide:rules -->           … <!-- /guide:rules -->     regeln.html: every rule of rules/rules.json + its example
    <!-- guide:rules-toc -->       … <!-- /guide:rules-toc --> regeln.html: area list
    <!-- guide:stats -->           … <!-- /guide:stats -->     rule counts by status

Rule examples are fragments in src/rule-examples/<RULE-ID>.html. Outputs written besides the pages:
docs/rules.json (copy of rules/rules.json), guide/RULES.md (all rules as Markdown for agents), docs/llms.txt.

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
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
SEBARO = DOCS / "sebaro"
RULES = ROOT / "rules" / "rules.json"
EXAMPLES = ROOT / "src" / "rule-examples"
REPO_URL = "https://github.com/grundhofer/sebaro-guide"
SITE_URL = "https://grundhofer.github.io/sebaro-guide/"

# file, label, icon (sprite id), one line for llms.txt
PAGES = [
    ("index.html", "Start", "home", "Einstieg: was sebaro ist, die Kernregeln in sieben Sätzen, Wege durch den Guide"),
    ("regeln.html", "Regeln", "check", "Alle Gestaltungsregeln mit ID, Begründung, Prüfung und Live-Beispiel (richtig/falsch)"),
    ("grundlagen.html", "Grundlagen", "board", "Farben, Schrift, Raum, Form, Linien, Ebenen, Bewegung: alle Tokens mit Werten"),
    ("bauteile.html", "Bauteile", "copy", "Alle Komponenten mit Zuständen und Markup"),
    ("daten.html", "Daten", "chart-bar", "Jede Datenart einmal dargestellt: Text, Zahlen, Zeit, Status, Listen, Tabellen, Diagramme, Code …"),
    ("web.html", "Web", "globe", "Beispiel-Website mit allen typischen Seiten und Fällen"),
    ("app.html", "App", "file", "Beispiel-App am Handy: alle typischen Bildschirme und Zustände"),
    ("desktop.html", "Desktop", "folder", "Beispiel-Desktop-App (Tauri/macOS): Fenster, Seitenleiste, Tabellen, Menüs, Tastatur"),
    ("gedanken.html", "Gedanken", "book", "Die Gedanken dahinter: Haltung, Geschichte, Entscheidungen, Abwägungen"),
    ("ausblick.html", "Ausblick", "arrow-right", "Vorschläge zur Weiterentwicklung und offene Fragen"),
]

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


def text(s: str, lang: str = "de") -> str:
    """Escape rule text for HTML and replace characters the fonts lack."""
    out = esc(s)
    for ch, word in (GLYPH_WORDS_EN if lang == "en" else GLYPH_WORDS).items():
        out = out.replace(ch, word)
    for ch, (name, label) in GLYPH_ICONS.items():
        out = out.replace(ch, f'<svg class="sb-icon sb-icon--16" role="img" aria-label="{label}" focusable="false">'
                              f'<use href="#{name}"/></svg>')
    return out.replace("Delta- ", "Delta-")


def icon(name: str, size: int = 16) -> str:
    return (f'<svg class="sb-icon sb-icon--{size}" aria-hidden="true" focusable="false">'
            f'<use href="#{name}"/></svg>')


def sync_state() -> dict:
    p = SEBARO / "GUIDE-SYNC.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.is_file() else {}


def rules_data() -> dict:
    return json.loads(RULES.read_text(encoding="utf-8")) if RULES.is_file() else {"areas": [], "rules": []}


# ------------------------------------------------------------------ blocks

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
        '<script defer src="assets/guide.js"></script>',
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
        cur = ' aria-current="page"' if file == current else ""
        links.append(f'<a href="{file}"{cur}>{esc(label)}</a>')
    return "\n".join([
        '<a class="sb-skip-link" href="#inhalt">Zum Inhalt</a>',
        '<header class="sb-site-header g-header">',
        '  <a class="sb-lockup" href="index.html">',
        f'    <span class="sb-sign-tile sb-sign-tile--32" aria-hidden="true">{tile_svg("studio", "32")}</span>',
        '    <span class="sb-wordmark">sebaro</span><span class="g-header__suffix">Guide</span>',
        '  </a>',
        '  <button class="sb-theme-button" type="button" data-sb-theme-button>Hell oder Dunkel</button>',
        '  <div class="sb-site-header__links">',
        '    <nav class="sb-site-nav g-nav" aria-label="Hauptmenü">',
        "      " + " ".join(links),
        '    </nav>',
        '  </div>',
        '  <span class="sb-visually-hidden" role="status" data-sb-theme-status></span>',
        '</header>',
    ])


def block_footer(_attrs: dict) -> str:
    st = sync_state()
    commit = (st.get("sebaroDesignCommit") or "")[:7]
    contracts = st.get("contracts") or {}
    return "\n".join([
        '<footer class="sb-site-footer g-footer">',
        f'  <p>sebaro Guide <a href="{REPO_URL}/blob/main/CHANGELOG.md">Version {esc(rules_data().get("version", "?"))}{icon("external-link--16")}</a> · '
        f'System sebaro, Token-Vertrag {esc(str(contracts.get("tokens", "?")))} · '
        f'aus sebaroDesign <code class="sb-code-inline">{esc(commit)}</code></p>',
        '  <ul class="sb-site-footer__links">',
        '    <li><a href="rules.json">rules.json</a></li>',
        '    <li><a href="llms.txt">llms.txt</a></li>',
        f'    <li><a href="{REPO_URL}">GitHub{icon("external-link--16")}</a></li>',
        f'    <li><a href="{REPO_URL}/blob/main/AGENTS.md">Für Agenten{icon("external-link--16")}</a></li>',
        '  </ul>',
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


BLOCKS = {"head": block_head, "sprite": block_sprite, "header": block_header, "footer": block_footer,
          "tile": block_tile, "rules": block_rules, "rules-toc": block_rules_toc, "stats": block_stats}
MARKER = re.compile(r'<!-- guide:(?P<name>[a-z-]+)(?P<attrs>(?:\s+[a-z]+="[^"]*")*)\s*-->'
                    r'(?P<body>.*?)<!-- /guide:(?P=name) -->', re.S)
ATTR = re.compile(r'([a-z]+)="([^"]*)"')


def fill(text: str) -> str:
    def repl(m: re.Match) -> str:
        name = m.group("name")
        attrs = dict(ATTR.findall(m.group("attrs") or ""))
        if name not in BLOCKS:
            raise SystemExit(f"unknown block guide:{name}")
        return f'<!-- guide:{name}{m.group("attrs")} -->\n{BLOCKS[name](attrs)}\n<!-- /guide:{name} -->'
    return MARKER.sub(repl, text)


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
             f"Agent entry: {REPO_URL}/blob/main/AGENTS.md", "", "## Pages", ""]
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
    if args.check:
        for s in stale:
            print(f"stale: {s}")
        print(f"build --check: {len(stale)} stale of {len(targets)}")
        return 1 if stale else 0
    print(f"build: wrote {len(stale)} of {len(targets)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
