#!/bin/sh
# run-tests.sh [simulator id]
#
# Builds the app and runs every test (MusterappTests: screenshots with the text check, the text check's own fixtures,
# behaviour) on an iOS simulator, then reads the result bundle. Without an id it takes an iPhone 17 or 16 of
# the newest iOS runtime that has one. Writes into build/test/ (git-ignored): xcodebuild.log, Tests.xcresult and shots/ with every
# screenshot (look at them before you call a screen done).
#
# xcodebuild sometimes does not exit after the tests have finished (sebaroDesign TOOLS §2.20, seen with Xcode 27). The
# script watches the log: once it shows the completed run (the last „Test Suite 'All tests' passed/failed“ line with
# its „Executed N tests“), xcodebuild gets SB_TEST_GRACE seconds (default 120) to exit, then it is stopped, and only
# this case is judged as a run (by the result bundle, or by the log when the bundle was not written yet). A run that
# hangs before that line (SB_TEST_TIMEOUT seconds, default 3600) is stopped and fails, whatever the log says so far.
#
# Exit 0 only when every test ran and passed: a failed, skipped or missing test, a crashed or restarted test host, an
# infrastructure failure, a result bundle that does not say „Passed“ or a timeout fail the script (exit 1); see
# tools/test-result.py. Before the run it checks that judge against its regression cases
# (tools/test-result-fixtures/check.sh --parser-only). SB_XCODEBUILD replaces the xcodebuild command (that check's
# runner cases use it with a stand-in that hangs, and SB_TEST_OUT for another output folder).

set -u
here=$(cd "$(dirname "$0")/.." && pwd)
out=${SB_TEST_OUT:-$here/build/test}
mkdir -p "$out"
rm -rf "$out/Tests.xcresult" "$out/shots"

device=${1:-$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return (int(m.group(1)), int(m.group(2))) if m else (0, 0)
for runtime in sorted(devices, key=version, reverse=True):
    if version(runtime) == (0, 0):
        continue
    # only phones whose screen holds the 393 and 320 pt looks without a side safe area (sebaroDesign CHECKS.md §42)
    phones = [d for d in devices[runtime] if d["name"] in ("iPhone 17", "iPhone 16")]
    if phones:
        print(phones[0]["udid"])
        break
')}
if [ -z "$device" ]; then
    echo "run-tests: no iPhone simulator available" >&2
    exit 1
fi
echo "run-tests: simulator $device"

"$here/tools/test-result-fixtures/check.sh" --parser-only || exit 1

# the completed run: the suite's end line, then its count on the next line
completed() {
    grep -A1 -E "^Test Suite 'All tests' (passed|failed) at" "$out/xcodebuild.log" | grep -qE "Executed [0-9]+ tests?, with"
}

TEST_RUNNER_SB_SHOTS="$out/shots" ${SB_XCODEBUILD:-xcodebuild} test -project "$here/Musterapp.xcodeproj" \
    -scheme Musterapp -destination "id=$device" -derivedDataPath "$out/dd" -resultBundlePath "$out/Tests.xcresult" \
    CODE_SIGNING_ALLOWED=NO > "$out/xcodebuild.log" 2>&1 &
pid=$!
waited=0
ended=-1
stopped=no
limit=${SB_TEST_TIMEOUT:-3600}
grace=${SB_TEST_GRACE:-120}
while kill -0 "$pid" 2>/dev/null; do
    sleep 5
    waited=$((waited + 5))
    if [ "$ended" -lt 0 ] && completed; then
        ended=$waited
    fi
    if [ "$ended" -ge 0 ] && [ $((waited - ended)) -ge "$grace" ]; then
        echo "run-tests: the test run completed, but xcodebuild did not exit within ${grace}s after it; stopping it"
        stopped=after-run
    elif [ "$ended" -lt 0 ] && [ "$waited" -ge "$limit" ]; then
        echo "run-tests: FAIL timeout: no completed test run after ${waited}s (SB_TEST_TIMEOUT=$limit); stopping xcodebuild"
        stopped=timeout
    fi
    if [ "$stopped" != no ]; then
        kill "$pid" 2>/dev/null
        sleep 5
        kill -9 "$pid" 2>/dev/null
        break
    fi
done
wait "$pid" 2>/dev/null
status=$?
echo "run-tests: xcodebuild ended (exit status $status), log in $out/xcodebuild.log"
grep -E "\.swift:[0-9]+: error:|^Test Case .* failed|BUILD FAILED|TEST FAILED" "$out/xcodebuild.log" | cut -c1-2000 | head -40
case $stopped in
    timeout)
        python3 "$here/tools/test-result.py" "$out/Tests.xcresult" "$out/xcodebuild.log" --exit-status "$status"
        echo "run-tests: FAIL the run timed out before it completed"
        exit 1 ;;
    after-run)
        python3 "$here/tools/test-result.py" "$out/Tests.xcresult" "$out/xcodebuild.log" --stopped-after-run ;;
    *)
        python3 "$here/tools/test-result.py" "$out/Tests.xcresult" "$out/xcodebuild.log" --exit-status "$status" ;;
esac
