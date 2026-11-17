#!/usr/bin/env bash
# hook.sh — PreToolUse hook for the Artifact tool (artifact-smoke skill). On a page publish of a local
# .html file it (1) checks a human-test page gives every step a verdict + note (cheap, stdlib python),
# then (2) loads the page headless and blocks if its script throws. Exit 2 = block, reason on stderr.
# Wire it (settings.json): PreToolUse, matcher "Artifact",
#   command: bash "$CLAUDE_PROJECT_DIR/.claude/skills/artifact-smoke/hook.sh"
# Env: ARTIFACT_TEST_ASKS = regex for "this page asks for a test" in your language (see test-page-check.py).
# Fails closed: if playwright is missing the publish is blocked with the install hint.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
in=$(cat)
command -v jq >/dev/null 2>&1 || { echo "artifact-smoke hook: jq not found" >&2; exit 2; }
f=$(printf '%s' "$in" | jq -r '.tool_input.file_path // empty')
act=$(printf '%s' "$in" | jq -r '.tool_input.action // "publish"')
asset=$(printf '%s' "$in" | jq -r '.tool_input.asset // false')
[ "$act" = publish ] && [ "$asset" != true ] && [[ "$f" == *.html ]] && [ -f "$f" ] || exit 0
caps=$(printf '%s' "$in" | jq -c '.tool_input.capabilities // null')
args=("$f" --capabilities "$caps"); [ -n "${ARTIFACT_TEST_ASKS:-}" ] && args+=(--asks "$ARTIFACT_TEST_ASKS")
out=$(python3 "$here/test-page-check.py" "${args[@]}" 2>&1) || { echo "$out" >&2; exit 2; }
out=$(timeout 90 node "$here/smoke.cjs" "$f" 2>&1) || { echo "$out" >&2; exit 2; }
exit 0
