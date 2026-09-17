#!/usr/bin/env bash
# meta: id=version-check kind=hook group="Reusable Claude Code assets" status=ready tags=hook,session-start,sync intent="SessionStart hook: warn when the repo's pinned claude-common version is behind the newest local tag"
# version-check.sh — shipped to every consumer as .claude/hooks/common/version-check.sh (SessionStart).
# Reads .claude/common.lock, compares to the newest v* tag in $CLAUDE_COMMON_DIR (default
# ~/repos/claude-common). Local git only, no network. Prints one line when behind, else nothing.
# Always exits 0 so a broken host never blocks a session.
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
common="${CLAUDE_COMMON_DIR:-$HOME/repos/claude-common}"
lock="$proj/.claude/common.lock"
[ -f "$lock" ] && [ -d "$common/.git" ] || exit 0
pinned="$(jq -r '.version // empty' "$lock" 2>/dev/null)" || exit 0
latest="$(git -C "$common" tag -l 'v*' --sort=-v:refname 2>/dev/null | head -n1)"
[ -n "$pinned" ] && [ -n "$latest" ] || exit 0
[ "$pinned" = "$latest" ] && exit 0
echo "claude-common: repo pinned $pinned, latest $latest — run scripts/sync-consumers.sh"
exit 0
