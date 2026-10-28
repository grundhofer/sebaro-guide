#!/bin/sh
# lint-sebaro-android.sh [kotlin source folder]
#
# Text checks for an Android app that takes sebaro from the sebaro-compose package. They catch what Android Lint
# does not know: screens that draw sebaro's parts themselves instead of using the package's wrappers. The app never
# holds a copy of the package, so no folder is exempt. Default folder: app/src/main/kotlin next to this tools/ folder.
# Exit 0: nothing found. Exit 1: every offending line is printed with the rule it breaks. Exit 2: no such folder.
#
# What is checked (rule ids of the sebaro guide):
#   S1 the theme comes only from SebaroAppTheme(...): no SebaroTheme(...) call, so no product colour (MOB-01, ZEI-01)
#   S2 SebaroProduct only to pick the sign tile: SbSignTile or SebaroProduct.fromId on the same line (ZEI-01)
#   S3 the lime colour roles stay inside the wrappers: no .primaryAction… / .onPrimaryAction colour read (AKT-01, FAR-01)
#   S4 no stock Material 3 buttons, FAB, navigation bar or AlertDialog (MOB-02, NAV-01)
#   S5 no tinted areas: no …Subtle colour roles (EBE-01)
#   S6 no count badges (HAL-05)
#   S7 no raw colours: no Color(0x…), Color.rgb(…), parseColor(…) (FAR-01)
#   S8 the primary action only through SbPrimaryActionModel: no SbPrimaryAction(…) call (AKT-01, AKT-02)
#   S9 every file that defines a …Screen composable puts it on SbScreen (MOB-01)
#   S10 every SbNavItem has a word (NAV-02)
# Not checked here, look at it in review: icon-only buttons outside the top bar, the order of actions in a group.

dir=${1:-$(cd "$(dirname "$0")/.." && pwd)/app/src/main/kotlin}
if [ ! -d "$dir" ]; then
    echo "lint-sebaro-android: no folder $dir" >&2
    exit 2
fi

found=0

# report <rule> <extended regex> [regex of lines that may match]
report() {
    rule=$1
    pattern=$2
    allowed=${3:-}
    hits=$(grep -rnE --include='*.kt' --include='*.kts' "$pattern" "$dir" || true)
    if [ -n "$allowed" ] && [ -n "$hits" ]; then
        hits=$(printf '%s\n' "$hits" | grep -vE "$allowed" || true)
    fi
    if [ -n "$hits" ]; then
        printf '%s\n' "$hits" | sed "s/^/$rule: /"
        found=1
    fi
}

report S1 '(^|[^A-Za-z0-9_.])SebaroTheme[[:space:]]*\('
report S2 'SebaroProduct\.' 'SbSignTile|SebaroProduct\.fromId'
report S3 '\.(on)?[pP]rimaryAction(Hover|Pressed|Outline)?([^A-Za-z0-9_]|$)'
report S4 '(^|[^A-Za-z0-9_])(Button|FilledTonalButton|ElevatedButton|OutlinedButton|TextButton|FloatingActionButton|ExtendedFloatingActionButton|SmallFloatingActionButton|LargeFloatingActionButton|NavigationBar|NavigationBarItem|NavigationRail|AlertDialog|BasicAlertDialog)[[:space:]]*[({]'
report S5 '(accent|success|warning|danger|info)Subtle|textOn[A-Za-z]*Subtle'
report S6 '(^|[^A-Za-z0-9_])(Badge|BadgedBox)[[:space:]]*[({]'
report S7 'Color\(0[xX]|Color\.rgb\(|Color\.argb\(|parseColor\('
report S8 '(^|[^A-Za-z0-9_])SbPrimaryAction[[:space:]]*\('
report S10 'SbNavItem\([[:space:]]*(""|\))'

# S9: a file with "fun <Name>Screen(" must call SbScreen(
for file in $(grep -rlE --include='*.kt' 'fun [A-Z][A-Za-z0-9_]*Screen[[:space:]]*\(' "$dir"); do
    if ! grep -qE '(^|[^A-Za-z0-9_])SbScreen[[:space:]]*\(' "$file"; then
        echo "S9: $file: defines a screen without SbScreen"
        found=1
    fi
done

if [ "$found" -eq 0 ]; then
    echo "lint-sebaro-android: no findings in $dir"
fi
exit $found
