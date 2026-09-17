#!/usr/bin/env bash
# meta: id=release kind=script group="Index & navigation" status=ready tags=release,tag,changelog intent="Cut a tagged claude-common release: rotate CHANGELOG, write self lock + CLAUDE.md block, rebuild index, tag vX.Y.Z, push"
# release.sh — cut a release of claude-common.
#   scripts/release.sh <major|minor|patch> [-m "note"] [--dry-run]
# Refuses unless on main, clean, and not behind origin/main. First release is always v1.0.0.
# Steps: CHANGELOG [Unreleased] -> [vX.Y.Z] - date; self lock + CLAUDE.md block; build-index;
#        commit "release: vX.Y.Z"; annotated tag; push main + tag (RELEASE_NO_PUSH=1 to skip).
set -uo pipefail
COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$COMMON" || exit 1
. scripts/lib/sync-apply.sh
BUMP="${1:-}"; shift || true; NOTE=""; DRY=0
while [ $# -gt 0 ]; do case "$1" in -m) NOTE="$2"; shift ;; --dry-run) DRY=1 ;; *) echo "unknown arg: $1" >&2; exit 2 ;; esac; shift; done
case "$BUMP" in major|minor|patch) ;; *) echo "usage: release.sh <major|minor|patch> [-m note] [--dry-run]" >&2; exit 2 ;; esac

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "release.sh: not on main" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "release.sh: working tree dirty" >&2; exit 1; }
if git remote get-url origin >/dev/null 2>&1; then
  git fetch -q origin main 2>/dev/null || true
  if git rev-parse -q --verify origin/main >/dev/null && [ "$(git rev-list --count HEAD..origin/main)" != 0 ]; then
    echo "release.sh: main is behind origin/main — pull first" >&2; exit 1; fi
fi

latest="$(git tag -l 'v*' --sort=-v:refname | head -n1)"
if [ -n "$latest" ] && ! [[ "$latest" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "release.sh: latest tag '$latest' is not vX.Y.Z" >&2; exit 1
fi
if [ -z "$latest" ]; then next=v1.0.0; else
  IFS=. read -r MA MI PA <<< "${latest#v}"
  case "$BUMP" in major) next="v$((MA+1)).0.0" ;; minor) next="v$MA.$((MI+1)).0" ;; patch) next="v$MA.$MI.$((PA+1))" ;; esac
fi
echo "release.sh: $latest -> $next"
[ $DRY = 1 ] && { echo "(dry-run) would rotate CHANGELOG, write self lock/block, commit, tag $next"; exit 0; }

# CHANGELOG: [Unreleased] -> [next] - date, then a fresh empty [Unreleased]
tmp="$(mktemp)"
awk -v v="$next" -v d="$(date -u +%F)" -v note="$NOTE" '
  /^## \[Unreleased\]/ && !done { print "## [Unreleased]"; print ""; print "## [" v "] - " d; if (note != "") { print ""; print "- " note }; done=1; next } { print }' CHANGELOG.md > "$tmp" \
  || { rm -f "$tmp"; echo "release.sh: CHANGELOG rotation failed" >&2; exit 1; }
grep -q "^## \[$next\]" "$tmp" || { rm -f "$tmp"; echo "release.sh: CHANGELOG.md has no '## [Unreleased]' section" >&2; exit 1; }
mv "$tmp" CHANGELOG.md || { rm -f "$tmp"; echo "release.sh: CHANGELOG.md write failed" >&2; exit 1; }

apply_block "$COMMON" "$next" claude-common "$COMMON" || { echo "release.sh: apply_block failed" >&2; exit 1; }
# write_lock's internal pipeline includes `grep -v '^$'`, which exits 1 when MANAGED is empty
# (nothing left after filtering the blank line) even though it still writes a correct
# `managed: []` lock — under `pipefail` that nonzero would false-positive here since the self
# consumer always passes "". Run it with pipefail off so only a genuine write failure (surfaced
# by the pipeline's actual last command) aborts the release. See task-6-report.md Finding 1 fix.
( set +o pipefail; write_lock "$COMMON" "$next" "" ) || { echo "release.sh: write_lock failed" >&2; exit 1; }
python3 scripts/build-index.py >/dev/null || { echo "release.sh: build-index.py failed" >&2; exit 1; }

git add -A || { echo "release.sh: git add failed" >&2; exit 1; }
git commit -q -m "release: $next

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" || { echo "release.sh: git commit failed" >&2; exit 1; }
git tag -a "$next" -m "claude-common $next${NOTE:+ — $NOTE}"
if [ "${RELEASE_NO_PUSH:-0}" = 1 ]; then echo "release.sh: tagged $next (RELEASE_NO_PUSH=1, not pushed)"; exit 0; fi
if git remote get-url origin >/dev/null 2>&1; then git push -q origin main "$next" && echo "release.sh: pushed $next" || { echo "release.sh: push failed (tag exists locally)" >&2; exit 1; }
else echo "release.sh: no origin; tagged $next locally"; fi
