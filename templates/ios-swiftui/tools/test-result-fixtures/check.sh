#!/bin/sh
# check.sh [--parser-only]
#
# Regression cases of the test judge. Parser cases (cases.txt): each folder holds an xcodebuild.log and, where the run
# wrote one, the bundle's summary.json; tools/test-result.py must end with the expected exit and print the named line,
# so a case that fails for another reason than the one it stands for fails too. Runner cases (not with
# --parser-only): tools/run-tests.sh with fake-xcodebuild.sh in place of xcodebuild, writing into a temporary folder:
# a run that hangs after its completed, passing end is stopped and passes; a run that hangs before its end fails as a
# timeout; a run whose xcodebuild exits with an error fails. run-tests.sh runs the parser cases before every run; CI runs
# all. Exit 0: every case as expected. Exit 1: a case is named with its output.

set -u
dir=$(cd "$(dirname "$0")" && pwd)
tools=$(dirname "$dir")
failed=0

while IFS='|' read -r name expect arguments line what; do
    name=$(echo "$name" | xargs); expect=$(echo "$expect" | xargs); arguments=$(echo "$arguments" | xargs)
    line=$(echo "$line" | sed 's/^ *//; s/ *$//')
    summary=
    [ -f "$dir/$name/summary.json" ] && summary="--summary-json $dir/$name/summary.json"
    # shellcheck disable=SC2086
    output=$(python3 "$tools/test-result.py" "$dir/$name/bundle" "$dir/$name/xcodebuild.log" $arguments $summary 2>&1)
    status=$?
    if [ "$status" -ne "$expect" ] || ! printf '%s\n' "$output" | grep -qF -- "$line"; then
        echo "test-result case $name: FAIL (exit $status, expected $expect and „${line}“): $what"
        printf '%s\n' "$output" | sed 's/^/    /'
        failed=1
    fi
done <<CASES
$(grep -v '^#' "$dir/cases.txt")
CASES
count=$(grep -vc '^#' "$dir/cases.txt")
if [ "$failed" -ne 0 ]; then
    echo "test-result-fixtures: FAIL in the parser cases"
    exit 1
fi
echo "test-result-fixtures: $count parser cases as expected"
[ "${1:-}" = --parser-only ] && exit 0

# runner cases: <name> <expected exit> <a line the output must contain> <log> <hang> <status>
runner() {
    work=$(mktemp -d)
    output=$(SB_XCODEBUILD="$dir/fake-xcodebuild.sh" SB_FAKE_LOG="$dir/$4/xcodebuild.log" SB_FAKE_HANG=$5 \
        SB_FAKE_STATUS=$6 SB_TEST_OUT="$work" SB_TEST_GRACE=5 SB_TEST_TIMEOUT=15 "$tools/run-tests.sh" fake 2>&1)
    status=$?
    rm -rf "$work"
    if [ "$status" -ne "$2" ] || ! printf '%s\n' "$output" | grep -qF -- "$3"; then
        echo "run-tests case $1: FAIL (exit $status, expected $2 and „${3}“)"
        printf '%s\n' "$output" | sed 's/^/    /'
        failed=1
    else
        echo "run-tests case $1: exit $status as expected"
    fi
}
runner hang-after-completed-run 0 "did not exit within 5s after it; stopping it" stopped-after-run yes 0
runner hang-before-the-end 1 "run-tests: FAIL the run timed out before it completed" incomplete-log yes 0
runner hang-after-a-failed-run 1 "says „failed“" failed yes 0
runner exits-with-an-error 1 "exit status 65" failed no 65
[ "$failed" -eq 0 ] && echo "test-result-fixtures: 4 runner cases as expected"
exit "$failed"
