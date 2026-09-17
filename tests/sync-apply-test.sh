#!/usr/bin/env bash
# Unit tests for scripts/lib/sync-apply.sh on temp dirs (no git involved).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
. "$R/scripts/lib/sync-apply.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# --- fake exported tag tree
SRC="$T/src"; mkdir -p "$SRC/.claude/commands" "$SRC/.claude/agents" "$SRC/hooks" "$SRC/templates"
echo "# DIRECTIVE v-test" > "$SRC/AGENT-DIRECTIVE.md"
printf -- '---\ndescription: cmd one\n---\nbody one\n' > "$SRC/.claude/commands/one.md"
printf -- 'no frontmatter agent\n' > "$SRC/.claude/agents/bot.md"
printf -- '#!/usr/bin/env bash\necho hook\n' > "$SRC/hooks/version-check.sh"
cp "$R/templates/settings.baseline.json" "$R/templates/claude-md-block.md" "$SRC/templates/"
mkdir -p "$SRC/scripts/lib"; cp "$R/scripts/lib/merge-settings.jq" "$SRC/scripts/lib/"

# --- case 1: empty repo, no CLAUDE.md
D1="$T/d1"; mkdir -p "$D1"
apply_contract "$SRC" "$D1" v1.2.3 fresh-repo || _fail "apply_contract d1 rc"
assert_file "$D1/AGENT-DIRECTIVE.md"
assert_grep '^# fresh-repo$' "$D1/CLAUDE.md"
assert_count '^@AGENT-DIRECTIVE\.md$' "$D1/CLAUDE.md" 1
assert_grep 'claude-common v1\.2\.3' "$D1/CLAUDE.md"
# Tightened assertions for one.md (cmd file with frontmatter)
assert_eq "$(sed -n 1p "$D1/.claude/commands/one.md")" "---" "one.md line 1"
assert_eq "$(sed -n 2p "$D1/.claude/commands/one.md")" "managed-by: claude-common" "one.md line 2"
assert_eq "$(sed -n 3p "$D1/.claude/commands/one.md")" "description: cmd one" "one.md line 3"
assert_eq "$(sed -n 4p "$D1/.claude/commands/one.md")" "---" "one.md line 4"
assert_count '^---$' "$D1/.claude/commands/one.md" 2 "one.md two --- delimiters"
# Tightened assertions for bot.md (agent file without frontmatter)
assert_eq "$(sed -n 1p "$D1/.claude/agents/bot.md")" "---" "bot.md line 1"
assert_eq "$(sed -n 2p "$D1/.claude/agents/bot.md")" "managed-by: claude-common" "bot.md line 2"
assert_eq "$(sed -n 3p "$D1/.claude/agents/bot.md")" "---" "bot.md line 3"
assert_eq "$(sed -n 4p "$D1/.claude/agents/bot.md")" "no frontmatter agent" "bot.md line 4"
assert_exec "$D1/.claude/hooks/common/version-check.sh"
assert_eq "$(jq -S -c . "$D1/.claude/settings.json")" "$(jq -S -c . "$SRC/templates/settings.baseline.json")" "settings == baseline"
assert_eq "$(jq -r .version "$D1/.claude/common.lock")" "v1.2.3" "lock version"
assert_eq "$(jq -c '.managed|sort' "$D1/.claude/common.lock")" \
  '[".claude/agents/bot.md",".claude/commands/one.md",".claude/hooks/common/version-check.sh","AGENT-DIRECTIVE.md"]' "lock managed"

# --- case 2: existing repo with title, stray import, local agent, settings with plugins + own hook
D2="$T/d2"; mkdir -p "$D2/.claude/agents"
printf -- '# My Repo\n\n@AGENT-DIRECTIVE.md\n\n## Rules\n- keep me\n' > "$D2/CLAUDE.md"
echo "local agent" > "$D2/.claude/agents/local.md"
cat > "$D2/.claude/settings.json" <<'EOF'
{"enabledPlugins":{"p@m":true},"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo mine"}]}]}}
EOF
apply_contract "$SRC" "$D2" v1.2.3 my-repo || _fail "apply_contract d2 rc"
assert_count '^@AGENT-DIRECTIVE\.md$' "$D2/CLAUDE.md" 1
assert_count '^<!-- claude-common:begin -->$' "$D2/CLAUDE.md" 1
assert_eq "$(sed -n 1p "$D2/CLAUDE.md")" "# My Repo" "title kept first"
assert_eq "$(sed -n 3p "$D2/CLAUDE.md")" "<!-- claude-common:begin -->" "block right after title"
assert_grep '^- keep me$' "$D2/CLAUDE.md"
assert_eq "$(cat "$D2/.claude/agents/local.md")" "local agent" "local agent untouched"
assert_eq "$(jq -r '.enabledPlugins["p@m"]' "$D2/.claude/settings.json")" "true" "plugins kept"
assert_eq "$(jq '.hooks.SessionStart|length' "$D2/.claude/settings.json")" "2" "hook appended"
# idempotent re-run
cp -r "$D2" "$T/d2-before"
apply_contract "$SRC" "$D2" v1.2.3 my-repo || _fail "re-apply rc"
diff -r "$T/d2-before" "$D2" >/dev/null || _fail "second apply changed files"

# --- case 3: upstream removed a managed file; local file with same prefix survives
D3="$T/d3"; mkdir -p "$D3/.claude/commands"
echo "old managed" > "$D3/.claude/commands/gone.md"
echo "mine"        > "$D3/.claude/commands/keep.md"
mkdir -p "$D3/.claude"; printf '{"version":"v1.0.0","synced":"2026-01-01","managed":[".claude/commands/gone.md","AGENT-DIRECTIVE.md"]}' > "$D3/.claude/common.lock"
apply_contract "$SRC" "$D3" v1.2.3 r3 || _fail "apply d3 rc"
assert_not_file "$D3/.claude/commands/gone.md"
assert_file "$D3/.claude/commands/keep.md"
assert_file "$D3/.claude/commands/one.md"

# --- apply_block alone (self mode)
D4="$T/d4"; mkdir -p "$D4"; printf '# Self\n\n@AGENT-DIRECTIVE.md\n\nbody\n' > "$D4/CLAUDE.md"
apply_block "$D4" v2.0.0 self "$SRC" || _fail "apply_block rc"
assert_count '^@AGENT-DIRECTIVE\.md$' "$D4/CLAUDE.md" 1
assert_grep 'claude-common v2\.0\.0' "$D4/CLAUDE.md"
assert_not_file "$D4/AGENT-DIRECTIVE.md"

# --- apply_block must fail without template
D5="$T/d5"; mkdir -p "$D5"
if apply_block "$D5" v1 x "$T/nosrc" 2>/dev/null; then _fail "apply_block should fail without template"; fi

# --- apply_contract must fail (and propagate) when the directive cannot be written
# AGENT-DIRECTIVE.md is a directory, and it already contains a same-named subdirectory, so
# `cp .../AGENT-DIRECTIVE.md $D6/AGENT-DIRECTIVE.md` can't copy-into (name collision) or overwrite.
D6="$T/d6"; mkdir -p "$D6/AGENT-DIRECTIVE.md/AGENT-DIRECTIVE.md"
if apply_contract "$SRC" "$T/d6" v1 r6 2>/dev/null; then _fail "apply_contract should fail when directive cannot be written"; fi
finish sync-apply-test
