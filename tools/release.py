#!/usr/bin/env python3
"""Turn the "Unveröffentlicht" section of CHANGELOG.md into a version.

    python3 tools/release.py 1.2.0            # sets rules.json version/date, snapshots rules/releases/1.2.0.json
    python3 tools/release.py 1.2.0 --date 2026-10-21

Refuses when the section is empty, the version is not higher than the last one, or check_site.py fails afterwards.
Run tools/build.py afterwards (the footer shows the version). Standard library only.
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules" / "rules.json"
RELEASES = ROOT / "rules" / "releases"
CHANGELOG = ROOT / "CHANGELOG.md"
HEAD = "## Unveröffentlicht"


def vtuple(v: str) -> tuple[int, ...]:
    return tuple(int(x) for x in v.split("."))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("version")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    args = ap.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        sys.exit("version must look like 1.2.0")
    last = max((p.stem for p in RELEASES.glob("*.json")), key=vtuple)
    if vtuple(args.version) <= vtuple(last):
        sys.exit(f"{args.version} is not higher than the last release {last}")
    text = CHANGELOG.read_text(encoding="utf-8")
    start = text.index(HEAD) + len(HEAD)
    end = text.index("\n## ", start)
    body = text[start:end].strip()
    if not body:
        sys.exit("nothing under 'Unveröffentlicht' in CHANGELOG.md")
    text = text[:start] + f"\n\n## {args.version} · {args.date}\n\n{body}\n" + text[end:]
    data = json.loads(RULES.read_text(encoding="utf-8"))
    data["version"], data["date"] = args.version, args.date
    out = json.dumps(data, ensure_ascii=False, indent=1) + "\n"
    RULES.write_text(out, encoding="utf-8")
    (RELEASES / f"{args.version}.json").write_text(out, encoding="utf-8")
    CHANGELOG.write_text(text, encoding="utf-8")
    print(f"released {args.version} ({args.date}); now run python3 tools/build.py and tools/check_site.py")
    return subprocess.call([sys.executable, str(ROOT / "tools" / "check_site.py")])


if __name__ == "__main__":
    sys.exit(main())
