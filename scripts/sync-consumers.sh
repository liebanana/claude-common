#!/usr/bin/env bash
# meta: id=sync-consumers kind=script group="Index & navigation" status=ready tags=sync,release,pr,cron intent="Bring every consumer repo to the latest tagged claude-common release via one PR per repo (status/dry-run/discover modes)"
# sync-consumers.sh — pin every consumer repo to a claude-common release. One PR per repo. Never
# touches a default branch or the user's working tree (works in a temp git worktree per repo).
#
#   scripts/sync-consumers.sh                 # sync all consumers behind the newest v* tag (local branch only)
#   AUTO_PUSH=1 scripts/sync-consumers.sh     # …and push + open/refresh a PR per repo (or --push)
#   scripts/sync-consumers.sh --status        # table: repo · pinned · latest · state (current/behind/
#                                              #   pr-open #N/unmanaged/no-remote/branch-local/worktree/
#                                              #   skip/self/missing/no-default-branch)
#   scripts/sync-consumers.sh --dry-run       # show what would change, commit nothing
#   scripts/sync-consumers.sh --discover      # git repos under root that are in neither consumers nor exclude
#   scripts/sync-consumers.sh --repo X [--repo Y] [--version vX.Y.Z] [--root DIR] [--manifest FILE]
# Env: AUTO_PUSH, GH_BIN (default gh), SYNC_SCRATCH (default <common>/state/sync-wt), CLAUDE_COMMON_DIR.
# Exit 1 if any consumer failed (others still processed). Spec: docs/superpowers/specs/2026-09-14-consumer-sync-design.md §4
set -uo pipefail
COMMON="${CLAUDE_COMMON_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
. "$COMMON/scripts/lib/sync-apply.sh"

MANIFEST="$COMMON/sync/consumers.json"; MODE=sync; DRY=0; PUSH="${AUTO_PUSH:-0}"; VERSION=""; ROOT_OVERRIDE=""
declare -a ONLY=()
while [ $# -gt 0 ]; do
  case "$1" in
    --status) MODE=status ;; --discover) MODE=discover ;; --dry-run) DRY=1 ;; --push) PUSH=1 ;;
    --repo) [ $# -ge 2 ] || { echo "$1 needs a value" >&2; exit 2; }; ONLY+=("$2"); shift ;;
    --version) [ $# -ge 2 ] || { echo "$1 needs a value" >&2; exit 2; }; VERSION="$2"; shift ;;
    --root) [ $# -ge 2 ] || { echo "$1 needs a value" >&2; exit 2; }; ROOT_OVERRIDE="$2"; shift ;;
    --manifest) [ $# -ge 2 ] || { echo "$1 needs a value" >&2; exit 2; }; MANIFEST="$2"; shift ;;
    -h|--help) sed -n '3,14p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done
GH="${GH_BIN:-gh}"; SCRATCH="${SYNC_SCRATCH:-$COMMON/state/sync-wt}"
log() { echo "[sync] $*"; }

[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 2; }
ROOT="${ROOT_OVERRIDE:-$(jq -r .root "$MANIFEST")}"; ROOT="${ROOT/#\~/$HOME}"
[ -d "$ROOT" ] || { echo "root not found: $ROOT" >&2; exit 2; }
LATEST="$(git -C "$COMMON" tag -l 'v*' --sort=-v:refname | head -n1)"
TARGET="${VERSION:-$LATEST}"

is_worktree() { local g c; g="$(git -C "$1" rev-parse --git-dir 2>/dev/null)" || return 1; c="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)"; [ "$(cd "$1" && realpath "$g")" != "$(cd "$1" && realpath "$c")" ]; }
default_branch() { local d; d="$(git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"; [ -n "$d" ] && { echo "${d#origin/}"; return; }
  git -C "$1" show-ref -q --verify refs/heads/main && { echo main; return; }; git -C "$1" show-ref -q --verify refs/heads/master && { echo master; return; }; return 1; }
