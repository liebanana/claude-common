#!/usr/bin/env bash
# meta: id=discover kind=script group="Discover & adopt external agent tooling" status=ready tags=discovery,multi-source intent="Find new agent/tooling candidates across GitHub + forums (HN, Lobsters, Reddit), merge cross-source signals, dedupe against the ledger"
# discover.sh — multi-source discovery orchestrator.
#
# Runs each enabled source script in scripts/sources/ (each emits normalized JSONL),
# normalizes GitHub links to owner/repo so forum links dedupe against repos, merges
# duplicates across sources (collecting which sources mentioned each tool = a reliability
# signal), drops anything already in research/ledger.jsonl, and writes the queue.
#
# Output: research/_candidates.jsonl — one object per NEW candidate:
#   {source, sources:[...], key, repo, title, url, signals:{...}, context_url?}
# Env:
#   SOURCES        which sources to run (default "github github-trending hackernews
#                  lobsters"). reddit is available but off by default (needs OAuth).
#   REQUIRE_REPO   1 (default) keep only items that resolve to a GitHub repo — forums
#                  then surface *tools*, not arxiv/blogs, and corroborate GitHub finds.
#                  Set 0 to also keep non-repo links (product sites, posts).
#   EXCLUDE_RE     case-insensitive regex; candidates whose repo/title match are dropped
#                  BEFORE triage ever spends tokens on them (predictably off-mission
#                  domains). Set to "" to disable.
#   plus each source's own env (MIN_STARS, HN_MIN_POINTS, LOBSTERS_TAGS, REDDIT_*, …)
#
# Output is SORTED best-first: corroborated (multi-source) > trending > forum buzz >
# stars — so consumers can take the top N and trust it's the highest-signal slice.
set -euo pipefail
REQUIRE_REPO="${REQUIRE_REPO:-1}"
EXCLUDE_RE="${EXCLUDE_RE-video|voice|avatar|music|song|vtuber|ui[-/]ux|anime|wallpaper}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEDGER="$REPO_DIR/research/ledger.jsonl"
OUT="$REPO_DIR/research/_candidates.jsonl"
SOURCES="${SOURCES:-github github-trending hackernews lobsters}"

raw="$(mktemp)"; norm="$(mktemp)"; seen="$(mktemp)"
trap 'rm -f "$raw" "$norm" "$seen"' EXIT

for s in $SOURCES; do
  script="$REPO_DIR/scripts/sources/$s.sh"
  if [ ! -f "$script" ]; then echo "[discover] unknown source: $s" >&2; continue; fi
  echo "[discover] source: $s" >&2
  bash "$script" >> "$raw" || echo "[discover] source $s errored, continuing" >&2
done

# Normalize: any github.com/<owner>/<repo> URL -> key/repo "owner/repo" so the same tool
# found on a forum dedupes against a GitHub hit and against the ledger.
jq -c '
  if (.url|type=="string") and (.url|test("https?://github\\.com/[^/]+/[^/]+")) then
    (.url|capture("github\\.com/(?<o>[^/]+)/(?<r>[^/?#]+)")) as $m
    | .key = ($m.o + "/" + ($m.r|sub("\\.git$";"")))
    | .repo = .key
  else . end
' "$raw" > "$norm" 2>/dev/null || cp "$raw" "$norm"

# Keys already triaged (dedup target).
touch "$LEDGER"
jq -r '(.key // .repo) // empty' "$LEDGER" 2>/dev/null | sort -u > "$seen"

# Merge duplicates by key (collect sources + shallow-merge signals), drop already-seen,
# drop predictably off-mission items, then rank best-first.
jq -c -s --rawfile seen "$seen" --argjson require_repo "$REQUIRE_REPO" --arg exclude "$EXCLUDE_RE" '
  ($seen | split("\n") | map(select(length>0)) | INDEX(.)) as $seenset
  | group_by(.key)
  | map( .[0] + {
      sources: (map(.source) | unique),
      signals: (reduce .[] as $x ({}; . + ($x.signals // {})))
    })
  | map(select(($seenset[.key]) | not))
  | map(select($require_repo == 0 or (.repo != null)))
  | map(select($exclude == "" or ((((.repo // "") + " " + (.title // "")) | test($exclude; "i")) | not)))
  | map(. + {_rank: (
      ((.sources | length) - 1) * 100000                    # corroboration dominates
      + (if .signals.trending then 20000 else 0 end)        # rising right now
      + ((.signals.points // .signals.score // 0) * 10)     # forum buzz
      + ((.signals.stars_period // 0) / 10)                 # weekly star velocity
      + ((.signals.stars // 0) / 1000)                      # absolute stars (weak tiebreak)
    )})
  | sort_by(-._rank)
  | map(del(._rank))
  | .[]
' "$norm" > "$OUT" 2>/dev/null || : > "$OUT"

n="$(wc -l < "$OUT" | tr -d ' ')"
echo "[discover] $n new candidate(s) across [$SOURCES] -> $OUT" >&2
echo "$n"
