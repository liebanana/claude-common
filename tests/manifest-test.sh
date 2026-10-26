#!/usr/bin/env bash
# Validates the consumer registry schema: always sync/consumers.example.json (tracked); also the
# host's gitignored sync/consumers.local.json when present, plus that its repos exist under root.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_REPO="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
check_manifest() {  # $1 = file, $2 = 1 to require the repos on this host
  local M="$1" root r
  assert_file "$M"
  jq -e '.root and (.exclude|type=="array") and (.consumers|type=="array")' "$M" >/dev/null || _fail "schema: $M"
  jq -e '[.consumers[].mode] | all(. as $m | ["pr","skip","self"] | index($m))' "$M" >/dev/null || _fail "bad mode: $M"
  jq -e '[.consumers[].repo] | length == (unique|length)' "$M" >/dev/null || _fail "duplicate repo: $M"
  jq -e '[.consumers[] | select(.mode=="self")] | length == 1' "$M" >/dev/null || _fail "exactly one self: $M"
  [ "$2" = 1 ] || return 0
  root="$(jq -r .root "$M")"; root="${root/#\~/$HOME}"
  while read -r r; do [ -d "$root/$r/.git" ] || _fail "consumer dir missing: $root/$r"; done < <(jq -r '.consumers[].repo' "$M")
}
check_manifest "$ROOT_REPO/sync/consumers.example.json" 0
LOCAL="${CLAUDE_COMMON_MANIFEST:-$ROOT_REPO/sync/consumers.local.json}"
[ -f "$LOCAL" ] && check_manifest "$LOCAL" 1
git -C "$ROOT_REPO" ls-files --error-unmatch sync/consumers.local.json >/dev/null 2>&1 && _fail "consumers.local.json must not be tracked"
assert_file "$ROOT_REPO/templates/settings.baseline.json"
jq -e '.permissions.deny | index("Read(./.env)")' "$ROOT_REPO/templates/settings.baseline.json" >/dev/null || _fail "baseline deny"
jq -e '.hooks.SessionStart[0].hooks[0].command | test("version-check")' "$ROOT_REPO/templates/settings.baseline.json" >/dev/null || _fail "baseline hook"
assert_grep '^<!-- claude-common:begin -->$' "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^<!-- claude-common:end -->$'   "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^@AGENT-DIRECTIVE\.md$'          "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '\{\{VERSION\}\}'                  "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^## \[Unreleased\]'               "$ROOT_REPO/CHANGELOG.md"
finish manifest-test
