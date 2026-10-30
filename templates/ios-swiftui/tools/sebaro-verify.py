#!/usr/bin/env python3
"""sebaro-verify.py [export folder]

Checks the copy of the sebaro iOS export in SebaroDesign/ against its own record, without the workshop: every file
that sebaro-export.json lists must be there with exactly its sha256, and no other file may be there (dotfiles and dot
folders aside, e.g. the .swiftpm/ or .build/ that Xcode and SwiftPM write). The same strict check the web templates
run with checks/verify-export.mjs --strict; the iOS export does not carry that script. It does not see source drift:
whether sebaroDesign has moved on since the export only `tools/sebaro-sync.sh` can tell, with a workshop checkout.
Its first line names the snapshot from the record (exporter, workshop commit, token contract); the README and the
guide's changelog do not write these down, so they never go stale.

Exit 0: the copy is the export. Exit 1: a file is edited, missing or not part of the export. Exit 2: no record.
Standard library only (Python 3.9+).
"""
import hashlib
import json
import sys
from pathlib import Path

folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "SebaroDesign"
record_file = folder / "sebaro-export.json"
try:
    record = json.loads(record_file.read_text(encoding="utf-8"))
except (OSError, ValueError) as error:
    print(f"sebaro-verify: no readable {record_file}: {error}", file=sys.stderr)
    sys.exit(2)

problems = []
listed = set()
for entry in record.get("files", []):
    path = entry["path"]
    listed.add(path)
    file = folder / path
    if not file.is_file():
        problems.append(f"FAIL  missing: {path}")
    elif hashlib.sha256(file.read_bytes()).hexdigest() != entry["sha256"]:
        problems.append(f"FAIL  edited: {path}")
for file in sorted(folder.rglob("*")):
    relative = file.relative_to(folder)
    if file.is_file() and not any(part.startswith(".") for part in relative.parts):
        name = relative.as_posix()
        if name != "sebaro-export.json" and name not in listed:
            problems.append(f"FAIL  not part of the export: {name}")

source = record.get("sebaroDesign", {}).get("commit", "?")[:12]
print(f"sebaro-verify: {folder.name}/ = {record.get('system', {}).get('slug')} for {record.get('target')}, "
      f"exported {record.get('date')} by {record.get('tool')} from sebaroDesign {source}, "
      f"token contract {record.get('contracts', {}).get('tokens', '?')}")
for line in problems:
    print(line)
print(f"result: {'drift, ' + str(len(problems)) + ' finding(s)' if problems else 'up to date'}, {len(listed)} files")
sys.exit(1 if problems else 0)
