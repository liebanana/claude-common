#!/usr/bin/env bash
# Unit test for scripts/lib/merge-settings.jq (repo wins; arrays unioned; hooks deduped by command).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
J="$R/scripts/lib/merge-settings.jq"
B="$R/templates/settings.baseline.json"
merge() { jq -s -f "$J" "$B" "$1"; }

echo '{}' > "$T/empty.json"
out=$(merge "$T/empty.json")
assert_eq "$(echo "$out" | jq -c .)" "$(jq -c . "$B")" "empty repo == baseline"

cat > "$T/repo.json" <<'EOF'
{ "enabledPlugins": {"x@y": true},
  "permissions": {"allow": ["Bash(ls:*)"], "deny": ["Read(./.env)"], "defaultMode": "auto"},
  "hooks": {"SessionStart": [{"hooks":[{"type":"command","command":"echo local"}]}],
            "Stop": [{"hooks":[{"type":"command","command":"echo bye"}]}]} }
EOF
out=$(merge "$T/repo.json")
assert_eq "$(echo "$out" | jq -r '.enabledPlugins["x@y"]')" "true" "repo key preserved"
assert_eq "$(echo "$out" | jq -r '.permissions.defaultMode')" "auto" "repo scalar wins"
assert_eq "$(echo "$out" | jq -c '.permissions.allow')" '["Bash(ls:*)"]' "allow kept"
assert_eq "$(echo "$out" | jq -c '.permissions.deny|sort')" '["Read(./.env)","Read(./.env.*)"]' "deny unioned+deduped"
assert_eq "$(echo "$out" | jq '.hooks.SessionStart|length')" "2" "baseline hook appended"
assert_eq "$(echo "$out" | jq -r '.hooks.SessionStart[0].hooks[0].command')" "echo local" "repo hook first"
assert_eq "$(echo "$out" | jq '.hooks.Stop|length')" "1" "other event untouched"

# idempotent: merging the merged output again changes nothing
echo "$out" > "$T/merged.json"
assert_eq "$(merge "$T/merged.json" | jq -c .)" "$(jq -c . "$T/merged.json")" "idempotent"
finish merge-settings-test
