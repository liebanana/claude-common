#!/usr/bin/env bash
# meta: id=cron-discover kind=script group="Discover & adopt external agent tooling" status=ready tags=discovery,cron intent="Run the discovery loop unattended (discover → triage → rebuild index → open a PR)"
# cron-discover.sh — unattended discovery loop: discover -> triage -> rebuild index -> PR.
#
# Changes land on a branch and open a PULL REQUEST (never pushed straight to the default
# branch), so every automated run is reviewable before it merges.
#
# Wire into cron (weekly is plenty), e.g.:
#   0 9 * * 1 /home/luisliev/repos/claude-common/scripts/cron-discover.sh \
#     >> /home/luisliev/repos/claude-common/state/discover.log 2>&1
#
# Env:
#   AUTO_PUSH=1   push the branch and open a PR (needs origin + gh). If unset/0, the run
#                 commits to a local branch only (handy for testing) — never to default.
#   CRON_TIMEOUT_SEC  hard cap on the claude triage step (default 900)
#   TRIAGE_MODEL  model for the headless triage (default sonnet). Pinned on purpose:
#                 `claude -p` otherwise inherits the user's default model, which may be
#                 a premium tier — triage is structured judgment, Sonnet-grade work.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"
# cron's PATH is minimal; ensure the claude CLI and friends resolve.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
set -a; [ -f .env ] && . ./.env; set +a

echo "=== cron-discover $(date -u +%FT%TZ) ==="

n="$(bash scripts/discover.sh | tail -1)"
if [ "${n:-0}" -eq 0 ]; then
  echo "[cron-discover] no new candidates; nothing to do."
  exit 0
fi
echo "[cron-discover] $n new candidate(s); invoking triage."

# Headless, autonomous analysis. Permissions are NOT bypassed: the triage tools are
# pre-allowed by a scoped allowlist in .claude/settings.json (Read/Write/Edit + curl,
# the discover script, and the candidates cleanup). Anything outside that allowlist is
# auto-denied in headless mode, so a bad candidate README can't make this run arbitrary
# commands. git push stays out of the session — the wrapper does it below.
CRON_TIMEOUT="${CRON_TIMEOUT_SEC:-900}"
timeout --signal=TERM --kill-after=30 "$CRON_TIMEOUT" \
  claude -p "/triage-discoveries" --model "${TRIAGE_MODEL:-sonnet}" || {
    echo "[cron-discover] triage step failed/timed out (exit $?)."
  }

# Regenerate the index deterministically (don't rely on the LLM step having done it).
python3 scripts/build-index.py || echo "[cron-discover] build-index failed."

if [ -z "$(git status --porcelain)" ]; then
  echo "[cron-discover] triage produced no changes."
  echo "=== done $(date -u +%FT%TZ) ==="
  exit 0
fi

# Commit onto a fresh branch (carries the uncommitted triage changes), then open a PR.
base="$(git rev-parse --abbrev-ref HEAD)"
branch="discover/$(date -u +%Y%m%d-%H%M%S)"
git checkout -q -b "$branch"
git add -A
git commit -q -m "discover: triage candidates $(date -u +%F)" \
  -m "Automated by cron-discover.sh — review before merging." || true
echo "[cron-discover] committed on $branch (base: $base)."

if [ "${AUTO_PUSH:-0}" = "1" ] && git remote get-url origin >/dev/null 2>&1; then
  if git push -q -u origin "$branch"; then
    echo "[cron-discover] pushed $branch."
    if command -v gh >/dev/null 2>&1; then
      n_adopt="$(git diff "$base"..HEAD --stat -- research/ledger.jsonl | grep -c . || true)"
      body="Automated weekly discovery run by \`cron-discover.sh\`.

Review the new \`research/\` notes, \`research/ledger.jsonl\` entries, and the regenerated
\`index.json\` / \`CATALOG.md\` before merging."
      if pr_url="$(gh pr create --base "$base" --head "$branch" \
            --title "discover: weekly triage $(date -u +%F)" --body "$body" 2>&1)"; then
        echo "[cron-discover] PR opened: $pr_url"
      else
        echo "[cron-discover] gh pr create failed: $pr_url (branch is pushed; open a PR manually)."
      fi
    else
      echo "[cron-discover] gh not found; branch pushed — open a PR manually."
    fi
  else
    echo "[cron-discover] push failed; commit is local on $branch."
  fi
else
  echo "[cron-discover] AUTO_PUSH!=1 — left commit local on $branch (no push/PR)."
fi

# Return to the base branch so the next run starts clean.
git checkout -q "$base" 2>/dev/null || echo "[cron-discover] warning: could not return to $base."
echo "=== done $(date -u +%FT%TZ) ==="
