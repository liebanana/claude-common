#!/usr/bin/env bash
# defect-class-loop gate-check.py: selftest + CLI exit-code contract on a fixture registry.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
G="$R/skills/defect-class-loop/gate-check.py"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
python3 "$G" --selftest >/dev/null || _fail "selftest"
mkdir -p "$T/repo/tests" && touch "$T/repo/tests/a.test.sh"
printf '## A — x\n- **Gate:** self:tests/a.test.sh\n## B — y\n- **Gate:** PENDING ROW-1\n' > "$T/reg.md"
echo ROW-1 > "$T/open.txt"
python3 "$G" --registry "$T/reg.md" --repo self="$T/repo" --open-ids "$T/open.txt" >/dev/null; assert_eq "$?" 0 "green registry"
printf '## C — z\nno gate line\n' >> "$T/reg.md"
python3 "$G" --registry "$T/reg.md" --repo self="$T/repo" --open-ids "$T/open.txt" >/dev/null; assert_eq "$?" 1 "class without a gate is RED"
echo C > "$T/base.txt"
python3 "$G" --registry "$T/reg.md" --repo self="$T/repo" --open-ids "$T/open.txt" --baseline "$T/base.txt" >/dev/null; assert_eq "$?" 0 "baseline debt is reported, not failed"
: > "$T/open.txt"
python3 "$G" --registry "$T/reg.md" --repo self="$T/repo" --open-ids "$T/open.txt" --baseline "$T/base.txt" >/dev/null; assert_eq "$?" 1 "PENDING on a closed item is RED"
python3 "$G" --registry "$T/missing.md" >/dev/null 2>&1; assert_eq "$?" 2 "unreadable registry fails closed"
finish defect-class-gate-test
