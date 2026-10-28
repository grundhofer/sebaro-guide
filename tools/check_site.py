#!/usr/bin/env python3
"""Static checks of the guide site (docs/) and the rule catalogue. Standard library only.

    python3 tools/check_site.py            # all groups, exit 1 on any error
    python3 tools/check_site.py --strict   # warnings count as errors

Groups
  PAGE   every docs/*.html: lang="de", <title>, exactly one <h1>, guide:og/head/header/footer blocks, unique ids (the
         inlined icon sprite included: a section id equal to an icon id is reported as such); rule fragments in
         src/rule-examples/ use no icon id of the sprite
  LINK   every relative href/src resolves to a file; same-page and cross-page #fragments exist; a link never points
         at an icon of the inlined sprite (only <use href> does)
  NET    no foreign requests: no http(s) in src=, <link href>, CSS url(), @import (plain <a href> links are allowed;
         <link rel="canonical"> is no request and is checked by OG instead)
  CSS    docs/assets/*.css (not vendor/): only var(--sb-*) colours, no hex/rgb/hsl literals, no box-shadow; a rule
         whose every selector is scoped by .g-ex--dont (a deliberate "Nicht so" specimen, not its label or note)
         may use both
  TOKEN  every var(--sb-*) in docs/*.html and docs/assets/*.css (not vendor/, not sebaro/) names a custom property
         that docs/sebaro/tokens.css or docs/sebaro/css/sebaro.css defines or reads (removed tokens fail here; prose
         like "--sb-space-" without var() is not checked)
  STYLE  inline style="" attributes contain no colour literals, except inside a .g-ex--dont specimen
  SWATCH every .g-swatch (FAR-13) sits on a reference page (index, grundlagen, regeln), has role="img" and a name
         that starts with "Farbfeld"
  LICENSE LICENSE.md is byte-identical to docs/sebaro/LICENSE.md (D76: one licence file for workshop, guide, export)
  RULES  rules/rules.json: unique ids, required fields, known areas/status; every rule rendered in regeln.html;
         missing example fragments in src/rule-examples/ are warnings
  TEXT   U+202F / U+2009 are not used in page text (D22: U+00A0 between number and unit)
  CHANGE every rule that differs from the last snapshot in rules/releases/ (new, changed, removed) is named under
         "Unveröffentlicht" in CHANGELOG.md and carries a newer "changed" date (a rule already dated on the day of the
         last release may keep that day, it cannot move further the same day); the version is the last release's
  OG     share images (D96 (a), WEB-09): every page has exactly one canonical and one each of og:type (website on the
         start page, else article), og:site_name, og:locale de_DE, og:url, og:title, og:description, og:image with
         width 1200, height 630 and a non-empty alt, twitter:card summary_large_image, and one meta description;
         canonical = og:url = the page's address under SITE_URL, og:title = its <h1>, og:description = its meta
         description, og:image = SITE_URL og/<page>.png. docs/og/ holds exactly those PNGs, each 1200 x 630, 8-bit RGB
         without alpha (colour type 2, no tRNS), and its most frequent colour is --sb-color-bg of [data-theme="light"]
         in docs/sebaro/tokens.css (within 2 per channel, like render.mjs). The PNG bytes are not compared: Linux and
         macOS render the fonts with other pixels (tools/og.mjs --check). Warning: an input recorded in
         src/og/head/inputs.json (page list, template, script, tokens, fonts, sprite, tile, lockups) changed since
         the images were rendered (render again: node tools/og.mjs, then tools/build.py)
  TERM   retired names do not appear in pages, fragments, rules or docs (D71: only "sebaro Sans" and "sebaro Mono");
         the font licence files in docs/sebaro/ keep the authors' copyright as the OFL requires, and so do the copies of
         the export in the starter templates (templates/*/public/sebaro/, not scanned; see template_files())
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import sys
import zlib
from collections import Counter
from itertools import accumulate
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
RULES = ROOT / "rules" / "rules.json"
EXAMPLES = ROOT / "src" / "rule-examples"
SITE_URL = "https://grundhofer.github.io/sebaro-guide/"   # as tools/build.py
OG_DIR = DOCS / "og"
OG_STAMP = ROOT / "src" / "og" / "head" / "inputs.json"
OG_SIZE = (1200, 630)
OG_ONCE = ["og:type", "og:site_name", "og:locale", "og:url", "og:title", "og:description", "og:image",
           "og:image:width", "og:image:height", "og:image:alt"]
REQUIRED_RULE_FIELDS = ["id", "area", "title", "rule", "rule_en", "why", "do", "dont", "decisions", "source",
                        "platforms", "status", "check", "changed"]
COLOUR_LITERAL = re.compile(r"#[0-9a-fA-F]{3,8}\b|\b(?:rgb|rgba|hsl|hsla|oklch|oklab|lab|lch|color)\(", re.I)
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}
SWATCH_PAGES = {"index.html", "grundlagen.html", "regeln.html"}
# a token name; wildcards in prose such as var(--sb-color-*) or var(--sb-space-…) are not names
VAR_SB = re.compile(r"var\(\s*(--sb-[A-Za-z0-9_-]*[A-Za-z0-9_])(?![-*…A-Za-z0-9_])")


def template_files() -> list[Path]:
    """Files of templates/ for TERM. Left out: a copy of the web export inside a starter template (a folder that holds
    sebaro-export.json; its font licence keeps the authors' copyright as the OFL requires, like docs/sebaro/, and
    checks/verify-export.mjs --strict checks it against its record) and the folders a template's install, build or
    tests write (git-ignored there, never committed)."""
    base = ROOT / "templates"
    generated = {"node_modules", "dist", "build", "target", "test-results", "playwright-report", ".astro"}
    out: list[Path] = []
    for folder, dirs, files in os.walk(base):
        if "sebaro-export.json" in files:
            dirs[:] = []
            continue
        dirs[:] = sorted(d for d in dirs if d not in generated)
        out += [Path(folder) / f for f in sorted(files) if "." in f]
    return out


def is_dont_scoped(prelude: str) -> bool:
    """True when every selector of a CSS rule targets the inside of a .g-ex--dont specimen (not its label or note)."""
    sels = [x.strip() for x in prelude.split(",") if x.strip()]
    return bool(sels) and all(".g-ex--dont" in x and "g-ex__label" not in x and "g-ex__note" not in x for x in sels)


def css_blocks(body: str) -> list[tuple[int, int, str]]:
    """(start, end, prelude) of every {…} block, outermost first; comments must be stripped already."""
    blocks, stack, last = [], [], 0
    for i, ch in enumerate(body):
        if ch == "{":
            stack.append((i, body[last:i].strip()))
            last = i + 1
        elif ch == "}":
            if stack:
                start, prelude = stack.pop()
                blocks.append((start, i, prelude))
            last = i + 1
        elif ch == ";":
            last = i + 1
    return blocks


def dont_exempt(blocks: list[tuple[int, int, str]], pos: int) -> bool:
    """Is position pos inside a rule (not an @-rule) whose selectors are all .g-ex--dont scoped?"""
    inner = [b for b in blocks if b[0] < pos < b[1] and not b[2].startswith("@")]
    return bool(inner) and is_dont_scoped(min(inner, key=lambda b: b[1] - b[0])[2])


class Page(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.refs: list[tuple[str, str, str]] = []  # (tag, attr, value)
        self.styles: list[str] = []
        self.h1 = 0
        self.lang = None
        self.title = False
        self._in_title = False
        self.text: list[str] = []
        self._skip = 0
        self._stack: list[tuple[str, bool]] = []   # (tag, inside a .g-ex--dont specimen)
        self.dont_styles = 0
        self.swatches: list[dict] = []
        self.var_refs: list[str] = []
        self.canonical: list[str] = []
        self.meta: list[tuple[str, str]] = []      # (property or name, content)
        self.h1_text: list[str] = []
        self._in_h1 = False

    def _dont(self, a: dict) -> bool:
        cls = (a.get("class") or "").split()
        if "g-ex__label" in cls or "g-ex__note" in cls:
            return False
        return "g-ex--dont" in cls or (bool(self._stack) and self._stack[-1][1])

    def handle_starttag(self, tag, attrs, closed=False):
        a = dict(attrs)
        dont = self._dont(a)
        if not closed and tag not in VOID:
            self._stack.append((tag, dont))
        if "g-swatch" in (a.get("class") or "").split():
            self.swatches.append(a)
        if tag == "html":
            self.lang = a.get("lang")
        if tag == "h1":
            self.h1 += 1
            self._in_h1 = self.h1 == 1
        if tag == "meta" and (a.get("property") or a.get("name")):
            self.meta.append((a.get("property") or a.get("name") or "", a.get("content") or ""))
        if tag == "link" and (a.get("rel") or "").strip().lower() == "canonical":
            self.canonical.append(a.get("href") or "")   # no request; OG checks it instead of NET
            a = {k: v for k, v in a.items() if k != "href"}
        if tag == "title":
            self._in_title = True
        if tag in ("script", "style"):
            self._skip += 1
        if "id" in a and a["id"] is not None:
            self.ids.append(a["id"])
        for attr in ("href", "src", "xlink:href", "srcset", "poster", "action"):
            if a.get(attr):
                self.refs.append((tag, attr, a[attr]))
        if a.get("style"):
            self.var_refs += VAR_SB.findall(a["style"])
            if dont:
                self.dont_styles += bool(COLOUR_LITERAL.search(a["style"]))
            else:
                self.styles.append(a["style"])

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs, closed=True)
        if tag in ("script", "style"):
            self._skip -= 1

    def handle_endtag(self, tag):
        for i in range(len(self._stack) - 1, -1, -1):
            if self._stack[i][0] == tag:
                del self._stack[i:]
                break
        if tag == "title":
            self._in_title = False
        if tag == "h1":
            self._in_h1 = False
        if tag in ("script", "style"):
            self._skip = max(0, self._skip - 1)

    def handle_data(self, data):
        if self._in_title and data.strip():
            self.title = True
        if self._in_h1:
            self.h1_text.append(data)
        self.var_refs += VAR_SB.findall(data)   # <style> blocks and code samples alike
        if not self._skip:
            self.text.append(data)


def png_info(data: bytes) -> tuple[int, int, int, int, set[str], bytes]:
    """(width, height, bit depth, colour type, chunk types, zlib data) of a PNG; raises ValueError."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, ihdr, idat, kinds = 8, None, [], set()
    while pos + 8 <= len(data):
        n, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        kinds.add(kind.decode("latin1"))
        if kind == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"IEND":
            break
        pos += 12 + n
    if not ihdr:
        raise ValueError("no IHDR")
    if ihdr[6]:
        raise ValueError("interlaced")
    return ihdr[0], ihdr[1], ihdr[2], ihdr[3], kinds, b"".join(idat)


