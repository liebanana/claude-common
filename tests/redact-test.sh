#!/usr/bin/env bash
# Runs the redact.py unit tests (pure python, no pytest) and the CLI --check contract.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
python3 "$R/tests/test_redact.py" >/dev/null || _fail "python unit tests"
out=$(printf 'token ghp_%s end\n' "$(printf 'a%.0s' $(seq 1 24))" | python3 "$R/scripts/redact.py"); assert_eq "$out" "token [redacted] end" "cli redacts"
printf 'nothing here\n' | python3 "$R/scripts/redact.py" --check 2>/dev/null; assert_eq "$?" 0 "check clean exit 0"
printf 'API_KEY=abc123\n' | python3 "$R/scripts/redact.py" --check 2>/dev/null; assert_eq "$?" 1 "check dirty exit 1"
finish redact-test
