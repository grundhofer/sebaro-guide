#!/bin/sh
# lint-sebaro-ios.sh [swift source folder]
#
# Text checks for an iOS app that takes sebaro from the local SebaroDesign package (the iOS export). They catch what
# the Swift compiler does not know: screens that draw sebaro's parts themselves or use the system's look instead of
# sebaro's. The package folder SebaroDesign/ is the export and is never checked or edited. Default folder: Musterapp/
# next to this tools/ folder. Exit 0: nothing found. Exit 1: every offending line is printed with the rule it breaks.
# Exit 2: no such folder.
#
# The rules I1–I8 are those of sebaroDesign spec/12 §14; S9–S13 are this template's additions.
#   I1 no TabView and no .tabItem: the bottom bar is SbTabBar (NAV-02, MOB-05)
#   I2 no .alert( or .confirmationDialog(: dialogs are sbConfirmDialog / sbUnsavedDialog (AKT-08, MOB-06)
#   I3 no .swipeActions: row actions go into sbContextMenu (MOB-06)
#   I4 no Image(systemName: and no SF Symbols: icons are SbIcon from the sprite (ICO-01)
#   I5 no raw colours (Color(red:, Color(hue:, Color(white:, #colorLiteral, UIColor(red:, Color(.sRGB, hex
#      literals in Color(…)), no named system colours (Color.red, .blue …, Color(.system…), no .shadow( (FAR-01, EBE-02)
#   I6 the lime colour roles stay inside the package: no sbPrimaryAction… colour read, no .borderedProminent (AKT-01)
#   I7 no upper limit on Dynamic Type: no .dynamicTypeSize(... or ..< on content (ZUG-09)
#   I8 no system fonts: no .font(.system, .font(.body/.title/…), Font.system(, UIFont.systemFont( (SCH-01)
#   S9 no pills or capsules: no Capsule(, .capsule, .clipShape(Circle()) on controls, cornerRadius 9999 / SebaroRadius.pill (FOR-01)
#   S10 no stock button styles: .borderedProminent, .bordered, .borderless (MOB-02)
#   S11 no tinted areas: no …Subtle colour roles, no .ultraThinMaterial / .regularMaterial / glassEffect (EBE-01)
#   S12 no hard-coded sizes in layout calls: a number literal other than 0 in .padding(, .frame(, spacing: (tokens only)
#   S13 every file that defines a …Screen view puts it on SbScreen (MOB-01)
# Not checked here, look at it in review: icon-only buttons without accessibilityLabel, the order of actions in a group,
# words written into code instead of Localizable.xcstrings (the tests' text check and review find those).

dir=${1:-$(cd "$(dirname "$0")/.." && pwd)/Musterapp}
if [ ! -d "$dir" ]; then
    echo "lint-sebaro-ios: no folder $dir" >&2
    exit 2
fi

found=0

# report <rule> <extended regex> [regex of lines that may match]
report() {
    rule=$1
    pattern=$2
    allowed=${3:-}
    hits=$(grep -rnE --include='*.swift' "$pattern" "$dir" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
    if [ -n "$allowed" ] && [ -n "$hits" ]; then
        hits=$(printf '%s\n' "$hits" | grep -vE "$allowed" || true)
    fi
    if [ -n "$hits" ]; then
        printf '%s\n' "$hits" | sed "s/^/$rule: /"
        found=1
    fi
}

report I1 '(^|[^A-Za-z0-9_])TabView([^A-Za-z0-9_]|$)|\.tabItem([^A-Za-z0-9_]|$)'
report I2 '\.(alert|confirmationDialog)[[:space:]]*\('
report I3 '\.swipeActions([[:space:]]*[({]|$)'
report I4 'Image\([[:space:]]*systemName:|systemImage:'
report I5 'Color\([[:space:]]*(red|hue|white|\.sRGB|\.displayP3|sbLight):|colorLiteral|UIColor\([[:space:]]*(red|white|hue):|Color\([[:space:]]*0[xX]|Color\.(red|blue|green|orange|yellow|pink|purple|gray|black|white|teal|indigo|mint|cyan|brown)([^A-Za-z0-9_]|$)|Color\([[:space:]]*\.system|\.shadow[[:space:]]*\('
report I6 '[sS]bPrimaryAction(Pressed|Hover|Outline)?([^A-Za-z0-9_(]|$)|\.onPrimaryAction([^A-Za-z0-9_]|$)|\.borderedProminent'
report I7 'dynamicTypeSize\([^)]*(\.\.\.|\.\.<)'
report I8 '\.font\([[:space:]]*\.(system|largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)([^A-Za-z0-9_]|$)|Font\.system[[:space:]]*\(|UIFont\.(systemFont|boldSystemFont|preferredFont)'
report S9 '(^|[^A-Za-z0-9_])Capsule[[:space:]]*\(|\.capsule([^A-Za-z0-9_]|$)|SebaroRadius\.pill|cornerRadius:?[[:space:]]*9999'
report S10 'buttonStyle\([[:space:]]*\.(bordered|borderless|borderedProminent)'
report S11 '(accent|success|warning|danger|info)Subtle|Material([^A-Za-z0-9_]|$)|\.(ultraThin|thin|regular|thick|ultraThick)Material|glassEffect'
report S12 '\.(padding|frame)\(([^)]*[^A-Za-z0-9_.])?[1-9][0-9]*(\.[0-9]+)?([^0-9A-Za-z_.]|$)|spacing:[[:space:]]*[1-9][0-9]*(\.[0-9]+)?([^0-9A-Za-z_.]|$)'

# S13: a file with "struct <Name>Screen: View" must use SbScreen( or SbFormSheet(
for file in $(grep -rlE --include='*.swift' 'struct [A-Z][A-Za-z0-9_]*Screen[[:space:]]*:[[:space:]]*View' "$dir"); do
    if ! grep -qE '(^|[^A-Za-z0-9_])(SbScreen|SbFormSheet)[[:space:]]*[({]' "$file"; then
        echo "S13: $file: defines a screen without SbScreen or SbFormSheet"
        found=1
    fi
done

if [ "$found" -eq 0 ]; then
    echo "lint-sebaro-ios: no findings in $dir"
fi
exit $found
