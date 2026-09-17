#!/usr/bin/env bash
# Tests scripts/release.sh on a temp clone with a bare origin (no network).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
C="$T/common"; mkdir -p "$C"
( cd "$R" && git ls-files -co --exclude-standard | grep -v '^state/' | tar -cf - -T - ) | tar -xf - -C "$C"
git -C "$C" init -q -b main && git -C "$C" add -A && git -C "$C" commit -qm base
git init -q --bare "$T/origin.git"; git -C "$C" remote add origin "$T/origin.git"; git -C "$C" push -q -u origin main

# guard: dirty tree refuses
echo x > "$C/junk"; out=$(cd "$C" && bash scripts/release.sh patch 2>&1); assert_eq "$?" 1 "dirty refuses"; rm "$C/junk"
# guard: bad bump arg
out=$(cd "$C" && bash scripts/release.sh nope 2>&1); assert_eq "$?" 2 "bad arg rc"
# first release → v1.0.0 regardless of bump kind
out=$(cd "$C" && bash scripts/release.sh patch 2>&1); assert_eq "$?" 0 "release rc"
assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v1.0.0" "first tag"
assert_eq "$(git -C "$T/origin.git" tag -l v1.0.0)" "v1.0.0" "tag pushed"
assert_eq "$(git -C "$C" log -1 --format=%s)" "release: v1.0.0" "commit subject"
assert_grep "^## \[v1\.0\.0\] - $(date -u +%F)$" "$C/CHANGELOG.md"
assert_grep '^## \[Unreleased\]$' "$C/CHANGELOG.md"
assert_eq "$(jq -r .version "$C/.claude/common.lock")" "v1.0.0" "self lock"
assert_count '^@AGENT-DIRECTIVE\.md$' "$C/CLAUDE.md" 1
assert_grep 'claude-common v1\.0\.0' "$C/CLAUDE.md"
# second: minor → v1.1.0 ; then patch → v1.1.1 ; major → v2.0.0
( cd "$C" && bash scripts/release.sh minor >/dev/null 2>&1 ); assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v1.1.0" "minor"
( cd "$C" && bash scripts/release.sh patch >/dev/null 2>&1 ); assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v1.1.1" "patch"
( cd "$C" && bash scripts/release.sh major >/dev/null 2>&1 ); assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v2.0.0" "major"
# --dry-run: no commit, no tag
before=$(git -C "$C" rev-parse HEAD); ( cd "$C" && bash scripts/release.sh patch --dry-run >/dev/null 2>&1 )
assert_eq "$(git -C "$C" rev-parse HEAD)" "$before" "dry-run no commit"; assert_eq "$(git -C "$C" tag -l v2.0.1)" "" "dry-run no tag"
finish release-test
