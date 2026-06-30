#!/usr/bin/env bash
# sources/github-trending.sh — emit currently-trending GitHub repos as normalized JSONL.
#
# Scrapes https://github.com/trending (no API exists). This is the "what's rising right
# now" signal. Filtered to agent/AI-relevant repos by keyword (trending is not
# topic-scoped, so we cut the noise here). No auth needed.
# Env:
#   TREND_SINCE      daily | weekly | monthly        (default weekly)
#   TREND_KEYWORDS   regex (case-insensitive) repo/description must match
#                    (default: agent/AI/Claude/MCP/LLM/token/prompt/context/skill/rag)
set -euo pipefail
TREND_SINCE="${TREND_SINCE:-weekly}"
TREND_KEYWORDS="${TREND_KEYWORDS:-claude|agent|agentic|mcp|llm|\\bai\\b|prompt|context|token|rag|skill|subagent|copilot|cli}"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
curl -fsSL -H "User-Agent: Mozilla/5.0 claude-common-discover/1.0" \
  "https://github.com/trending?since=${TREND_SINCE}" -o "$tmp" 2>/dev/null || true
[ -s "$tmp" ] || { echo "[github-trending] fetch failed" >&2; exit 0; }

# NB: the program is read from stdin (the heredoc); the HTML file path is argv[1].
TREND_SINCE="$TREND_SINCE" TREND_KEYWORDS="$TREND_KEYWORDS" python3 - "$tmp" <<'PY'
import os, re, sys, json
html = open(sys.argv[1], encoding="utf-8", errors="replace").read()
since = os.environ.get("TREND_SINCE", "weekly")
kw = re.compile(os.environ.get("TREND_KEYWORDS", ""), re.I)
# Split into per-repo article blocks.
blocks = re.split(r'<article class="Box-row">', html)[1:]
for b in blocks:
    m = re.search(r'href="/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)"\s+data-view', b)
    if not m:
        continue
    repo = m.group(1)
    dm = re.search(r'<p class="col-9[^"]*"[^>]*>\s*(.*?)\s*</p>', b, re.S)
    desc = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', dm.group(1))).strip() if dm else ""
    sm = re.search(r'([\d,]+)\s+stars\s+(?:this week|today|this month)', b)
    stars_period = int(sm.group(1).replace(",", "")) if sm else None
    if not (kw.search(repo) or kw.search(desc)):
        continue
    print(json.dumps({
        "source": "github-trending",
        "key": repo, "repo": repo,
        "title": desc, "url": f"https://github.com/{repo}",
        "signals": {"stars_period": stars_period, "period": since, "trending": True},
    }, ensure_ascii=False))
PY
