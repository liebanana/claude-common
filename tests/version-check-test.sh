#!/usr/bin/env bash
# Tests hooks/version-check.sh against a fake claude-common with tags and fake project dirs.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
H="$R/hooks/version-check.sh"
git init -q "$T/common" && git -C "$T/common" commit -q --allow-empty -m init \
  && git -C "$T/common" tag v1.0.0 && git -C "$T/common" tag v1.2.0 && git -C "$T/common" tag v1.10.0
mk() { mkdir -p "$T/$1/.claude"; printf '{"version":"%s","synced":"2026-01-01","managed":[]}' "$2" > "$T/$1/.claude/common.lock"; }
mk behind v1.2.0; mk current v1.10.0; mkdir -p "$T/nolock"

out=$(CLAUDE_COMMON_DIR="$T/common" CLAUDE_PROJECT_DIR="$T/behind"  bash "$H"); rc=$?
assert_eq "$rc" 0 "exit 0 behind"; assert_eq "$out" "claude-common: repo pinned v1.2.0, latest v1.10.0 — run scripts/sync-consumers.sh" "behind message"
out=$(CLAUDE_COMMON_DIR="$T/common" CLAUDE_PROJECT_DIR="$T/current" bash "$H"); assert_eq "$out" "" "silent when current"
out=$(CLAUDE_COMMON_DIR="$T/common" CLAUDE_PROJECT_DIR="$T/nolock"  bash "$H"); assert_eq "$out" "" "silent without lock"
out=$(CLAUDE_COMMON_DIR="$T/absent" CLAUDE_PROJECT_DIR="$T/behind"  bash "$H"); rc=$?; assert_eq "$rc" 0 "exit 0 no common"; assert_eq "$out" "" "silent without claude-common"
finish version-check-test
