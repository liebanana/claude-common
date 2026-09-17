#!/usr/bin/env bash
# Validates sync/consumers.json: schema, modes, every listed repo exists under root on this host.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_REPO="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
M="$ROOT_REPO/sync/consumers.json"
assert_file "$M"
jq -e '.root and (.exclude|type=="array") and (.consumers|type=="array")' "$M" >/dev/null || _fail "schema"
jq -e '[.consumers[].mode] | all(. as $m | ["pr","skip","self"] | index($m))' "$M" >/dev/null || _fail "bad mode"
jq -e '[.consumers[].repo] | length == (unique|length)' "$M" >/dev/null || _fail "duplicate repo"
jq -e '[.consumers[] | select(.mode=="self")] | length == 1' "$M" >/dev/null || _fail "exactly one self"
root="$(jq -r .root "$M")"; root="${root/#\~/$HOME}"
while read -r r; do [ -d "$root/$r/.git" ] || _fail "consumer dir missing: $root/$r"; done < <(jq -r '.consumers[].repo' "$M")
assert_file "$ROOT_REPO/templates/settings.baseline.json"
jq -e '.permissions.deny | index("Read(./.env)")' "$ROOT_REPO/templates/settings.baseline.json" >/dev/null || _fail "baseline deny"
jq -e '.hooks.SessionStart[0].hooks[0].command | test("version-check")' "$ROOT_REPO/templates/settings.baseline.json" >/dev/null || _fail "baseline hook"
assert_grep '^<!-- claude-common:begin -->$' "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^<!-- claude-common:end -->$'   "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^@AGENT-DIRECTIVE\.md$'          "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '\{\{VERSION\}\}'                  "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^## \[Unreleased\]'               "$ROOT_REPO/CHANGELOG.md"
finish manifest-test
