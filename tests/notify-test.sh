#!/usr/bin/env bash
# Contract tests for scripts/notify.sh + notify-hook.sh that need no network: usage/config errors and
# the message-building path (curl is stubbed via PATH).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
N="$R/scripts/notify.sh"; H="$R/scripts/notify-hook.sh"
env -u TELEGRAM_BOT_TOKEN -u TELEGRAM_CHAT_ID NOTIFY_ENV_FILE=/nonexistent bash "$N" "hi" >/dev/null 2>&1; assert_eq "$?" 1 "missing token exits 1"
TELEGRAM_BOT_TOKEN=x TELEGRAM_CHAT_ID=y NOTIFY_ENV_FILE=/nonexistent bash "$N" >/dev/null 2>&1; assert_eq "$?" 1 "missing message exits 1"
# stub curl: record the payload, answer 200
mkdir -p "$T/bin"; cat > "$T/bin/curl" <<'STUB'
#!/usr/bin/env bash
out=""; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift;; -d) printf '%s' "$2" > "$CURL_LOG"; shift;; esac; shift; done
[ -n "$out" ] && echo '{"ok":true}' > "$out"; printf '200'
STUB
chmod +x "$T/bin/curl"
out=$(PATH="$T/bin:$PATH" CURL_LOG="$T/payload" TELEGRAM_BOT_TOKEN=123:abc TELEGRAM_CHAT_ID=42 NOTIFY_ENV_FILE=/nonexistent bash "$N" --title "CI" "hello_world"); assert_eq "$?" 0 "send exit 0"
assert_grep '"chat_id": "42"' "$T/payload"; assert_grep 'CI' "$T/payload"; assert_grep 'hello_world' "$T/payload"
# .env file loading via NOTIFY_ENV_FILE
printf 'TELEGRAM_BOT_TOKEN=1:z\nTELEGRAM_CHAT_ID=7\n' > "$T/env"
PATH="$T/bin:$PATH" CURL_LOG="$T/payload2" NOTIFY_ENV_FILE="$T/env" bash "$N" "x" >/dev/null; assert_grep '"chat_id": "7"' "$T/payload2"
# hook: custom message and Stop-hook JSON on stdin
PATH="$T/bin:$PATH" CURL_LOG="$T/payload3" TELEGRAM_BOT_TOKEN=1:z TELEGRAM_CHAT_ID=7 NOTIFY_ENV_FILE=/nonexistent bash "$H" "custom done" >/dev/null; assert_grep 'custom done' "$T/payload3"
echo '{"stop_reason":"end_turn","session_id":"abcdef1234"}' | PATH="$T/bin:$PATH" CURL_LOG="$T/payload4" TELEGRAM_BOT_TOKEN=1:z TELEGRAM_CHAT_ID=7 NOTIFY_ENV_FILE=/nonexistent bash "$H" >/dev/null; assert_grep 'Agent stopped' "$T/payload4"
finish notify-test
