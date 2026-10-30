#!/usr/bin/env python3
"""test-result.py <Tests.xcresult> <xcodebuild.log> [--exit-status N | --stopped-after-run] [--summary-json FILE]

Judges a test run. Exit 0 only when all of this holds, else 1 (every reason is printed):

- the log shows a complete run: its last „Test Suite 'All tests' …“ line says „passed“ and is followed by „Executed N
  tests, with 0 failures“, N > 0;
- the log shows no crash, restart or unexpected exit of the test host („Restarting after unexpected exit“, „crashed“,
  „Fatal error:“ …) and no infrastructure failure (the runner did not start, lost its connection, the simulator did
  not boot …); xcodebuild restarts a crashed host and its last summary then leaves the crashed test out;
- the result bundle (`xcrun xcresulttool get test-results summary`, Xcode 16 and later) says „Passed“, has a finish
  time, counts N tests as the log does, none failed, skipped or expected to fail;
- xcodebuild ended by itself with exit status 0 (`--exit-status 0`), or run-tests.sh stopped it after the log showed
  the completed run (`--stopped-after-run`, the known hang of Xcode 27, sebaroDesign TOOLS §2.20). Only then may the
  bundle be missing or half written (a folder without its Info.plist: xcodebuild had not finished it); the log alone
  decides. A bundle that can be read must pass in every case.

`--summary-json FILE` reads the bundle's summary from FILE instead of asking xcresulttool, for the regression cases in
tools/test-result-fixtures/ (`tools/test-result-fixtures/check.sh` runs them). Standard library only.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("bundle")
parser.add_argument("log")
how = parser.add_mutually_exclusive_group(required=True)
how.add_argument("--exit-status", type=int, help="xcodebuild's exit status, when it ended by itself")
how.add_argument("--stopped-after-run", action="store_true", help="run-tests.sh stopped xcodebuild after the run")
parser.add_argument("--summary-json", help="the bundle's summary as a file (fixtures)")
args = parser.parse_args()

problems = []
try:
    text = Path(args.log).read_text(encoding="utf-8", errors="replace")
except OSError as error:
    text = ""
    problems.append(f"no log: {error}")

# 1 the log shows a complete run
ends = list(re.finditer(r"^Test Suite 'All tests' (passed|failed) at .*\n\s*Executed (\d+) tests?, with (\d+) failures?",
                        text, re.M))
log_total = None
if not ends:
    problems.append("the log has no end of the test run („Test Suite 'All tests' passed/failed“ with its count): "
                    "the run did not complete")
else:
    last = ends[-1]
    log_total = int(last.group(2))
    if last.group(1) != "passed":
        problems.append(f"the log's last test suite line says „{last.group(1)}“")
    if int(last.group(3)) != 0:
        problems.append(f"the log counts {last.group(3)} failure(s)")
    if log_total == 0:
        problems.append("the log counts 0 tests")
    log_skipped = len(re.findall(r"^Test Case .* skipped", text, re.M))
    if log_skipped:
        problems.append(f"the log names {log_skipped} skipped test(s)")

# 2 no crash, restart or unexpected exit; no infrastructure failure
CRASH = [
    r"Restarting after unexpected exit",
    r"[Cc]rashed with signal",
    r"Test crashed",
    r"\bcrashed\b.*\b(test|runner|host)\b|\b(test|runner|host)\b.*\bcrashed\b",
    r"[Ee]arly unexpected exit",
    r"[Uu]nexpected exit",
    r"exited unexpectedly",
    r"Fatal error:",
    r"Precondition failed",
    r"Assertion failed:",
    r"terminating due to uncaught exception",
]
INFRASTRUCTURE = [
    r"Test runner exited before starting test execution",
    r"Test runner never began executing tests",
    r"[Ll]ost connection to (the )?test",
    r"Failed to (install|launch|load|start)",
    r"[Uu]nable to boot",
    r"The application failed to launch",
    r"[Tt]esting cancelled",
    r"Test operation failure",
    r"xcodebuild: error:",
    r"\*\* (BUILD|TEST EXECUTE|TEST BUILD) FAILED \*\*",
    r"\bTimed out\b.*\b(test|runner|simulator|device)\b",
]
for kind, patterns in (("a crash, restart or unexpected exit of the test host", CRASH),
                       ("an infrastructure failure", INFRASTRUCTURE)):
    hits = [line for line in text.splitlines() if any(re.search(pattern, line) for pattern in patterns)]
    if hits:
        problems.append(f"the log shows {kind} ({len(hits)} line(s)), first: {hits[0].strip()[:300]}")

# 3 the result bundle
summary = None
unreadable = False
if args.summary_json:
    try:
        summary = json.loads(Path(args.summary_json).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        summary = None
elif Path(args.bundle).exists():
    run = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", args.bundle,
                          "--compact"], capture_output=True, text=True)
    if run.returncode == 0:
        try:
            summary = json.loads(run.stdout)
        except ValueError:
            summary = None
    elif args.stopped_after_run:
        # stopped while it was writing the bundle: a folder without its Info.plist is a bundle not written yet
        print(f"test-result: the result bundle is not complete: {' '.join(run.stderr.split())[:300]}")
    else:
        unreadable = True
        problems.append(f"xcresulttool could not read the result bundle: {' '.join(run.stderr.split())[:300]}")
if summary is None:
    if args.stopped_after_run:
        print("test-result: no readable result bundle; xcodebuild was stopped after the completed run, the log decides")
    elif not unreadable:
        problems.append("no readable result bundle")
else:
    result = summary.get("result")
    passed, failed = summary.get("passedTests", 0), summary.get("failedTests", 0)
    skipped, expected = summary.get("skippedTests", 0), summary.get("expectedFailures", 0)
    total = summary.get("totalTestCount", passed + failed + skipped + expected)
    print(f"test-result: result bundle: {result}, {total} tests, {passed} passed, {failed} failed, {skipped} skipped, "
          f"{expected} expected failures")
    if result != "Passed":
        problems.append(f"the result bundle's result is „{result}“, not „Passed“")
    if not summary.get("finishTime"):
        problems.append("the result bundle has no finish time: the run is incomplete")
    if failed or skipped or expected:
        problems.append(f"the result bundle counts {failed} failed, {skipped} skipped, {expected} expected failures")
    if total == 0 or passed != total:
        problems.append(f"the result bundle has {passed} passed of {total} tests")
    if log_total is not None and total != log_total:
        problems.append(f"the result bundle counts {total} tests, the log {log_total}")

# 4 how xcodebuild ended
if args.exit_status is not None and args.exit_status != 0:
    problems.append(f"xcodebuild ended with exit status {args.exit_status}")

if log_total is not None:
    print(f"test-result: log: {log_total} tests in the completed run")
for line in problems:
    print(f"test-result: FAIL {line}")
print(f"test-result: {'failed' if problems else 'passed'}")
sys.exit(1 if problems else 0)
