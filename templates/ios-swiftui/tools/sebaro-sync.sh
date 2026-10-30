#!/bin/sh
# sebaro-sync.sh <sebaroDesign checkout> <exclusion list>
#
# Updates SebaroDesign/, this template's copy of the sebaro iOS export (the local Swift package), from a checkout of
# the workshop sebaroDesign (private): the counterpart of the web templates' `npm run sebaro:sync`. The copy in git is
# a snapshot; nothing updates it but this script.
#
# <exclusion list>: the private list of unreleased products no public file may name, as a file (JSON
# {"excludeProducts": [...]}, e.g. a guide checkout's git-ignored tools/sync.local.json, or one id per line) or as ids
# separated by commas. It is passed to export_system.py, which then leaves those products out and keeps only their
# number in sebaro-export.json. Never write the list into this folder.
#
# Steps: export_system.py --target ios into SebaroDesign/ (it replaces the folder's exported files), then
# export_system.py --verify (sources, gates and every file), then tools/sebaro-verify.py (the strict file check CI runs).
# Exit 0: updated and verified. Exit 1: the export or a check failed. Exit 2: usage.

set -eu
if [ $# -ne 2 ]; then
    echo "usage: $0 <sebaroDesign checkout> <exclusion list file or ids>" >&2
    exit 2
fi
workshop=$(cd "$1" && pwd)
exclude=$2
here=$(cd "$(dirname "$0")/.." && pwd)
tool="$workshop/tools/export_system.py"
if [ ! -f "$tool" ]; then
    echo "sebaro-sync: no tools/export_system.py in $workshop" >&2
    exit 2
fi
case $exclude in
    */*|*.json|*.txt) exclude=$(cd "$(dirname "$exclude")" && pwd)/$(basename "$exclude") ;;
esac

cd "$workshop"
python3 "$tool" sebaro --target ios --out "$here/SebaroDesign" --exclude-products "$exclude" || exit 1
python3 "$tool" --verify "$here/SebaroDesign" --exclude-products "$exclude" || exit 1
python3 "$here/tools/sebaro-verify.py" "$here/SebaroDesign" || exit 1
echo "sebaro-sync: SebaroDesign/ updated; build and run the tests, look at the screenshots, then commit the folder"
