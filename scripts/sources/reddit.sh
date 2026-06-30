#!/usr/bin/env bash
# sources/reddit.sh — emit Reddit post candidates (external tool links) as JSONL.
#
# Reddit blocks unauthenticated .json from datacenter IPs (403), so this uses the
# app-only OAuth flow. It is OPTIONAL: if creds are absent it prints a notice and
# emits nothing (the orchestrator just skips it). Create a free "script" app at
# https://www.reddit.com/prefs/apps and set:
#   REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET   (required)
#   REDDIT_SUBS (default below), REDDIT_T (top window: day|week|month), REDDIT_MIN_SCORE (20)
# Signals: score (users/reliability), comments, age_days.
set -euo pipefail
if [ -z "${REDDIT_CLIENT_ID:-}" ] || [ -z "${REDDIT_CLIENT_SECRET:-}" ]; then
  echo "[reddit] no REDDIT_CLIENT_ID/SECRET — skipping (set them to enable; see script header)." >&2
  exit 0
fi
SUBS="${REDDIT_SUBS:-ClaudeAI ClaudeCode LocalLLaMA AI_Agents mcp ChatGPTCoding}"
T="${REDDIT_T:-week}"
MIN_SCORE="${REDDIT_MIN_SCORE:-20}"
UA="claude-common-discover/1.0"

token="$(curl -fsSL -A "$UA" -u "$REDDIT_CLIENT_ID:$REDDIT_CLIENT_SECRET" \
  -d grant_type=client_credentials https://www.reddit.com/api/v1/access_token 2>/dev/null \
  | jq -r '.access_token // empty')"
if [ -z "$token" ]; then
  echo "[reddit] auth failed — check creds." >&2; exit 0
fi

now=$(date -u +%s)
for sub in ${SUBS//,/ }; do
  curl -fsSL -A "$UA" -H "Authorization: bearer $token" \
    "https://oauth.reddit.com/r/$sub/top?t=$T&limit=25" 2>/dev/null \
    | jq -c --argjson now "$now" --argjson min "$MIN_SCORE" '.data.children[]?.data
        | select(.is_self == false and .score >= $min and .url != null) | {
            source:"reddit", key:.url, repo:null, title:.title, url:.url,
            signals:{score:.score, comments:.num_comments, subreddit:.subreddit,
                     age_days:(($now - .created_utc)/86400|floor)},
            context_url:("https://www.reddit.com" + .permalink)
          }' || echo "[reddit] sub failed: $sub" >&2
  sleep 1
done
