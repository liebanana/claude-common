#!/usr/bin/env bash
# sources/hackernews.sh — emit Hacker News story candidates (tool links) as JSONL.
# Signals: points (users/reliability), comments, seen_age_days (how old the story is —
# NOT the repo's age; the repo may be years older than its HN post). No auth (Algolia).
# Env: HN_MIN_POINTS (20), HN_QUERIES.
set -euo pipefail
HN_MIN_POINTS="${HN_MIN_POINTS:-20}"
DEFAULT_QUERIES='claude code
claude code skill
claude code plugin
mcp server
ai agent cli
context engineering'
QUERIES="${HN_QUERIES:-$DEFAULT_QUERIES}"
now=$(date -u +%s)
while IFS= read -r q; do
  [ -z "$q" ] && continue
  url="https://hn.algolia.com/api/v1/search?tags=story&hitsPerPage=30&query=$(jq -rn --arg s "$q" '$s|@uri')"
  curl -fsSL "$url" 2>/dev/null \
    | jq -c --argjson now "$now" --argjson min "$HN_MIN_POINTS" '.hits[]? | select(.url != null and .url != "" and (.points // 0) >= $min) | {
        source:"hackernews", key:.url, repo:null, title:.title, url:.url,
        signals:{points:.points, comments:.num_comments,
                 seen_age_days:(($now - .created_at_i)/86400|floor)},
        context_url:("https://news.ycombinator.com/item?id=" + .objectID)
      }' || echo "[hn] query failed: $q" >&2
  sleep 1
done <<< "$QUERIES"