has_remote() { git -C "$1" remote get-url origin >/dev/null 2>&1; }
pinned_of() { local ref="$1" dir="$2"; git -C "$dir" show "$ref:.claude/common.lock" 2>/dev/null | jq -r '.version // empty' 2>/dev/null; }
pr_number() { has_remote "$1" || return 0; command -v "$GH" >/dev/null 2>&1 || return 0; (cd "$1" && "$GH" pr list --head "$2" --state open --json number -q '.[0].number' 2>/dev/null) || true; }
changelog_delta() { awk -v v="$TARGET" '$0 ~ "^## \\["v"\\]" {p=1; next} p && /^## \[/ {exit} p' "$EXPORT/CHANGELOG.md" 2>/dev/null; }

# ---------- discover
if [ "$MODE" = discover ]; then
  for d in "$ROOT"/*/; do d="${d%/}"; n="$(basename "$d")"
    [ -d "$d/.git" ] || continue                                  # real repos only (worktrees have a .git file)
    jq -e --arg n "$n" '(.exclude|index($n)) or ([.consumers[].repo]|index($n))' "$MANIFEST" >/dev/null && continue
    echo "$n"; done; exit 0
fi

# ---------- export the tag once
EXPORT=""
if [ "$MODE" = sync ]; then
  [ -n "$TARGET" ] || { echo "no v* tag in $COMMON — run scripts/release.sh first" >&2; exit 2; }
  git -C "$COMMON" rev-parse -q --verify "refs/tags/$TARGET" >/dev/null || { echo "tag not found: $TARGET" >&2; exit 2; }
  EXPORT="$(mktemp -d)"; trap 'rm -rf "$EXPORT"' EXIT
  git -C "$COMMON" archive "$TARGET" | tar -xf - -C "$EXPORT"
fi

# ---------- per-repo
[ "$MODE" = status ] && printf '%-28s %-10s %-10s %s\n' REPO PINNED LATEST STATE
FAILED=0
while IFS=$'\t' read -r repo mode; do
  if [ ${#ONLY[@]} -gt 0 ]; then printf '%s\n' "${ONLY[@]}" | grep -qxF "$repo" || continue; fi
  dir="$ROOT/$repo"; branch="common/$TARGET"
  if [ "$MODE" = status ]; then
    state=""; pinned="-"
    if   [ "$mode" = skip ]; then state=skip
    elif [ "$mode" = self ]; then pinned="$(jq -r '.version // "-"' "$COMMON/.claude/common.lock" 2>/dev/null || echo -)"; state=self
    elif [ ! -d "$dir" ]; then state=missing
    elif is_worktree "$dir"; then state=worktree
    else
      db="$(default_branch "$dir")" || { state=no-default-branch; }
      [ -z "$state" ] && { pinned="$(pinned_of "$db" "$dir")"; pinned="${pinned:--}"
        if [ "$pinned" = "$LATEST" ]; then state=current
        elif n="$(pr_number "$dir" "$branch")" && [ -n "$n" ]; then state="pr-open #$n"
        elif git -C "$dir" show-ref -q --verify "refs/heads/$branch"; then state="$( has_remote "$dir" && echo branch-local || echo no-remote )"
        elif [ "$pinned" = "-" ]; then state=unmanaged; else state=behind; fi; }
    fi
    printf '%-28s %-10s %-10s %s\n' "$repo" "$pinned" "${LATEST:--}" "$state"; continue
  fi

  # ----- sync mode
  [ "$mode" = skip ] && { log "$repo: skip (manifest)"; continue; }
  [ "$mode" = self ] && { log "$repo: self (written by release.sh)"; continue; }
  [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || { log "$repo: missing at $dir"; FAILED=1; continue; }
  is_worktree "$dir" && { log "$repo: skip (worktree)"; continue; }
  db="$(default_branch "$dir")" || { log "$repo: no default branch"; FAILED=1; continue; }
  remote=0; has_remote "$dir" && remote=1
  base="$db"
  if [ $remote = 1 ]; then git -C "$dir" fetch -q origin "$db" 2>/dev/null && base="origin/$db" || log "$repo: fetch failed, using local $db"; fi
  if [ ${#ONLY[@]} -eq 0 ] && [ "$(pinned_of "$base" "$dir")" = "$TARGET" ]; then log "$repo: current ($TARGET)"; continue; fi

  wt="$SCRATCH/$repo"; mkdir -p "$SCRATCH"; git -C "$dir" worktree remove -f "$wt" 2>/dev/null; rm -rf "$wt"
  prev="$(git -C "$dir" rev-parse -q --verify "refs/heads/$branch" 2>/dev/null || true)"
  if [ $DRY = 1 ]; then
    git -C "$dir" worktree add -q --detach "$wt" "$base" || { log "$repo: worktree add failed"; FAILED=1; continue; }
  else
    git -C "$dir" worktree add -q -B "$branch" "$wt" "$base" 2>/dev/null \
      || { log "$repo: cannot create branch $branch (checked out elsewhere?)"; FAILED=1; continue; }
  fi
  if ! apply_contract "$EXPORT" "$wt" "$TARGET" "$repo"; then log "$repo: apply failed"; git -C "$dir" worktree remove -f "$wt"; FAILED=1; continue; fi
  if ! ( cd "$wt" && git add -A ); then log "$repo: git add failed"; git -C "$dir" worktree remove -f "$wt"; FAILED=1; continue; fi
  if ( cd "$wt" && git diff --cached --quiet ); then
    log "$repo: up-to-date (no changes)"; git -C "$dir" worktree remove -f "$wt"; continue
  fi
  if [ $DRY = 1 ]; then
    log "$repo: would change:"; ( cd "$wt" && git diff --cached --stat | sed 's/^/    /' ); git -C "$dir" worktree remove -f "$wt"; continue
  fi
  if ! ( cd "$wt" && git commit -q -m "chore: sync claude-common $TARGET

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" ); then
    log "$repo: commit failed"; git -C "$dir" worktree remove -f "$wt"; FAILED=1; continue
  fi
  if [ -n "$prev" ] && ( cd "$wt" && git diff --quiet "$prev" HEAD ); then
    ( cd "$wt" && git reset -q --hard "$prev" )       # identical content: keep old sha, no re-push
    n="$(pr_number "$dir" "$branch")"; log "$repo: ${n:+pr-open #$n }(unchanged)"; git -C "$dir" worktree remove -f "$wt"; continue
  fi
  if [ $remote = 0 ]; then log "$repo: no remote — branch $branch left local"; git -C "$dir" worktree remove -f "$wt"; continue; fi
  if [ "$PUSH" != 1 ]; then log "$repo: branch $branch committed locally (AUTO_PUSH!=1, no push/PR)"; git -C "$dir" worktree remove -f "$wt"; continue; fi
  git -C "$wt" fetch -q origin "$branch" 2>/dev/null || true
  if ! ( cd "$wt" && git push -q --force-with-lease -u origin "$branch" ); then log "$repo: push failed"; git -C "$dir" worktree remove -f "$wt"; FAILED=1; continue; fi
  body="Pin claude-common to **$TARGET** (managed files only; repo-local rules untouched).

Changed:
$(cd "$wt" && git diff --name-only "$base" HEAD | sed 's/^/- /')

Changelog $TARGET:
$(changelog_delta)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
  if command -v "$GH" >/dev/null 2>&1; then
    n="$(pr_number "$dir" "$branch")"
    if [ -n "$n" ]; then (cd "$wt" && "$GH" pr edit "$n" --body "$body" >/dev/null) && log "$repo: PR #$n refreshed" || log "$repo: pr edit failed (branch pushed)"
    else url="$(cd "$wt" && "$GH" pr create --base "$db" --head "$branch" --title "chore: sync claude-common $TARGET" --body "$body" 2>&1)" \
         && log "$repo: PR $url" || { log "$repo: gh pr create failed: $url (branch pushed; open manually)"; FAILED=1; }
    fi
  else log "$repo: gh not found; branch pushed — open a PR manually"; fi
  git -C "$dir" worktree remove -f "$wt"
done < <(jq -r '.consumers[] | [.repo, .mode] | @tsv' "$MANIFEST")
exit $FAILED
