#!/bin/sh
# A stand-in for xcodebuild in the runner cases of check.sh (run-tests.sh takes it from SB_XCODEBUILD): prints the log
# SB_FAKE_LOG, then hangs (SB_FAKE_HANG=yes) or exits with SB_FAKE_STATUS (default 0). Ignores its arguments.
cat "$SB_FAKE_LOG"
if [ "${SB_FAKE_HANG:-no}" = yes ]; then
    exec sleep 600
fi
exit "${SB_FAKE_STATUS:-0}"
