#!/usr/bin/env bash
# cron-discover.sh — unattended discovery loop: discover -> triage -> commit.
#
# Wire into cron (weekly is plenty), e.g.:
#   0 9 * * 1 /home/luisliev/repos/claude-common/scripts/cron-discover.sh \
#     >> /home/luisliev/repos/claude-common/state/discover.log 2>&1
#
# Env:
#   AUTO_PUSH=1   also `git push` after committing (default: commit only — safer)
#   CRON_TIMEOUT_SEC  hard cap on the claude triage step (default 900)
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

# Headless, autonomous analysis. --dangerously-skip-permissions is appropriate here:
# the run is unattended and scoped to writing this repo + read-only network fetches.
CRON_TIMEOUT="${CRON_TIMEOUT_SEC:-900}"
timeout --signal=TERM --kill-after=30 "$CRON_TIMEOUT" \
  claude -p "/triage-discoveries" --dangerously-skip-permissions || {
    echo "[cron-discover] triage step failed/timed out (exit $?)."
  }

if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "discover: triage candidates $(date -u +%F)" \
    -m "Automated by cron-discover.sh" || true
  echo "[cron-discover] committed."
  if [ "${AUTO_PUSH:-0}" = "1" ] && git remote get-url origin >/dev/null 2>&1; then
    git push -q && echo "[cron-discover] pushed."
  fi
else
  echo "[cron-discover] triage produced no changes."
fi
echo "=== done $(date -u +%FT%TZ) ==="
