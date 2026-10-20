#!/usr/bin/env python3
"""Pull the sebaro system from sebaroDesign into docs/sebaro/ (and the demo specimens into docs/assets/vendor/).

sebaroDesign is the workshop: palettes, contracts, generators and gates live there. This guide never edits colours,
fonts, icons or brand files by hand; it re-exports them with sebaroDesign's own tools/export_system.py and records
what it took in docs/sebaro/sebaro-export.json (with sha256 per file) plus docs/sebaro/GUIDE-SYNC.json.

    python3 tools/sync_from_design.py                 # export + verify + copy
    python3 tools/sync_from_design.py --check         # exit 1 if docs/sebaro/ differs from a fresh export
    python3 tools/sync_from_design.py --verify-local  # exit 1 if a file in docs/sebaro/ no longer matches its sha256
    python3 tools/sync_from_design.py --from-export DIR --exclude-from FILE --require-exclusions
                                                      # CI: take a web export the workshop already built (it is
                                                      # copied and verified, never changed), read exclusions from FILE

The design repository is found via --design, $SEBARO_DESIGN, or ../sebaroDesign next to this repository. It is
needed for every mode except --verify-local (export --verify and the demo specimens come from it).
Products to leave out are not published: their brand files are dropped and their manifest entries removed. Only their
number is recorded, never their names. The list is the union of the git-ignored tools/sync.local.json
({"excludeProducts": [...]}), every --exclude-from FILE (the same JSON, or one id per line, # comments allowed) and the
environment variable SEBARO_EXCLUDE_PRODUCTS (ids separated by commas or white space); the workshop's CI passes it from
a secret, so the names never enter this public repository. --require-exclusions refuses to run with an empty list.
Before anything is written, every text file of the result is scanned for the excluded ids; a hit refuses the sync.
Standard library only.
"""
from __future__ import annotations

import argparse
import filecmp
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
TARGET = DOCS / "sebaro"
VENDOR = DOCS / "assets" / "vendor"
CONFIG = ROOT / "tools" / "sync.config.json"


LOCAL = ROOT / "tools" / "sync.local.json"
EXCLUDE_ENV = "SEBARO_EXCLUDE_PRODUCTS"
TEXT_SUFFIXES = {".css", ".js", ".json", ".md", ".svg", ".txt", ".html", ".webmanifest"}


