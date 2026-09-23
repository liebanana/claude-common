#!/usr/bin/env bash
# meta: id=notify-hook kind=script group="Reusable Claude Code assets" status=ready tags=notify,telegram,hooks,stop-hook intent="Claude Code Stop-hook / cron wrapper that forwards a session summary (or a custom message) to Telegram via notify.sh"
# notify-hook.sh — thin wrapper for Claude Code Stop hooks and cron jobs. Origin: claude-notify-bot.
#
# Designed to be registered as a Claude Code Stop hook in .claude/settings.json:
#   {
#     "hooks": {
#       "Stop": [
#         {
#           "matcher": "",
#           "hooks": [
#             {
#               "type": "command",
#               "command": "$HOME/repos/claude-common/scripts/notify-hook.sh"
#             }
#           ]
#         }
#       ]
#     }
#   }
#
# When called by Claude Code as a Stop hook:
#   - Claude Code passes a JSON payload on stdin with session info.
#   - This script reads it (or a custom message from $NOTIFY_MSG / $1) and forwards
#     it via notify.sh.
#
# Usage:
#   notify-hook.sh                          # reads Claude Code JSON from stdin
#   notify-hook.sh "custom message"         # sends the given message
#   NOTIFY_MSG="done" notify-hook.sh        # env override
#   notify-hook.sh --title "MyProject"      # extra title prefix (+ stdin payload)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="${NOTIFY_BIN:-$SCRIPT_DIR/notify.sh}"

TITLE="${NOTIFY_TITLE:-Claude Code}"
MSG="${NOTIFY_MSG:-}"
EXTRA_TITLE=""

# Parse optional --title arg
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title|-t)
      EXTRA_TITLE="${2:?--title requires a value}"
      shift 2
      ;;
    *)
      MSG="$1"
      shift
      ;;
  esac
done

if [[ -n "$EXTRA_TITLE" ]]; then
  TITLE="$EXTRA_TITLE"
fi

# If no explicit message, try to read Claude Code's JSON payload from stdin
if [[ -z "$MSG" ]] && ! [[ -t 0 ]]; then
  STDIN_DATA="$(cat 2>/dev/null || true)"
  if [[ -n "$STDIN_DATA" ]]; then
    # Try to extract a summary from the Claude Code Stop hook payload (has "stop_reason", etc.)
    # python3 is required; falls back to raw JSON if parsing fails
    MSG="$(python3 -c '
import json, sys
try:
    data = json.loads(sys.argv[1])
    # Claude Code Stop hook payload fields
    reason = data.get("stop_reason", "")
    session = data.get("session_id", "")[:8]
    tool = data.get("tool_name", "")
    if reason:
        parts = ["Agent stopped"]
        if reason != "end_turn":
            parts.append(f"({reason})")
        if session:
            parts.append(f"session {session}")
        print(" — ".join(parts) if len(parts) > 1 else parts[0])
    else:
        print("Agent finished")
except Exception:
    print("Agent finished")
' "$STDIN_DATA" 2>/dev/null || echo "Agent finished")"
  fi
fi

# Final fallback
if [[ -z "$MSG" ]]; then
  MSG="Agent finished"
fi

exec "$NOTIFY" --title "$TITLE" "$MSG"
