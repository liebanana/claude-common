#!/usr/bin/env bash
# artifact-smoke skill: test-page-check selftest, hook contract (skip / block paths need no browser),
# and the headless smoke itself when Playwright is resolvable (PLAYWRIGHT_MODULE or node_modules).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
S="$R/skills/artifact-smoke"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
python3 "$S/test-page-check.py" --selftest >/dev/null || _fail "test-page-check selftest"
hook() { printf '%s' "$1" | bash "$S/hook.sh" 2>"$T/err"; echo $?; }
assert_eq "$(hook '{"tool_input":{"file_path":"x.md"}}')" 0 "hook ignores non-html"
printf '<p>hi</p>' > "$T/p.html"
assert_eq "$(hook "{\"tool_input\":{\"action\":\"read\",\"file_path\":\"$T/p.html\"}}")" 0 "hook ignores non-publish"
assert_eq "$(hook "{\"tool_input\":{\"asset\":true,\"file_path\":\"$T/p.html\"}}")" 0 "hook ignores asset uploads"
printf '<h2>What to test</h2><ol><li>Tap Start</li></ol>' > "$T/bad.html"
assert_eq "$(hook "{\"tool_input\":{\"file_path\":\"$T/bad.html\"}}")" 2 "hook blocks a test page without verdicts"
assert_grep 'data-human-test' "$T/err"
if PLAYWRIGHT_MODULE="${PLAYWRIGHT_MODULE:-}" node -e 'try{require(process.env.PLAYWRIGHT_MODULE||"playwright")}catch(e){process.exit(1)}' 2>/dev/null; then
  timeout 120 node "$S/smoke.cjs" --selftest >/dev/null || _fail "smoke selftest (bad page must go RED)"
  timeout 120 node "$S/smoke.cjs" "$T/p.html" --expect p >/dev/null || _fail "smoke passes a good page"
else
  echo "  SKIP: playwright not resolvable — smoke.cjs browser cases not run (set PLAYWRIGHT_MODULE)"
fi
finish artifact-smoke-test
