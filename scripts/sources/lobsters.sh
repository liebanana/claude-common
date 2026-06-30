#!/usr/bin/env bash
# sources/lobsters.sh — emit Lobsters story candidates (tool links) as JSONL.
# Signals: score (users/reliability), comments, age_days. No auth needed.
# Env: LOBSTERS_TAGS (space/comma separated, default "ai").
set -euo pipefail
TAGS="${LOBSTERS_TAGS:-ai}"
now=$(date -u +%s)
for t in ${TAGS//,/ }; do
  curl -fsSL -H "User-Agent: claude-common-discover/1.0" "https://lobste.rs/t/$t.json" 2>/dev/null \
    | jq -c --argjson now "$now" '.[]? | select(.url != null and .url != "") | {
        source:"lobsters", key:.url, repo:null, title:.title, url:.url,
        signals:{score:.score, comments:.comment_count,
                 age_days:((try (($now - ((.created_at[0:19]+"Z")|fromdateiso8601))/86400|floor) catch null))},
        context_url:.comments_url
      }' || echo "[lobsters] tag failed: $t" >&2
  sleep 1
done