def read_exclusions(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    if text.lstrip().startswith("{"):
        return list(json.loads(text).get("excludeProducts", []))
    return [ln.split("#", 1)[0].strip() for ln in text.splitlines() if ln.split("#", 1)[0].strip()]


def load_config(exclude_from: list[Path] | None = None) -> dict:
    cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    # the names of unreleased products stay private: git-ignored sync.local.json, a file outside the repo, or the env
    names: list[str] = []
    if LOCAL.is_file():
        names += json.loads(LOCAL.read_text(encoding="utf-8")).get("excludeProducts", [])
    for path in exclude_from or []:
        names += read_exclusions(path)
    names += os.environ.get(EXCLUDE_ENV, "").replace(",", " ").split()
    cfg["excludeProducts"] = sorted({n.strip() for n in names if n.strip()})
    if not cfg["excludeProducts"]:
        print(f"note: no products excluded ({LOCAL.name}, --exclude-from and ${EXCLUDE_ENV} are empty)",
              file=sys.stderr)
    return cfg


def leaks(base: Path, names: list[str]) -> list[str]:
    """Relative paths of files whose path or text still names an excluded product (case-insensitive)."""
    hits = []
    for rel, p in sorted(tree_files(base).items()):
        low = rel.lower()
        text = p.read_text(encoding="utf-8", errors="replace").lower() if p.suffix in TEXT_SUFFIXES else ""
        if any(n.lower() in low or n.lower() in text for n in names):
            hits.append(rel)
    return hits


def find_design(arg: str | None) -> Path:
    for cand in (arg, os.environ.get("SEBARO_DESIGN"), str(ROOT.parent / "sebaroDesign")):
        if cand and (Path(cand) / "tools" / "export_system.py").is_file():
            return Path(cand).resolve()
    sys.exit("sebaroDesign not found: pass --design <path> or set SEBARO_DESIGN")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def export(design: Path, cfg: dict, out: Path, from_export: Path | None = None) -> dict:
    """Run export_system.py (or copy the given export) + --verify into out, then drop excluded products.
    Returns the guide sync record."""
    if from_export is None:
        cmd = [sys.executable, "tools/export_system.py", cfg["system"], "--target", "web", "--out", str(out),
               "--product", cfg["product"]]
        subprocess.run(cmd, cwd=design, check=True, stdout=subprocess.DEVNULL)
    else:
        rec = json.loads((from_export / "sebaro-export.json").read_text(encoding="utf-8"))
        got = (rec.get("system", {}).get("slug"), rec.get("target"), rec.get("product"))
        want = (cfg["system"], "web", cfg["product"])
        if got != want:
            sys.exit(f"{from_export} is a {got} export; the guide needs (system, target, product) = {want}")
        shutil.copytree(from_export, out)
    subprocess.run([sys.executable, "tools/export_system.py", "--verify", str(out)], cwd=design, check=True,
                   stdout=subprocess.DEVNULL)

    manifest_path = out / "sebaro-export.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    dropped = []
    for product in cfg.get("excludeProducts", []):
        for f in sorted(out.rglob(f"*{product}*")):
            if f.is_file():
                dropped.append(f.relative_to(out).as_posix())
                f.unlink()
    files = manifest.get("files")
    if isinstance(files, list):
        manifest["files"] = [e for e in files if not any(p in json.dumps(e) for p in cfg.get("excludeProducts", []))]
    elif isinstance(files, dict):
        manifest["files"] = {k: v for k, v in files.items()
                             if not any(p in k or p in json.dumps(v) for p in cfg.get("excludeProducts", []))}
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    vendor = {}
    for name in cfg.get("vendorSpecimens", []):
        src = design / "systems" / cfg["system"] / "demo" / "assets" / name
        vendor[name] = sha256(src)

    return {
        "$comment": "written by tools/sync_from_design.py; do not edit",
        "system": cfg["system"],
        "product": cfg["product"],
        "sebaroDesignCommit": manifest.get("sebaroDesign", {}).get("commit"),
        "sebaroDesignUncommitted": manifest.get("sebaroDesign", {}).get("uncommittedChanges"),
        "exportTool": manifest.get("tool"),
        "contracts": manifest.get("contracts"),
        "excludedProducts": len(cfg.get("excludeProducts", [])),
        "droppedFiles": len(dropped),
        "vendorSpecimens": vendor,
    }


def tree_files(base: Path) -> dict[str, Path]:
    return {p.relative_to(base).as_posix(): p for p in base.rglob("*") if p.is_file()}


def compare(a: Path, b: Path, ignore: set[str]) -> list[str]:
    fa, fb = tree_files(a), tree_files(b)
    diffs = []
    for rel in sorted(set(fa) | set(fb)):
        if rel in ignore:
            continue
        if rel not in fa or rel not in fb:
            diffs.append(f"only in {'fresh export' if rel in fa else 'docs/sebaro'}: {rel}")
        elif not filecmp.cmp(fa[rel], fb[rel], shallow=False):
            diffs.append(f"differs: {rel}")
    return diffs


def verify_local() -> int:
    manifest = json.loads((TARGET / "sebaro-export.json").read_text(encoding="utf-8"))
    files = manifest.get("files", [])
    entries = files.items() if isinstance(files, dict) else [(e.get("path"), e) for e in files]
    bad = 0
    for rel, entry in entries:
        want = entry.get("sha256") if isinstance(entry, dict) else None
        p = TARGET / rel
        if not p.is_file():
            print(f"missing: {rel}")
            bad += 1
        elif want and sha256(p) != want:
            print(f"changed: {rel}")
            bad += 1
    print(f"verify-local: {len(list(entries)) if not isinstance(files, dict) else len(files)} files, {bad} problems")
    return 1 if bad else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--design")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify-local", action="store_true")
    ap.add_argument("--from-export", type=Path, metavar="DIR",
                    help="use this web export (built with the product of sync.config.json) instead of running one")
    ap.add_argument("--exclude-from", type=Path, action="append", default=[], metavar="FILE",
                    help="more product ids to leave out (JSON like sync.local.json, or one id per line)")
    ap.add_argument("--require-exclusions", action="store_true",
                    help="exit 2 when no product is excluded (CI: a missing secret must not publish unreleased files)")
    args = ap.parse_args()

    if args.verify_local:
        return verify_local()

    cfg = load_config(args.exclude_from)
    if args.require_exclusions and not cfg["excludeProducts"]:
        print("error: --require-exclusions: no products to exclude; refusing to sync", file=sys.stderr)
        return 2
    if args.from_export is not None and not (args.from_export / "sebaro-export.json").is_file():
        print(f"error: {args.from_export} has no sebaro-export.json", file=sys.stderr)
        return 2
    design = find_design(args.design)
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "sebaro"
        record = export(design, cfg, out, args.from_export.resolve() if args.from_export else None)
        leaked = leaks(out, cfg["excludeProducts"])
        specimens = design / "systems" / cfg["system"] / "demo" / "assets"
        leaked += [f"vendor specimen {rel}" for rel in leaks(specimens, cfg["excludeProducts"])
                   if rel in cfg.get("vendorSpecimens", [])]
        if leaked:
            print(f"error: {len(leaked)} file(s) still name an excluded product; nothing was written:", file=sys.stderr)
            for rel in leaked:
                for n in cfg["excludeProducts"]:
                    rel = re.sub(re.escape(n), "<excluded>", rel, flags=re.I)
                print(f"    {rel}", file=sys.stderr)
            return 1
        if args.check:
            # date stamps differ between runs; compare everything else
            diffs = compare(out, TARGET, ignore={"sebaro-export.json", "GUIDE-SYNC.json"})
            for name in cfg.get("vendorSpecimens", []):
                src = design / "systems" / cfg["system"] / "demo" / "assets" / name
                if not (VENDOR / name).is_file() or not filecmp.cmp(src, VENDOR / name, shallow=False):
                    diffs.append(f"vendor specimen differs: {name}")
            for d in diffs:
                print(d)
            print(f"check: {len(diffs)} differences against sebaroDesign {record['sebaroDesignCommit']}")
            return 1 if diffs else 0

        if TARGET.exists():
            shutil.rmtree(TARGET)
        shutil.copytree(out, TARGET)
        VENDOR.mkdir(parents=True, exist_ok=True)
        for name in cfg.get("vendorSpecimens", []):
            shutil.copy2(design / "systems" / cfg["system"] / "demo" / "assets" / name, VENDOR / name)
        (TARGET / "GUIDE-SYNC.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n",
                                                 encoding="utf-8")
        print(f"synced sebaro from sebaroDesign {record['sebaroDesignCommit']}: "
              f"{len(tree_files(TARGET))} files, dropped {record['droppedFiles']} (excluded products)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
