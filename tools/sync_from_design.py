#!/usr/bin/env python3
"""Pull the sebaro system from sebaroDesign into docs/sebaro/ (and the demo specimens into docs/assets/vendor/).

sebaroDesign is the workshop: palettes, contracts, generators and gates live there. This guide never edits colours,
fonts, icons or brand files by hand; it re-exports them with sebaroDesign's own tools/export_system.py and records
what it took in docs/sebaro/sebaro-export.json (with sha256 per file) plus docs/sebaro/GUIDE-SYNC.json.

    python3 tools/sync_from_design.py                 # export + verify + copy
    python3 tools/sync_from_design.py --check         # exit 1 if docs/sebaro/ differs from a fresh export
    python3 tools/sync_from_design.py --verify-local  # exit 1 if a file in docs/sebaro/ no longer matches its sha256

The design repository is found via --design, $SEBARO_DESIGN, or ../sebaroDesign next to this repository.
Products listed in the git-ignored tools/sync.local.json ({"excludeProducts": [...]}) are not published: their brand
files are dropped and their manifest entries removed. Only their number is recorded, not their names.
Standard library only.
"""
from __future__ import annotations

import argparse
import filecmp
import hashlib
import json
import os
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


def load_config() -> dict:
    cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    # excludeProducts lives in the git-ignored sync.local.json: the names of unreleased products stay private
    if LOCAL.is_file():
        cfg.update(json.loads(LOCAL.read_text(encoding="utf-8")))
    else:
        print(f"note: {LOCAL.name} not found, no products excluded", file=sys.stderr)
    return cfg


def find_design(arg: str | None) -> Path:
    for cand in (arg, os.environ.get("SEBARO_DESIGN"), str(ROOT.parent / "sebaroDesign")):
        if cand and (Path(cand) / "tools" / "export_system.py").is_file():
            return Path(cand).resolve()
    sys.exit("sebaroDesign not found: pass --design <path> or set SEBARO_DESIGN")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def export(design: Path, cfg: dict, out: Path) -> dict:
    """Run export_system.py + --verify into out, then drop excluded products. Returns the guide sync record."""
    cmd = [sys.executable, "tools/export_system.py", cfg["system"], "--target", "web", "--out", str(out),
           "--product", cfg["product"]]
    subprocess.run(cmd, cwd=design, check=True, stdout=subprocess.DEVNULL)
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
    args = ap.parse_args()

    if args.verify_local:
        return verify_local()

    cfg = load_config()
    design = find_design(args.design)
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "sebaro"
        record = export(design, cfg, out)
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
