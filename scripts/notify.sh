#!/usr/bin/env bash
# meta: id=notify kind=script group="Reusable Claude Code assets" status=ready tags=notify,telegram,cron,hooks intent="Send a Telegram message from any script/cron/hook — env-driven (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID), Markdown with plain-text fallback, no jq dependency"
# notify.sh — send a Telegram message via the Bot API.
# Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from the environment, or from a .env file next to this
# script, or from $NOTIFY_ENV_FILE. See scripts/notify.env.example. Origin: the claude-notify-bot repo.
#
# Usage:
#   notify "message body"
#   notify --title "My Project" "message body"
#   echo "message" | notify --stdin
#   notify --stdin --title "CI" < /dev/stdin
#
# Exit codes: 0 success | 1 usage/config error | 2 API call failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- load .env if it exists (NOTIFY_ENV_FILE overrides the default location) ---
ENV_FILE="${NOTIFY_ENV_FILE:-$SCRIPT_DIR/.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1091
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
fi

# --- parse args ---
TITLE=""
MSG=""
READ_STDIN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title|-t)
      TITLE="${2:?--title requires a value}"
      shift 2
      ;;
    --stdin)
      READ_STDIN=1
      shift
      ;;
    --)
      shift
      MSG="$*"
      break
      ;;
    -*)
      echo "notify: unknown option '$1'" >&2
      echo "Usage: notify [--title TEXT] [--stdin] MESSAGE" >&2
      exit 1
      ;;
    *)
      MSG="$1"
      shift
      ;;
  esac
done

if [[ "$READ_STDIN" -eq 1 ]]; then
  MSG="$(cat)"
fi

if [[ -z "$MSG" ]]; then
  echo "notify: message is required" >&2
  echo "Usage: notify [--title TEXT] [--stdin] MESSAGE" >&2
  exit 1
fi

# --- validate env ---
if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "notify: TELEGRAM_BOT_TOKEN is not set. Add it to $SCRIPT_DIR/.env or export it." >&2
  exit 1
fi

if [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "notify: TELEGRAM_CHAT_ID is not set. Add it to $SCRIPT_DIR/.env or export it." >&2
  exit 1
fi

# --- build text ---
if [[ -n "$TITLE" ]]; then
  TEXT="*${TITLE}*"$'\n'"${MSG}"
else
  TEXT="$MSG"
fi

# --- POST to Telegram ---
API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

# Use python3 for JSON encoding (available everywhere; avoids jq dependency)
# NOTIFY_PARSE_MODE controls Telegram formatting: defaults to "Markdown" (back-compat).
# Set it empty (NOTIFY_PARSE_MODE="") to send literal plain text — safe for messages
# containing URLs/underscores/asterisks that would otherwise break Markdown parsing.
PAYLOAD="$(python3 -c '
import json, os, sys
chat_id, text = sys.argv[1], sys.argv[2]
pm = os.environ.get("NOTIFY_PARSE_MODE", "Markdown")
payload = {"chat_id": chat_id, "text": text}
if pm:
    payload["parse_mode"] = pm
print(json.dumps(payload))
' "$TELEGRAM_CHAT_ID" "$TEXT")"

RESP="$(mktemp)"; trap 'rm -f "$RESP"' EXIT
HTTP_CODE="$(curl -sS -o "$RESP" -w "%{http_code}" \
  -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>/dev/null)"

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  echo "notify: sent (HTTP $HTTP_CODE)"
  exit 0
fi

# --- Auto-fallback (2026-07-12): Markdown parse failures (unbalanced _ * etc.) got messages
# silently LOST for callers that forgot NOTIFY_PARSE_MODE="". On a 400 entity-parse error,
# retry ONCE as literal plain text — the message always arrives; formatting is best-effort.
if [[ "$HTTP_CODE" == "400" ]] && grep -q "can't parse entities" "$RESP" 2>/dev/null; then
  echo "notify: Markdown parse failed — retrying as plain text" >&2
  PAYLOAD_PLAIN="$(python3 -c '
import json, sys
print(json.dumps({"chat_id": sys.argv[1], "text": sys.argv[2]}))
' "$TELEGRAM_CHAT_ID" "$TEXT")"
  HTTP_CODE="$(curl -sS -o "$RESP" -w "%{http_code}"     -X POST "$API_URL"     -H "Content-Type: application/json"     -d "$PAYLOAD_PLAIN" 2>/dev/null)"
  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    echo "notify: sent plain (HTTP $HTTP_CODE)"
    exit 0
  fi
fi

echo "notify: Telegram API returned HTTP $HTTP_CODE" >&2
cat "$RESP" >&2 2>/dev/null; echo >&2
exit 2