def png_ground(width: int, height: int, raw: bytes) -> tuple[bytes, float]:
    """Most frequent colour of an 8-bit RGB image (filters 0-4) and its share of the pixels."""
    stride, bpp = width * 3, 3
    m7, m8 = int.from_bytes(b"\x7f" * stride, "big"), int.from_bytes(b"\x80" * stride, "big")
    prev, counts = bytes(stride), Counter()
    for y in range(height):
        f, line = raw[y * (stride + 1)], raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)]
        if f == 0:
            cur = line
        elif f == 2:   # Up: bytewise sum without carries, on whole rows at once
            x, p = int.from_bytes(line, "big"), int.from_bytes(prev, "big")
            cur = (((x & m7) + (p & m7)) ^ ((x ^ p) & m8)).to_bytes(stride, "big")
        elif f == 1:   # Sub: a running sum per channel
            b = bytearray(stride)
            for c in range(bpp):
                b[c::bpp] = bytes(v & 255 for v in accumulate(line[c::bpp]))
            cur = bytes(b)
        else:          # Average, Paeth (render.mjs writes neither; kept for other encoders)
            b = bytearray(line)
            for i in range(stride):
                a, up, c = (b[i - bpp] if i >= bpp else 0), prev[i], (prev[i - bpp] if i >= bpp else 0)
                if f == 3:
                    b[i] = (b[i] + ((a + up) >> 1)) & 255
                else:
                    pp = a + up - c
                    pa, pb, pc = abs(pp - a), abs(pp - up), abs(pp - c)
                    b[i] = (b[i] + (a if pa <= pb and pa <= pc else up if pb <= pc else c)) & 255
            cur = bytes(b)
        counts.update(cur[k:k + 3] for k in range(0, stride, 3))
        prev = cur
    colour, n = counts.most_common(1)[0]
    return colour, n / (width * height)


