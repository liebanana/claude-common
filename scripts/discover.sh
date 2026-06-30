#!/usr/bin/env bash
# meta: id=discover kind=script group="Discover & adopt external agent tooling" status=ready tags=discovery,github intent="Find new GitHub agent/plugin/MCP repos (search + dedupe against the research ledger)"
# discover.sh — find new Claude Code / agent / MCP repos on GitHub.
#
# Uses the GitHub REST search API via curl + jq (no `gh` dependency). Works
# unauthenticated (10 search req/min limit — fine for a weekly run); set
# $GITHUB_TOKEN for higher limits and private-rate headroom.
#
# It does NOT analyze anything — it only produces a deduped list of NEW candidate
# repos for the /triage-discoveries command (or a human) to evaluate. Repos already
# in research/ledger.jsonl are skipped, so each candidate is surfaced exactly once.
#
# Output: research/_candidates.tsv  (full_name \t stars \t pushed_at \t url \t desc)
# Tunables (env):
#   MIN_STARS   minimum stars to consider          (default 80)
#   PUSHED_SINCE only repos pushed on/after this    (default: 18 months ago)
#   PER_PAGE    results per query                   (default 30)
#   QUERIES     newline-separated search qualifiers (default: the agent topics below)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEDGER="$REPO_DIR/research/ledger.jsonl"
OUT="$REPO_DIR/research/_candidates.tsv"

MIN_STARS="${MIN_STARS:-80}"
PER_PAGE="${PER_PAGE:-30}"
PUSHED_SINCE="${PUSHED_SINCE:-$(date -u -d '18 months ago' +%Y-%m-%d 2>/dev/null || date -u -v-18m +%Y-%m-%d)}"

# Each line is a GitHub search qualifier string. Tweak freely.
DEFAULT_QUERIES='topic:claude-code
topic:claude-plugin
topic:mcp-server
topic:model-context-protocol
topic:ai-agents
topic:agentic
topic:llm-agent
claude code subagents in:name,description,readme'
QUERIES="${QUERIES:-$DEFAULT_QUERIES}"

AUTH=()
[ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "[discover] min_stars=$MIN_STARS pushed>=$PUSHED_SINCE" >&2
while IFS= read -r q; do
  [ -z "$q" ] && continue
  full_q="$q stars:>=$MIN_STARS pushed:>=$PUSHED_SINCE"
  url="https://api.github.com/search/repositories?per_page=$PER_PAGE&sort=stars&order=desc&q=$(jq -rn --arg s "$full_q" '$s|@uri')"
  echo "[discover] query: $full_q" >&2
  curl -fsSL "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$url" 2>/dev/null \
    | jq -r '.items[]? | [.full_name, (.stargazers_count|tostring), .pushed_at, .html_url, ((.description // "")|gsub("[\t\n]";" "))] | @tsv' \
    >> "$tmp" || echo "[discover] query failed (rate limit?), continuing" >&2
  sleep 7   # stay under the unauthenticated 10 req/min search ceiling
done <<< "$QUERIES"

# Dedup by full_name (col 1), keeping the first (highest-star) sighting.
sort -t$'\t' -k1,1 -u "$tmp" -o "$tmp"

# Drop anything already triaged (present as a repo in research/ledger.jsonl).
touch "$LEDGER"
seen_repos="$(jq -r '.repo' "$LEDGER" 2>/dev/null || true)"
awk -F'\t' 'NR==FNR{seen[$0]=1; next} !($1 in seen)' <(printf '%s\n' "$seen_repos") "$tmp" > "$OUT"

n="$(wc -l < "$OUT" | tr -d ' ')"
echo "[discover] $n new candidate(s) -> $OUT" >&2
echo "$n"
