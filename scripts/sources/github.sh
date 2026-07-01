#!/usr/bin/env bash
# sources/github.sh — emit GitHub repo candidates as normalized JSONL to stdout.
# Signals: stars (reliability/size), pushed (recency), repo_age_days (maturity).
# Env: MIN_STARS (80), PER_PAGE (30), PUSHED_SINCE (18mo ago), QUERIES, GITHUB_TOKEN.
set -euo pipefail
MIN_STARS="${MIN_STARS:-80}"
PER_PAGE="${PER_PAGE:-30}"
PUSHED_SINCE="${PUSHED_SINCE:-$(date -u -d '18 months ago' +%Y-%m-%d 2>/dev/null || date -u -v-18m +%Y-%m-%d)}"
DEFAULT_QUERIES='topic:claude-code
topic:claude-plugin
topic:mcp-server
topic:model-context-protocol
topic:ai-agents
topic:agentic
topic:llm-agent
claude code subagents in:name,description,readme'
QUERIES="${QUERIES:-$DEFAULT_QUERIES}"
AUTH=(); [ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
now=$(date -u +%s)
while IFS= read -r q; do
  [ -z "$q" ] && continue
  fq="$q stars:>=$MIN_STARS pushed:>=$PUSHED_SINCE"
  url="https://api.github.com/search/repositories?per_page=$PER_PAGE&sort=stars&order=desc&q=$(jq -rn --arg s "$fq" '$s|@uri')"
  curl -fsSL "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$url" 2>/dev/null \
    | jq -c --argjson now "$now" '.items[]? | {
        source:"github", key:.full_name, repo:.full_name,
        title:(.description // ""), url:.html_url,
        signals:{stars:.stargazers_count, pushed:(.pushed_at[0:10]),
                 repo_age_days:((try (($now - (.created_at|fromdateiso8601))/86400|floor) catch null))}
      }' || echo "[github] query failed (rate limit?): $q" >&2
  sleep 7   # stay under the unauthenticated search ceiling
done <<< "$QUERIES"