def page_url(name: str) -> str:
    return SITE_URL if name == "index.html" else SITE_URL + name


def parse(path: Path) -> Page:
    p = Page()
    p.feed(path.read_text(encoding="utf-8"))
    return p


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--only", help="report only findings that mention this text (e.g. app.html)")
    args = ap.parse_args()
    errors: list[str] = []
    warnings: list[str] = []
    pages = sorted(DOCS.glob("*.html"))
    parsed = {p.name: parse(p) for p in pages}
    sprite_file = DOCS / "sebaro" / "icons" / "sprite.svg"
    sprite_ids = set(re.findall(r'<symbol[^>]*\sid="([^"]+)"', sprite_file.read_text(encoding="utf-8"))) \
        if sprite_file.is_file() else set()

    # PAGE
    for name, pg in parsed.items():
        raw = (DOCS / name).read_text(encoding="utf-8")
        if pg.lang != "de":
            errors.append(f"PAGE {name}: <html lang> is {pg.lang!r}, expected 'de'")
        if not pg.title:
            errors.append(f"PAGE {name}: missing <title>")
        if pg.h1 != 1:
            errors.append(f"PAGE {name}: {pg.h1} <h1>, expected 1")
        for block in ("og", "head", "header", "footer", "sprite"):
            if f"<!-- guide:{block}" not in raw:
                errors.append(f"PAGE {name}: missing <!-- guide:{block} --> block")
        seen = set()
        for i in pg.ids:
            if i in seen:
                where = " (also an icon id of the inlined sprite; rename the page id)" if i in sprite_ids else ""
                errors.append(f"PAGE {name}: duplicate id {i!r}{where}")
            seen.add(i)
    for frag in sorted(EXAMPLES.glob("*.html")) if EXAMPLES.is_dir() else []:
        fp = parse(frag)
        for i in sorted(set(fp.ids) & sprite_ids):
            errors.append(f"PAGE src/rule-examples/{frag.name}: id {i!r} is an icon id of the sprite inlined into regeln.html")

    # LINK + NET
    for name, pg in parsed.items():
        for tag, attr, value in pg.refs:
            parts = urlsplit(value)
            if parts.scheme in ("http", "https", "") and parts.netloc:
                if not (tag == "a" and attr == "href"):
                    errors.append(f"NET {name}: foreign request <{tag} {attr}={value!r}>")
                continue
            if parts.scheme in ("mailto", "tel", "data", "javascript"):
                if parts.scheme == "javascript":
                    errors.append(f"LINK {name}: javascript: URL")
                continue
            if attr == "srcset":
                continue
            target_name = unquote(parts.path)
            if target_name:
                target = (DOCS / target_name).resolve()
                if not target.exists():
                    errors.append(f"LINK {name}: {value!r} -> missing {target_name}")
                    continue
            else:
                target = DOCS / name
            frag = unquote(parts.fragment)
            if frag and tag != "use" and frag in sprite_ids and target.suffix == ".html":
                errors.append(f"LINK {name}: {value!r} points at an icon of the inlined sprite, not at a section")
                continue
            if frag and target.suffix == ".html" and target.parent == DOCS and target.name in parsed:
                if frag not in parsed[target.name].ids and frag != "top":
                    errors.append(f"LINK {name}: {value!r} -> no id {frag!r} in {target.name}")

    # CSS
    dont_css = 0
    for css in sorted((DOCS / "assets").glob("*.css")):
        text = css.read_text(encoding="utf-8")
        # blank the comments but keep their newlines, so line numbers stay true
        body = re.sub(r"/\*.*?\*/", lambda m: re.sub(r"[^\n]", " ", m.group(0)), text, flags=re.S)
        blocks = css_blocks(body)
        for m in COLOUR_LITERAL.finditer(body):
            if dont_exempt(blocks, m.start()):
                dont_css += 1
                continue
            line = body[: m.start()].count("\n") + 1
            errors.append(f"CSS {css.name}:{line}: colour literal {m.group(0)!r}; use var(--sb-color-*)")
        for m in re.finditer(r"box-shadow\s*:\s*(?!none)", body):
            if dont_exempt(blocks, m.start()):
                dont_css += 1
                continue
            line = body[: m.start()].count("\n") + 1
            errors.append(f"CSS {css.name}:{line}: box-shadow (D46: ink lines instead of shadows)")
        for m in re.finditer(r"url\(\s*['\"]?https?:", body):
            errors.append(f"NET {css.name}: remote url()")
        for m in re.finditer(r"@import\s+['\"]?https?:", body):
            errors.append(f"NET {css.name}: remote @import")

    # TOKEN
    known: set[str] = set()
    for src in (DOCS / "sebaro" / "tokens.css", DOCS / "sebaro" / "css" / "sebaro.css"):
        if src.is_file():
            known |= set(re.findall(r"(--sb-[A-Za-z0-9_-]+)\s*:", src.read_text(encoding="utf-8")))   # defined
            known |= set(VAR_SB.findall(src.read_text(encoding="utf-8")))                          # read as input
    if not known:
        errors.append("TOKEN docs/sebaro/tokens.css and css/sebaro.css missing or empty")
    else:
        for name, pg in parsed.items():
            for v in sorted(set(pg.var_refs) - known):
                errors.append(f"TOKEN {name}: var({v}) is not a sebaro token (removed or misspelt)")
        for css in sorted((DOCS / "assets").glob("*.css")):
            body = css.read_text(encoding="utf-8")
            for m in VAR_SB.finditer(body):
                if m.group(1) not in known:
                    line = body[: m.start()].count("\n") + 1
                    errors.append(f"TOKEN {css.name}:{line}: var({m.group(1)}) is not a sebaro token (removed or misspelt)")

    # STYLE
    for name, pg in parsed.items():
        for st in pg.styles:
            if COLOUR_LITERAL.search(st):
                errors.append(f"STYLE {name}: colour literal in style={st!r}")

    # SWATCH
    for name, pg in parsed.items():
        for a in pg.swatches:
            label = (a.get("aria-label") or "").strip()
            if name not in SWATCH_PAGES:
                errors.append(f"SWATCH {name}: g-swatch only on reference pages {sorted(SWATCH_PAGES)} (FAR-13)")
            if a.get("role") != "img" or not label.startswith("Farbfeld"):
                errors.append(f"SWATCH {name}: g-swatch needs role=\"img\" and aria-label \"Farbfeld …\" (got {label!r})")

    # LICENSE
    lic, lic_export = ROOT / "LICENSE.md", DOCS / "sebaro" / "LICENSE.md"
    if not lic_export.is_file():
        errors.append("LICENSE docs/sebaro/LICENSE.md missing (re-export with tools/sync_from_design.py)")
    elif not lic.is_file() or lic.read_bytes() != lic_export.read_bytes():
        errors.append("LICENSE LICENSE.md differs from docs/sebaro/LICENSE.md (D76: the same file; copy it over)")

    # TEXT
    for name, pg in parsed.items():
        text = "".join(pg.text)
        for ch, label in ((" ", "U+202F"), (" ", "U+2009")):
            if ch in text:
                errors.append(f"TEXT {name}: {label} in text (D22: use U+00A0)")

    # CHANGE
    releases = sorted((ROOT / "rules" / "releases").glob("*.json"), key=lambda p: tuple(int(x) for x in p.stem.split(".")))
    if RULES.is_file() and releases:
        cur = json.loads(RULES.read_text(encoding="utf-8"))
        last = json.loads(releases[-1].read_text(encoding="utf-8"))
        log = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8") if (ROOT / "CHANGELOG.md").is_file() else ""
        m = re.search(r"## Unveröffentlicht\n(.*?)(?=\n## )", log, re.S)
        pending = m.group(1) if m else ""
        if cur.get("version") != releases[-1].stem:
            errors.append(f"CHANGE rules.json version {cur.get('version')} != last release {releases[-1].stem} (use tools/release.py)")
        rel_date = last.get("date", "")
        old = {r["id"]: r for r in last.get("rules", [])}
        new = {r["id"]: r for r in cur.get("rules", [])}
        strip = lambda r: {k: v for k, v in r.items() if k != "changed"}
        for rid in sorted(set(old) | set(new)):
            if rid in old and rid in new and strip(old[rid]) == strip(new[rid]):
                continue
            if not re.search(rf"\b{re.escape(rid)}\b", pending):
                kind = "new" if rid not in old else "removed" if rid not in new else "changed"
                errors.append(f"CHANGE {rid} is {kind} since {releases[-1].stem} but not listed under 'Unveröffentlicht' in CHANGELOG.md")
            # the date moves forward; a rule already dated on the day of the last release may keep that day
            if rid in old and rid in new:
                was, now = old[rid].get("changed", ""), new[rid].get("changed", "")
                if now < rel_date or (now <= was and was < rel_date):
                    errors.append(f"CHANGE {rid} changed but its 'changed' date was not moved forward")

    # OG
    tokens_css = (DOCS / "sebaro" / "tokens.css").read_text(encoding="utf-8") if (DOCS / "sebaro" / "tokens.css").is_file() else ""
    m = re.search(r'\[data-theme="light"\]\s*\{[^}]*?--sb-color-bg:\s*#([0-9A-Fa-f]{6})\b', tokens_css)
    light_bg = bytes.fromhex(m.group(1)) if m else None
    if light_bg is None:
        errors.append('OG docs/sebaro/tokens.css: no --sb-color-bg under [data-theme="light"]')
    for name, pg in parsed.items():
        want_url, stem = page_url(name), name[:-len(".html")]
        tags: dict[str, list[str]] = {}
        for key, content in pg.meta:
            tags.setdefault(key, []).append(content)
        if pg.canonical != [want_url]:
            errors.append(f"OG {name}: canonical {pg.canonical!r}, expected one {want_url!r}")
        for key in OG_ONCE + ["twitter:card", "description"]:
            if len(tags.get(key, [])) != 1:
                errors.append(f"OG {name}: {len(tags.get(key, []))}x {key}, expected 1 (guide:og block; tools/build.py)")
        one = lambda key: (tags.get(key) or [""])[0]
        h1 = " ".join("".join(pg.h1_text).split())
        expect = {"og:type": "website" if name == "index.html" else "article", "og:site_name": "sebaro Guide",
                  "og:locale": "de_DE", "og:url": want_url, "og:title": h1, "og:description": one("description"),
                  "og:image": f"{SITE_URL}og/{stem}.png", "og:image:width": str(OG_SIZE[0]),
                  "og:image:height": str(OG_SIZE[1]), "twitter:card": "summary_large_image"}
        for key, value in expect.items():
            if key in tags and one(key) != value:
                errors.append(f"OG {name}: {key} is {one(key)!r}, expected {value!r} (render again: node tools/og.mjs, then tools/build.py)")
        if "og:image:alt" in tags and not one("og:image:alt").strip():
            errors.append(f"OG {name}: empty og:image:alt")
    wanted = {name[:-len(".html")] + ".png" for name in parsed}
    have = {p.name for p in OG_DIR.iterdir()} if OG_DIR.is_dir() else set()
    for extra in sorted(have - wanted):
        errors.append(f"OG docs/og/{extra} belongs to no page")
    for png in sorted(wanted):
        f = OG_DIR / png
        if not f.is_file():
            errors.append(f"OG docs/og/{png} missing (node tools/og.mjs)")
            continue
        try:
            w, h, depth, ctype, kinds, idat = png_info(f.read_bytes())
            if (w, h) != OG_SIZE or depth != 8 or ctype != 2 or "tRNS" in kinds:
                errors.append(f"OG docs/og/{png}: {w} x {h}, depth {depth}, colour type {ctype}"
                              f"{', tRNS' if 'tRNS' in kinds else ''}; expected 1200 x 630, 8-bit RGB without alpha")
                continue
            colour, share = png_ground(w, h, zlib.decompress(idat))
        except (ValueError, zlib.error, struct.error, IndexError) as e:
            errors.append(f"OG docs/og/{png}: unreadable PNG ({e})")
            continue
        if light_bg and any(abs(a - b) > 2 for a, b in zip(colour, light_bg)):
            errors.append(f"OG docs/og/{png}: ground #{colour.hex().upper()} ({share:.0%} of the pixels) is not "
                          f"color.bg light #{light_bg.hex().upper()}")
    if not OG_STAMP.is_file():
        errors.append("OG src/og/head/inputs.json missing (node tools/og.mjs)")
    else:
        stamp = json.loads(OG_STAMP.read_text(encoding="utf-8")).get("inputs", {})
        if "src/og/pages.json" not in stamp or "docs/sebaro/brand/og/template.html" not in stamp:
            errors.append("OG src/og/head/inputs.json does not record the page list and the template")
        for path, digest in sorted(stamp.items()):
            f = ROOT / path
            if not f.is_file() or hashlib.sha256(f.read_bytes()).hexdigest() != digest:
                warnings.append(f"OG {path} changed since the share images were rendered "
                                f"(node tools/og.mjs, then tools/build.py)")

    # TERM
    retired = re.compile(r"radio[\s_-]*canada", re.I)
    term_files = [p for p in DOCS.glob("*.html")] + [p for p in DOCS.glob("assets/*.*")] + \
        sorted(EXAMPLES.glob("*.html")) + [RULES, ROOT / "AGENTS.md", ROOT / "README.md", ROOT / "LICENSE.md"] + \
        template_files() + sorted((ROOT / "guide").glob("*.md")) + \
        [DOCS / "llms.txt", DOCS / "rules.json"] + [p for p in (ROOT / "tools").glob("*.py") if p.name != "check_site.py"]
    for f in term_files:
        if f.is_file() and retired.search(f.read_text(encoding="utf-8", errors="ignore")):
            n = len(retired.findall(f.read_text(encoding="utf-8", errors="ignore")))
            errors.append(f"TERM {f.relative_to(ROOT)}: {n}x retired font name (D71: only sebaro Sans / sebaro Mono)")

    # RULES
    if RULES.is_file():
        data = json.loads(RULES.read_text(encoding="utf-8"))
        area_ids = {a["id"] for a in data.get("areas", [])}
        ids = [r.get("id") for r in data.get("rules", [])]
        dup = {i for i in ids if ids.count(i) > 1}
        for i in sorted(dup):
            errors.append(f"RULES duplicate id {i}")
        for r in data.get("rules", []):
            for f in REQUIRED_RULE_FIELDS:
                if f not in r or r[f] in (None, ""):
                    errors.append(f"RULES {r.get('id')}: missing field {f}")
            if r.get("area") not in area_ids:
                errors.append(f"RULES {r.get('id')}: unknown area {r.get('area')!r}")
            if r.get("status") not in ("entschieden", "vorläufig", "offen"):
                errors.append(f"RULES {r.get('id')}: unknown status {r.get('status')!r}")
            if not (EXAMPLES / f"{r.get('id')}.html").is_file():
                warnings.append(f"RULES {r.get('id')}: no example fragment src/rule-examples/{r.get('id')}.html")
        if "regeln.html" in parsed:
            have = set(parsed["regeln.html"].ids)
            for i in ids:
                if i not in have:
                    errors.append(f"RULES {i}: not rendered in regeln.html (run tools/build.py)")
        for frag in sorted(EXAMPLES.glob("*.html")) if EXAMPLES.is_dir() else []:
            if frag.stem not in ids:
                warnings.append(f"RULES orphan example {frag.name}")
    else:
        warnings.append("RULES rules/rules.json missing")

    if args.only:
        errors = [e for e in errors if args.only in e]
        warnings = [w for w in warnings if args.only in w]
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    fail = bool(errors) or (args.strict and bool(warnings))
    dont_styles = sum(pg.dont_styles for pg in parsed.values())
    print(f"check_site: {len(pages)} pages, {len(errors)} errors, {len(warnings)} warnings -> {'FAIL' if fail else 'PASS'}"
          f" (.g-ex--dont exemptions used: {dont_css} in CSS, {dont_styles} inline styles)")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
