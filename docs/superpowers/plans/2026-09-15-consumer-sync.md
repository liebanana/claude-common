# Consumer Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every repo under `~/repos` runs on the same pinned, tagged release of claude-common, delivered as one reviewable PR per repo by a script that a weekly cron and a human can both run.

**Architecture:** Pure file transformation lives in `scripts/lib/sync-apply.sh` (`apply_contract`) and a jq merge program, both testable on temp dirs with no git. `scripts/sync-consumers.sh` wraps that in git/PR orchestration (temp worktree per repo, branch `common/vX.Y.Z`, `gh pr create`). `scripts/release.sh` cuts tags. A SessionStart hook copied into every repo warns when the pin is behind.

**Tech Stack:** bash (`set -uo pipefail`, explicit error returns), jq 1.7, git 2.43, gh 2.95, python3 (existing `build-index.py`). No shellcheck on this host — use `bash -n`.

**Spec:** `docs/superpowers/specs/2026-09-14-consumer-sync-design.md`

## Global Constraints

- Public repo: **no secrets, no absolute home paths in committed files** except the manifest `root` (`~/repos`, tilde-expanded at runtime).
- Every script self-documents at the top and carries a `# meta:` line (build-index scans `scripts/*.sh`, `hooks/*`).
- Scripts exit non-zero on failure; per-repo failures do not abort the run.
- Never write to a consumer's default branch. Never push claude-common from the sync script.
- Markers are exactly `<!-- claude-common:begin -->` and `<!-- claude-common:end -->`.
- Managed-file marker is the frontmatter key `managed-by: claude-common`.
- Lock file path is `.claude/common.lock`; schema `{"version":"vX.Y.Z","synced":"YYYY-MM-DD","managed":[...]}`.
- Consumer branch name is `common/vX.Y.Z`; commit subject `chore: sync claude-common vX.Y.Z`.
- Commit trailer on every commit: `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Run `python3 scripts/build-index.py` after adding any script/hook; commit the regenerated files with it.

## File structure

| Path | Responsibility |
|---|---|
| `sync/consumers.json` | the consumer manifest (data only) |
| `templates/settings.baseline.json` | baseline settings merged into every consumer |
| `templates/claude-md-block.md` | CLAUDE.md block, `{{VERSION}}` placeholder |
| `CHANGELOG.md` | Keep-a-Changelog; `release.sh` rotates `[Unreleased]` |
| `scripts/lib/merge-settings.jq` | deep-merge baseline + repo settings, repo wins |
| `scripts/lib/sync-apply.sh` | `apply_block`, `apply_contract` — file contract, no git |
| `hooks/version-check.sh` | SessionStart hook shipped to consumers |
| `scripts/sync-consumers.sh` | orchestration: manifest, worktree, commit, push, PR, status |
| `scripts/release.sh` | tag a release |
| `tests/merge-settings-test.sh`, `tests/sync-apply-test.sh`, `tests/version-check-test.sh`, `tests/sync-smoke.sh`, `tests/release-test.sh` | one test script per unit; each exits 0 on pass |
| `tests/lib/assert.sh` | tiny assert helpers shared by tests |

---

### Task 1: Static assets — manifest, templates, CHANGELOG, test helpers

**Files:**
- Create: `sync/consumers.json`, `templates/settings.baseline.json`, `templates/claude-md-block.md`, `CHANGELOG.md`, `tests/lib/assert.sh`, `tests/manifest-test.sh`

**Interfaces:**
- Produces: manifest schema `{root, exclude[], consumers[{repo,mode}]}`; template placeholder `{{VERSION}}`; `assert_eq`, `assert_file`, `assert_grep`, `assert_no_grep`, `assert_not_file`, `pass` helpers.

- [ ] **Step 1: Write the test helpers**

`tests/lib/assert.sh`:
```bash
#!/usr/bin/env bash
# Tiny assert helpers for tests/*.sh. Source me. Each failure prints and exits 1.
FAILS=0
_fail() { echo "  FAIL: $*" >&2; FAILS=$((FAILS+1)); }
assert_eq()       { [ "$1" = "$2" ] || _fail "$3: expected '$2' got '$1'"; }
assert_file()     { [ -f "$1" ] || _fail "missing file $1"; }
assert_not_file() { [ ! -e "$1" ] || _fail "should not exist: $1"; }
assert_exec()     { [ -x "$1" ] || _fail "not executable: $1"; }
assert_grep()     { grep -qE -- "$1" "$2" || _fail "'$1' not found in $2"; }
assert_no_grep()  { ! grep -qE -- "$1" "$2" || _fail "'$1' unexpectedly found in $2"; }
assert_count()    { local n; n=$(grep -cE -- "$1" "$2" || true); [ "$n" = "$3" ] || _fail "'$1' in $2: expected $3 matches, got $n"; }
finish()          { if [ "$FAILS" = 0 ]; then echo "PASS: $1"; exit 0; else echo "FAILED: $1 ($FAILS)"; exit 1; fi; }
```

- [ ] **Step 2: Write the failing manifest test**

`tests/manifest-test.sh`:
```bash
#!/usr/bin/env bash
# Validates sync/consumers.json: schema, modes, every listed repo exists under root on this host.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_REPO="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
M="$ROOT_REPO/sync/consumers.json"
assert_file "$M"
jq -e '.root and (.exclude|type=="array") and (.consumers|type=="array")' "$M" >/dev/null || _fail "schema"
jq -e '[.consumers[].mode] | all(. as $m | ["pr","skip","self"] | index($m))' "$M" >/dev/null || _fail "bad mode"
jq -e '[.consumers[].repo] | length == (unique|length)' "$M" >/dev/null || _fail "duplicate repo"
jq -e '[.consumers[] | select(.mode=="self")] | length == 1' "$M" >/dev/null || _fail "exactly one self"
root="$(jq -r .root "$M")"; root="${root/#\~/$HOME}"
while read -r r; do [ -d "$root/$r/.git" ] || _fail "consumer dir missing: $root/$r"; done < <(jq -r '.consumers[].repo' "$M")
assert_file "$ROOT_REPO/templates/settings.baseline.json"
jq -e '.permissions.deny | index("Read(./.env)")' "$ROOT_REPO/templates/settings.baseline.json" >/dev/null || _fail "baseline deny"
jq -e '.hooks.SessionStart[0].hooks[0].command | test("version-check")' "$ROOT_REPO/templates/settings.baseline.json" >/dev/null || _fail "baseline hook"
assert_grep '^<!-- claude-common:begin -->$' "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^<!-- claude-common:end -->$'   "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^@AGENT-DIRECTIVE\.md$'          "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '\{\{VERSION\}\}'                  "$ROOT_REPO/templates/claude-md-block.md"
assert_grep '^## \[Unreleased\]'               "$ROOT_REPO/CHANGELOG.md"
finish manifest-test
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash tests/manifest-test.sh` — Expected: `FAIL: missing file .../sync/consumers.json` … `FAILED`.

- [ ] **Step 4: Create the assets**

`sync/consumers.json`:
```json
{
  "root": "~/repos",
  "exclude": [],
  "consumers": [
    { "repo": "claude-ai-trends",         "mode": "pr" },
    { "repo": "claude-notify-bot",        "mode": "pr" },
    { "repo": "claude-stay-tripper",      "mode": "pr" },
    { "repo": "claude-tradingdesk",       "mode": "pr" },
    { "repo": "claude-language-content",  "mode": "pr" },
    { "repo": "claude-language-medialab", "mode": "pr" },
    { "repo": "claude-language-tutor",    "mode": "pr" },
    { "repo": "langtutor",                "mode": "pr" },
    { "repo": "langtutor-infra",          "mode": "pr" },
    { "repo": "topo-arch-ac",             "mode": "pr" },
    { "repo": "mix-hunters",              "mode": "pr" },
    { "repo": "Starlock",                 "mode": "pr" },
    { "repo": "vault",                    "mode": "pr" },
    { "repo": "claude-common",            "mode": "self" }
  ]
}
```

`templates/settings.baseline.json`:
```json
{
  "permissions": {
    "deny": ["Read(./.env)", "Read(./.env.*)"]
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/common/version-check.sh\"" }
        ]
      }
    ]
  }
}
```

`templates/claude-md-block.md`:
```markdown
<!-- claude-common:begin -->
<!-- Managed by claude-common {{VERSION}} via scripts/sync-consumers.sh — edit upstream, not here. -->
@AGENT-DIRECTIVE.md

**Shared agent toolkit (claude-common {{VERSION}}).** Before building tooling, scripts, agents or hooks
from scratch, check `~/repos/claude-common`: query `index.json` with `jq` or read `CATALOG.md`. If an
asset fits, use it; if it needs a step you shouldn't take alone (install, auth, MCP server), recommend
it to the user instead of reinventing. Learned something reusable? Run `/contribute-to-common`.
<!-- claude-common:end -->
```

`CHANGELOG.md`:
```markdown
# Changelog

All notable changes to claude-common. Format: Keep a Changelog. Versions are git tags `vX.Y.Z`;
consumers pin to a tag via `scripts/sync-consumers.sh`.

## [Unreleased]

### Added
- Consumer sync: `sync/consumers.json`, `scripts/sync-consumers.sh`, `scripts/release.sh`,
  `hooks/version-check.sh`, baseline settings + CLAUDE.md block templates.
- `CHANGELOG.md`.

### Changed
- `AGENT-DIRECTIVE.md` is now mastered here (was `~/repos/AGENT-DIRECTIVE.md` + `sync-directive.sh`).
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/manifest-test.sh` — Expected: `PASS: manifest-test`.

- [ ] **Step 6: Commit**

```bash
git add sync templates CHANGELOG.md tests
git commit -m "sync: manifest, baseline settings, CLAUDE.md block template, changelog, test helpers

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Settings merge program (`merge-settings.jq`)

**Files:**
- Create: `scripts/lib/merge-settings.jq`, `tests/merge-settings-test.sh`

**Interfaces:**
- Produces: `jq -s -f scripts/lib/merge-settings.jq baseline.json repo.json` → merged JSON on stdout. Repo scalars/objects win; `permissions.allow`/`deny` unioned; each `hooks.<Event>` list = repo groups + baseline groups whose first command isn't already present.

- [ ] **Step 1: Write the failing test**

`tests/merge-settings-test.sh`:
```bash
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
```

- [ ] **Step 2: Run to verify it fails** — `bash tests/merge-settings-test.sh` → jq error "Could not open scripts/lib/merge-settings.jq".

- [ ] **Step 3: Write the program**

`scripts/lib/merge-settings.jq`:
```jq
# merge-settings.jq — input: [baseline, repo] (via `jq -s`). Output: merged settings.
# Rules: repo wins on conflicting keys ($b * $r); permissions.allow/deny are unioned;
# each hooks.<Event> list = repo groups + baseline groups whose first command is absent.
.[0] as $b | .[1] as $r
| def union($x; $y): (($x // []) + ($y // [])) | unique;
  def cmds: [.hooks[]?.command];
  def merge_hooks($bh; $rh):
      ((($bh // {}) | keys) + (($rh // {}) | keys)) | unique
      | map(. as $k
            | ($rh[$k] // []) as $rg
            | ($rg | map(cmds) | add // []) as $have
            | { key: $k,
                value: ($rg + (($bh[$k] // []) | map(select((cmds | .[0]) as $c | ($have | index($c)) == null)))) })
      | from_entries;
  ($b * $r)
  | .permissions.allow = union($b.permissions.allow; $r.permissions.allow)
  | .permissions.deny  = union($b.permissions.deny;  $r.permissions.deny)
  | .hooks = merge_hooks($b.hooks; $r.hooks)
  | if .permissions.allow == [] then del(.permissions.allow) else . end
  | if .permissions.deny  == [] then del(.permissions.deny)  else . end
  | if .hooks == {} then del(.hooks) else . end
```

- [ ] **Step 4: Run to verify it passes** — `bash tests/merge-settings-test.sh` → `PASS: merge-settings-test`. If "empty repo == baseline" fails on key order, compare with `jq -S -c` on both sides instead.

- [ ] **Step 5: Commit**
```bash
git add scripts/lib/merge-settings.jq tests/merge-settings-test.sh
git commit -m "sync: jq settings merge (repo wins, arrays unioned, hooks deduped)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: The file contract — `scripts/lib/sync-apply.sh`

**Files:**
- Create: `scripts/lib/sync-apply.sh`, `tests/sync-apply-test.sh`

**Interfaces:**
- Consumes: `scripts/lib/merge-settings.jq`, `templates/*` (found relative to `SRC`).
- Produces (sourced, not executed):
  - `apply_block DST VERSION REPO_NAME SRC` — upserts the CLAUDE.md block only (used by `release.sh` for the `self` consumer).
  - `apply_contract SRC DST VERSION REPO_NAME` — full contract (§3 of spec). `SRC` = an exported tag tree of claude-common. Prints nothing on success; returns non-zero on error.
  - `write_lock DST VERSION MANAGED_LIST_NEWLINE_SEPARATED`.

- [ ] **Step 1: Write the failing test**

`tests/sync-apply-test.sh`:
```bash
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
assert_grep '^managed-by: claude-common$' "$D1/.claude/commands/one.md"
assert_grep '^description: cmd one$' "$D1/.claude/commands/one.md"
assert_grep '^managed-by: claude-common$' "$D1/.claude/agents/bot.md"
assert_grep '^no frontmatter agent$' "$D1/.claude/agents/bot.md"
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
finish sync-apply-test
```

- [ ] **Step 2: Run to verify it fails** — `bash tests/sync-apply-test.sh` → "No such file … sync-apply.sh".

- [ ] **Step 3: Write the library**

`scripts/lib/sync-apply.sh`:
```bash
#!/usr/bin/env bash
# sync-apply.sh — the claude-common consumer *file contract*, as sourceable functions. No git here.
#   apply_contract SRC DST VERSION REPO   full contract (directive, managed commands/agents/hooks,
#                                         settings merge, CLAUDE.md block, lock)
#   apply_block    DST VERSION REPO SRC   CLAUDE.md block only (used for the `self` consumer)
#   write_lock     DST VERSION MANAGED    MANAGED = newline-separated relative paths
# SRC = an exported claude-common tree (git archive of a tag). Functions return non-zero on error.
# Spec: docs/superpowers/specs/2026-09-14-consumer-sync-design.md §3

CC_BEGIN='<!-- claude-common:begin -->'
CC_END='<!-- claude-common:end -->'
CC_MARK='managed-by: claude-common'

# _render_block SRC VERSION -> block text on stdout
_render_block() { sed "s/{{VERSION}}/$2/g" "$1/templates/claude-md-block.md"; }

# _copy_marked SRCFILE DSTFILE  — copy a .md adding `managed-by: claude-common` to frontmatter
_copy_marked() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ "$(head -c 4 "$src")" = "---"$'\n' ]; then
    { echo '---'; echo "$CC_MARK"; tail -n +2 "$src"; } > "$dst"
  else
    { echo '---'; echo "$CC_MARK"; echo '---'; cat "$src"; } > "$dst"
  fi
}

apply_block() {
  local dst="$1" version="$2" repo="$3" src="$4" f="$1/CLAUDE.md" tmp
  tmp="$(mktemp)"
  if [ ! -f "$f" ]; then
    { echo "# $repo"; echo; _render_block "$src" "$version"; } > "$f"; rm -f "$tmp"; return 0
  fi
  # 1) strip existing block and stray import lines
  awk -v b="$CC_BEGIN" -v e="$CC_END" '
    $0==b {skip=1; next} $0==e {skip=0; next} skip {next}
    /^@AGENT-DIRECTIVE\.md[[:space:]]*$/ {next} {print}' "$f" > "$tmp"
  # 2) insert block after the first H1 (plus a blank line), else at top
  local block; block="$(_render_block "$src" "$version")"
  if grep -q '^# ' "$tmp"; then
    awk -v blk="$block" '!done && /^# / {print; print ""; print blk; done=1; next} {print}' "$tmp" > "$tmp.2"
  else
    { echo "$block"; echo; cat "$tmp"; } > "$tmp.2"
  fi
  # 3) squeeze runs of >1 blank lines left by the strip
  cat -s "$tmp.2" > "$f"; rm -f "$tmp" "$tmp.2"
}

write_lock() {
  local dst="$1" version="$2" managed="$3"
  mkdir -p "$dst/.claude"
  printf '%s\n' "$managed" | grep -v '^$' | sort -u \
    | jq -R . | jq -s --arg v "$version" --arg d "$(date -u +%F)" '{version:$v, synced:$d, managed:.}' \
    > "$dst/.claude/common.lock"
}

apply_contract() {
  local src="$1" dst="$2" version="$3" repo="$4"
  [ -f "$src/AGENT-DIRECTIVE.md" ] || { echo "apply_contract: $src is not a claude-common export" >&2; return 1; }
  local managed="" old_managed=""
  [ -f "$dst/.claude/common.lock" ] && old_managed="$(jq -r '.managed[]?' "$dst/.claude/common.lock" 2>/dev/null || true)"

  cp "$src/AGENT-DIRECTIVE.md" "$dst/AGENT-DIRECTIVE.md"; managed+="AGENT-DIRECTIVE.md"$'\n'

  local f rel
  for f in "$src"/.claude/commands/*.md "$src"/.claude/agents/*.md; do
    [ -f "$f" ] || continue; [ "$(basename "$f")" = README.md ] && continue
    rel=".claude/$(basename "$(dirname "$f")")/$(basename "$f")"
    _copy_marked "$f" "$dst/$rel"; managed+="$rel"$'\n'
  done
  for f in "$src"/hooks/*.sh; do
    [ -f "$f" ] || continue
    rel=".claude/hooks/common/$(basename "$f")"
    mkdir -p "$dst/.claude/hooks/common"; cp "$f" "$dst/$rel"; chmod +x "$dst/$rel"; managed+="$rel"$'\n'
  done

  # settings: baseline merged under repo settings (repo wins)
  mkdir -p "$dst/.claude"
  local cur="$dst/.claude/settings.json" tmp; tmp="$(mktemp)"
  [ -f "$cur" ] || echo '{}' > "$cur"
  jq -s -f "$src/scripts/lib/merge-settings.jq" "$src/templates/settings.baseline.json" "$cur" > "$tmp" \
    || { rm -f "$tmp"; echo "apply_contract: settings merge failed for $repo" >&2; return 1; }
  mv "$tmp" "$cur"

  apply_block "$dst" "$version" "$repo" "$src"

  # delete previously-managed files that upstream no longer ships (only under managed prefixes)
  local p
  while read -r p; do
    [ -n "$p" ] || continue
    printf '%s\n' "$managed" | grep -qxF "$p" && continue
    case "$p" in .claude/commands/*|.claude/agents/*|.claude/hooks/common/*) rm -f "$dst/$p" ;; esac
  done <<< "$old_managed"

  write_lock "$dst" "$version" "$managed"
}
```

- [ ] **Step 4: Run to verify it passes** — `bash tests/sync-apply-test.sh` → `PASS: sync-apply-test`. Typical fixes if not: `head -c 4` comparison (use `[ "$(head -n1 "$src")" = "---" ]` instead); `cat -s` behaviour on the "block right after title" assertion (line 3 must be the begin marker — title, blank, marker).

- [ ] **Step 5: `bash -n scripts/lib/sync-apply.sh` and commit**
```bash
git add scripts/lib/sync-apply.sh tests/sync-apply-test.sh
git commit -m "sync: file contract library (directive, managed assets, settings merge, CLAUDE.md block, lock)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: SessionStart hook — `hooks/version-check.sh`

**Files:**
- Create: `hooks/version-check.sh`, `tests/version-check-test.sh`
- Modify: `hooks/README.md` (add one line listing the hook)

**Interfaces:**
- Consumes: `.claude/common.lock` in `$CLAUDE_PROJECT_DIR` (falls back to `$PWD`); `CLAUDE_COMMON_DIR` (default `$HOME/repos/claude-common`).
- Produces: one stdout line when behind; nothing otherwise; always exit 0.

- [ ] **Step 1: Write the failing test**

`tests/version-check-test.sh`:
```bash
#!/usr/bin/env bash
# Tests hooks/version-check.sh against a fake claude-common with tags and fake project dirs.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
H="$R/hooks/version-check.sh"
git init -q "$T/common" && git -C "$T/common" commit -q --allow-empty -m init \
  && git -C "$T/common" tag v1.0.0 && git -C "$T/common" tag v1.2.0 && git -C "$T/common" tag v1.10.0
mk() { mkdir -p "$T/$1/.claude"; printf '{"version":"%s","synced":"2026-01-01","managed":[]}' "$2" > "$T/$1/.claude/common.lock"; }
mk behind v1.2.0; mk current v1.10.0; mkdir -p "$T/nolock"

out=$(CLAUDE_COMMON_DIR="$T/common" CLAUDE_PROJECT_DIR="$T/behind"  bash "$H"); rc=$?
assert_eq "$rc" 0 "exit 0 behind"; assert_eq "$out" "claude-common: repo pinned v1.2.0, latest v1.10.0 — run scripts/sync-consumers.sh" "behind message"
out=$(CLAUDE_COMMON_DIR="$T/common" CLAUDE_PROJECT_DIR="$T/current" bash "$H"); assert_eq "$out" "" "silent when current"
out=$(CLAUDE_COMMON_DIR="$T/common" CLAUDE_PROJECT_DIR="$T/nolock"  bash "$H"); assert_eq "$out" "" "silent without lock"
out=$(CLAUDE_COMMON_DIR="$T/absent" CLAUDE_PROJECT_DIR="$T/behind"  bash "$H"); rc=$?; assert_eq "$rc" 0 "exit 0 no common"; assert_eq "$out" "" "silent without claude-common"
finish version-check-test
```

- [ ] **Step 2: Run to verify it fails** — `bash tests/version-check-test.sh` → "No such file".

- [ ] **Step 3: Write the hook**

`hooks/version-check.sh`:
```bash
#!/usr/bin/env bash
# meta: id=version-check kind=hook group="Reusable Claude Code assets" status=ready tags=hook,session-start,sync intent="SessionStart hook: warn when the repo's pinned claude-common version is behind the newest local tag"
# version-check.sh — shipped to every consumer as .claude/hooks/common/version-check.sh (SessionStart).
# Reads .claude/common.lock, compares to the newest v* tag in $CLAUDE_COMMON_DIR (default
# ~/repos/claude-common). Local git only, no network. Prints one line when behind, else nothing.
# Always exits 0 so a broken host never blocks a session.
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
common="${CLAUDE_COMMON_DIR:-$HOME/repos/claude-common}"
lock="$proj/.claude/common.lock"
[ -f "$lock" ] && [ -d "$common/.git" ] || exit 0
pinned="$(jq -r '.version // empty' "$lock" 2>/dev/null)" || exit 0
latest="$(git -C "$common" tag -l 'v*' --sort=-v:refname 2>/dev/null | head -n1)"
[ -n "$pinned" ] && [ -n "$latest" ] || exit 0
[ "$pinned" = "$latest" ] && exit 0
echo "claude-common: repo pinned $pinned, latest $latest — run scripts/sync-consumers.sh"
exit 0
```
`chmod +x hooks/version-check.sh`. Add to `hooks/README.md`: `- \`version-check.sh\` — SessionStart: warns when \`.claude/common.lock\` is behind the newest claude-common tag (installed by \`scripts/sync-consumers.sh\`).`

- [ ] **Step 4: Run to verify it passes** — `bash tests/version-check-test.sh` → `PASS`. Also `python3 scripts/build-index.py` and confirm `jq -r '.assets[]|select(.id=="version-check")|.path' index.json` prints `hooks/version-check.sh`.

- [ ] **Step 5: Commit**
```bash
git add hooks tests/version-check-test.sh index.json CATALOG.md
git commit -m "hooks: version-check SessionStart hook (warn when pinned claude-common is behind)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Orchestrator — `scripts/sync-consumers.sh`

**Files:**
- Create: `scripts/sync-consumers.sh`, `tests/sync-smoke.sh`

**Interfaces:**
- Consumes: `apply_contract` (Task 3), manifest (Task 1).
- Produces CLI:
  `sync-consumers.sh [--status] [--dry-run] [--discover] [--repo NAME]… [--version vX.Y.Z] [--root DIR] [--manifest FILE] [--push]`
  Env: `AUTO_PUSH=1` ≡ `--push`; `GH_BIN` (default `gh`) — tests substitute a fake; `SYNC_SCRATCH` (default `<common>/state/sync-wt`).
  Exit 0 if every consumer succeeded, 1 otherwise.

- [ ] **Step 1: Write the failing smoke test**

`tests/sync-smoke.sh`:
```bash
#!/usr/bin/env bash
# End-to-end: fake root with 4 repos, fake tagged claude-common clone, fake gh. No network.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# fake claude-common: working tree of the real repo (incl. uncommitted work) committed + tagged
C="$T/common"; mkdir -p "$C"
( cd "$R" && git ls-files -co --exclude-standard | grep -v '^state/' | tar -cf - -T - ) | tar -xf - -C "$C"
git -C "$C" init -q && git -C "$C" add -A && git -C "$C" commit -qm base && git -C "$C" tag v9.9.9

# fake gh: records calls, returns an open PR after create
GH="$T/gh"; cat > "$GH" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr list")   if [ -f "$GH_LOG.created" ]; then echo 7; fi ;;   # mimics `--json number -q '.[0].number'`
  "pr create") touch "$GH_LOG.created"; echo "https://example.test/pr/7" ;;
  "pr edit")   echo edited ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$GH"; export GH_BIN="$GH" GH_LOG="$T/gh.log"

# fake root: a (remote, CLAUDE.md, dirty file), b (no CLAUDE.md), c (worktree of a), d (no remote)
ROOT="$T/root"; mkdir -p "$ROOT" "$T/remotes"
mkrepo() { git init -q -b main "$ROOT/$1"; ( cd "$ROOT/$1" && echo "# $1" > README.md && git add -A && git commit -qm init ); }
mkrepo a; mkrepo b; mkrepo d
( cd "$ROOT/a" && printf '# A\n\n@AGENT-DIRECTIVE.md\n\nlocal rules\n' > CLAUDE.md && git add -A && git commit -qm claude \
  && git init -q --bare "$T/remotes/a.git" && git remote add origin "$T/remotes/a.git" && git push -q -u origin main \
  && git remote set-head origin main && echo dirty > dirty.txt )
( cd "$ROOT/b" && git init -q --bare "$T/remotes/b.git" && git remote add origin "$T/remotes/b.git" && git push -q -u origin main && git remote set-head origin main )
git -C "$ROOT/a" worktree add -q "$ROOT/c" -b wt-branch
cat > "$T/manifest.json" <<EOF
{"root":"$ROOT","exclude":["zzz"],"consumers":[{"repo":"a","mode":"pr"},{"repo":"b","mode":"pr"},{"repo":"c","mode":"pr"},{"repo":"d","mode":"pr"},{"repo":"common","mode":"self"}]}
EOF
mkdir -p "$ROOT/zzz/.git" "$ROOT/unlisted"; git init -q "$ROOT/unlisted"

S="$C/scripts/sync-consumers.sh"
# --discover
out=$(bash "$S" --manifest "$T/manifest.json" --discover); assert_eq "$out" "unlisted" "discover finds only unlisted"
# --status before
out=$(bash "$S" --manifest "$T/manifest.json" --status); assert_grep '^a[[:space:]].*unmanaged' <(echo "$out"); assert_grep '^c[[:space:]].*worktree' <(echo "$out")
# --dry-run changes nothing
bash "$S" --manifest "$T/manifest.json" --dry-run >/dev/null; rc=$?; assert_eq "$rc" 0 "dry-run rc"
assert_eq "$(git -C "$ROOT/a" branch --list 'common/*' | wc -l)" "0" "dry-run made no branch"
# real run with push
out=$(AUTO_PUSH=1 bash "$S" --manifest "$T/manifest.json" 2>&1); rc=$?
echo "$out" > "$T/run1.log"; assert_eq "$rc" 0 "run1 rc"
assert_grep 'a: PR https://example.test/pr/7' "$T/run1.log"
assert_grep 'c: skip \(worktree\)' "$T/run1.log"
assert_grep 'd: no remote — branch common/v9.9.9 left local' "$T/run1.log"
assert_grep 'common: self' "$T/run1.log"
git -C "$T/remotes/a.git" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null || _fail "a branch not pushed"
git -C "$T/remotes/b.git" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null || _fail "b branch not pushed"
git -C "$ROOT/d" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null || _fail "d local branch missing"
assert_file "$ROOT/a/dirty.txt"; assert_not_file "$ROOT/a/AGENT-DIRECTIVE.md"   # user tree untouched
assert_eq "$(git -C "$ROOT/a" rev-parse --abbrev-ref HEAD)" "main" "a still on main"
git -C "$ROOT/a" show common/v9.9.9:.claude/common.lock | jq -e '.version=="v9.9.9"' >/dev/null || _fail "lock on branch"
assert_eq "$(git -C "$ROOT/a" show common/v9.9.9:CLAUDE.md | grep -c '^@AGENT-DIRECTIVE.md$')" "1" "single import on branch"
git -C "$ROOT/b" show common/v9.9.9:CLAUDE.md | grep -q '^# b$' || _fail "b scaffolded CLAUDE.md"
assert_grep '^pr create' "$GH_LOG"
[ -z "$(ls -A "$C/state/sync-wt" 2>/dev/null)" ] || _fail "scratch worktrees not cleaned"
# second run: branches unchanged, no new push, PR reused
sha_before=$(git -C "$ROOT/a" rev-parse common/v9.9.9)
out=$(AUTO_PUSH=1 bash "$S" --manifest "$T/manifest.json" 2>&1); assert_eq "$?" 0 "run2 rc"
assert_eq "$(git -C "$ROOT/a" rev-parse common/v9.9.9)" "$sha_before" "run2 did not rewrite branch"
assert_grep 'a: pr-open #7 \(unchanged\)' <(echo "$out")
assert_eq "$(grep -c '^pr create' "$GH_LOG")" "2" "no third pr create (a,b once each)"
# --status after
out=$(bash "$S" --manifest "$T/manifest.json" --status); assert_grep '^a[[:space:]].*pr-open #7' <(echo "$out"); assert_grep '^d[[:space:]].*no-remote' <(echo "$out")
# merge a's PR (fast-forward main) → status current, run is a no-op
( cd "$ROOT/a" && git merge -q --ff-only common/v9.9.9 && git push -q origin main )
out=$(bash "$S" --manifest "$T/manifest.json" --status); assert_grep '^a[[:space:]].*current' <(echo "$out")
finish sync-smoke
```

- [ ] **Step 2: Run to verify it fails** — `bash tests/sync-smoke.sh` → "No such file … sync-consumers.sh".

- [ ] **Step 3: Write the orchestrator**

`scripts/sync-consumers.sh`:
```bash
#!/usr/bin/env bash
# meta: id=sync-consumers kind=script group="Index & navigation" status=ready tags=sync,release,pr,cron intent="Bring every consumer repo to the latest tagged claude-common release via one PR per repo (status/dry-run/discover modes)"
# sync-consumers.sh — pin every consumer repo to a claude-common release. One PR per repo. Never
# touches a default branch or the user's working tree (works in a temp git worktree per repo).
#
#   scripts/sync-consumers.sh                 # sync all consumers behind the newest v* tag (local branch only)
#   AUTO_PUSH=1 scripts/sync-consumers.sh     # …and push + open/refresh a PR per repo (or --push)
#   scripts/sync-consumers.sh --status        # table: repo · pinned · latest · state
#   scripts/sync-consumers.sh --dry-run       # show what would change, commit nothing
#   scripts/sync-consumers.sh --discover      # git repos under root that are in neither consumers nor exclude
#   scripts/sync-consumers.sh --repo X [--repo Y] [--version vX.Y.Z] [--root DIR] [--manifest FILE]
# Env: AUTO_PUSH, GH_BIN (default gh), SYNC_SCRATCH (default <common>/state/sync-wt), CLAUDE_COMMON_DIR.
# Exit 1 if any consumer failed (others still processed). Spec: docs/superpowers/specs/2026-09-14-consumer-sync-design.md §4
set -uo pipefail
COMMON="${CLAUDE_COMMON_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
. "$COMMON/scripts/lib/sync-apply.sh"

MANIFEST="$COMMON/sync/consumers.json"; MODE=sync; DRY=0; PUSH="${AUTO_PUSH:-0}"; VERSION=""; ROOT_OVERRIDE=""
declare -a ONLY=()
while [ $# -gt 0 ]; do
  case "$1" in
    --status) MODE=status ;; --discover) MODE=discover ;; --dry-run) DRY=1 ;; --push) PUSH=1 ;;
    --repo) ONLY+=("$2"); shift ;; --version) VERSION="$2"; shift ;; --root) ROOT_OVERRIDE="$2"; shift ;;
    --manifest) MANIFEST="$2"; shift ;; -h|--help) sed -n '3,14p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done
GH="${GH_BIN:-gh}"; SCRATCH="${SYNC_SCRATCH:-$COMMON/state/sync-wt}"
log() { echo "[sync] $*"; }

[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 2; }
ROOT="${ROOT_OVERRIDE:-$(jq -r .root "$MANIFEST")}"; ROOT="${ROOT/#\~/$HOME}"
[ -d "$ROOT" ] || { echo "root not found: $ROOT" >&2; exit 2; }
LATEST="$(git -C "$COMMON" tag -l 'v*' --sort=-v:refname | head -n1)"
TARGET="${VERSION:-$LATEST}"

is_worktree() { local g c; g="$(git -C "$1" rev-parse --git-dir 2>/dev/null)" || return 1; c="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)"; [ "$(cd "$1" && realpath "$g")" != "$(cd "$1" && realpath "$c")" ]; }
default_branch() { local d; d="$(git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"; [ -n "$d" ] && { echo "${d#origin/}"; return; }
  git -C "$1" show-ref -q --verify refs/heads/main && { echo main; return; }; git -C "$1" show-ref -q --verify refs/heads/master && { echo master; return; }; return 1; }
has_remote() { git -C "$1" remote get-url origin >/dev/null 2>&1; }
pinned_of() { local ref="$1" dir="$2"; git -C "$dir" show "$ref:.claude/common.lock" 2>/dev/null | jq -r '.version // empty' 2>/dev/null; }
pr_number() { has_remote "$1" || return 0; command -v "$GH" >/dev/null 2>&1 || return 0; (cd "$1" && "$GH" pr list --head "$2" --state open --json number -q '.[0].number' 2>/dev/null) || true; }
changelog_delta() { awk -v v="$TARGET" '$0 ~ "^## \\["v"\\]" {p=1; next} p && /^## \[/ {exit} p' "$EXPORT/CHANGELOG.md" 2>/dev/null; }

# ---------- discover
if [ "$MODE" = discover ]; then
  for d in "$ROOT"/*/; do d="${d%/}"; n="$(basename "$d")"
    [ -d "$d/.git" ] || continue                                  # real repos only (worktrees have a .git file)
    jq -e --arg n "$n" '(.exclude|index($n)) or ([.consumers[].repo]|index($n))' "$MANIFEST" >/dev/null && continue
    echo "$n"; done; exit 0
fi

# ---------- export the tag once
EXPORT=""
if [ "$MODE" = sync ]; then
  [ -n "$TARGET" ] || { echo "no v* tag in $COMMON — run scripts/release.sh first" >&2; exit 2; }
  git -C "$COMMON" rev-parse -q --verify "refs/tags/$TARGET" >/dev/null || { echo "tag not found: $TARGET" >&2; exit 2; }
  EXPORT="$(mktemp -d)"; trap 'rm -rf "$EXPORT"' EXIT
  git -C "$COMMON" archive "$TARGET" | tar -xf - -C "$EXPORT"
fi

# ---------- per-repo
[ "$MODE" = status ] && printf '%-28s %-10s %-10s %s\n' REPO PINNED LATEST STATE
FAILED=0
while IFS=$'\t' read -r repo mode; do
  if [ ${#ONLY[@]} -gt 0 ]; then printf '%s\n' "${ONLY[@]}" | grep -qxF "$repo" || continue; fi
  dir="$ROOT/$repo"; branch="common/$TARGET"
  if [ "$MODE" = status ]; then
    state=""; pinned="-"
    if   [ "$mode" = skip ]; then state=skip
    elif [ "$mode" = self ]; then pinned="$(jq -r '.version // "-"' "$COMMON/.claude/common.lock" 2>/dev/null || echo -)"; state=self
    elif [ ! -d "$dir" ]; then state=missing
    elif is_worktree "$dir"; then state=worktree
    else
      db="$(default_branch "$dir")" || { state=no-default-branch; }
      [ -z "$state" ] && { pinned="$(pinned_of "$db" "$dir")"; pinned="${pinned:--}"
        if [ "$pinned" = "$LATEST" ]; then state=current
        elif n="$(pr_number "$dir" "$branch")" && [ -n "$n" ]; then state="pr-open #$n"
        elif git -C "$dir" show-ref -q --verify "refs/heads/$branch"; then state="$( has_remote "$dir" && echo branch-local || echo no-remote )"
        elif [ "$pinned" = "-" ]; then state=unmanaged; else state=behind; fi; }
    fi
    printf '%-28s %-10s %-10s %s\n' "$repo" "$pinned" "${LATEST:--}" "$state"; continue
  fi

  # ----- sync mode
  [ "$mode" = skip ] && { log "$repo: skip (manifest)"; continue; }
  [ "$mode" = self ] && { log "$repo: self (written by release.sh)"; continue; }
  [ -d "$dir/.git" ] || [ -f "$dir/.git" ] || { log "$repo: missing at $dir"; FAILED=1; continue; }
  is_worktree "$dir" && { log "$repo: skip (worktree)"; continue; }
  db="$(default_branch "$dir")" || { log "$repo: no default branch"; FAILED=1; continue; }
  remote=0; has_remote "$dir" && remote=1
  base="$db"
  if [ $remote = 1 ]; then git -C "$dir" fetch -q origin "$db" 2>/dev/null && base="origin/$db" || log "$repo: fetch failed, using local $db"; fi
  if [ ${#ONLY[@]} -eq 0 ] && [ "$(pinned_of "$base" "$dir")" = "$TARGET" ]; then log "$repo: current ($TARGET)"; continue; fi

  wt="$SCRATCH/$repo"; mkdir -p "$SCRATCH"; git -C "$dir" worktree remove -f "$wt" 2>/dev/null; rm -rf "$wt"
  prev="$(git -C "$dir" rev-parse -q --verify "refs/heads/$branch" 2>/dev/null || true)"
  if [ $DRY = 1 ]; then
    git -C "$dir" worktree add -q --detach "$wt" "$base" || { log "$repo: worktree add failed"; FAILED=1; continue; }
  else
    git -C "$dir" worktree add -q -B "$branch" "$wt" "$base" 2>/dev/null \
      || { log "$repo: cannot create branch $branch (checked out elsewhere?)"; FAILED=1; continue; }
  fi
  if ! apply_contract "$EXPORT" "$wt" "$TARGET" "$repo"; then log "$repo: apply failed"; git -C "$dir" worktree remove -f "$wt"; FAILED=1; continue; fi
  ( cd "$wt" && git add -A )
  if ( cd "$wt" && git diff --cached --quiet ); then
    log "$repo: up-to-date (no changes)"; git -C "$dir" worktree remove -f "$wt"; continue
  fi
  if [ $DRY = 1 ]; then
    log "$repo: would change:"; ( cd "$wt" && git diff --cached --stat | sed 's/^/    /' ); git -C "$dir" worktree remove -f "$wt"; continue
  fi
  ( cd "$wt" && git commit -q -m "chore: sync claude-common $TARGET

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" )
  if [ -n "$prev" ] && ( cd "$wt" && git diff --quiet "$prev" HEAD ); then
    ( cd "$wt" && git reset -q --hard "$prev" )       # identical content: keep old sha, no re-push
    n="$(pr_number "$dir" "$branch")"; log "$repo: ${n:+pr-open #$n }(unchanged)"; git -C "$dir" worktree remove -f "$wt"; continue
  fi
  if [ $remote = 0 ]; then log "$repo: no remote — branch $branch left local"; git -C "$dir" worktree remove -f "$wt"; continue; fi
  if [ "$PUSH" != 1 ]; then log "$repo: branch $branch committed locally (AUTO_PUSH!=1, no push/PR)"; git -C "$dir" worktree remove -f "$wt"; continue; fi
  if ! ( cd "$wt" && git push -q --force-with-lease -u origin "$branch" ); then log "$repo: push failed"; git -C "$dir" worktree remove -f "$wt"; FAILED=1; continue; fi
  body="Pin claude-common to **$TARGET** (managed files only; repo-local rules untouched).

Changed:
$(cd "$wt" && git diff --name-only "$base" HEAD | sed 's/^/- /')

Changelog $TARGET:
$(changelog_delta)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
  if command -v "$GH" >/dev/null 2>&1; then
    n="$(pr_number "$dir" "$branch")"
    if [ -n "$n" ]; then (cd "$wt" && "$GH" pr edit "$n" --body "$body" >/dev/null) && log "$repo: PR #$n refreshed" || log "$repo: pr edit failed (branch pushed)"
    else url="$(cd "$wt" && "$GH" pr create --base "$db" --head "$branch" --title "chore: sync claude-common $TARGET" --body "$body" 2>&1)" \
         && log "$repo: PR $url" || { log "$repo: gh pr create failed: $url (branch pushed; open manually)"; FAILED=1; }
    fi
  else log "$repo: gh not found; branch pushed — open a PR manually"; fi
  git -C "$dir" worktree remove -f "$wt"
done < <(jq -r '.consumers[] | [.repo, .mode] | @tsv' "$MANIFEST")
exit $FAILED
```

- [ ] **Step 4: `bash -n scripts/sync-consumers.sh`, `chmod +x`, run the smoke test** — `bash tests/sync-smoke.sh` → `PASS: sync-smoke`. Likely iterations: `git worktree add -B` needs the branch not checked out anywhere (the test's `c` worktree uses `wt-branch`, fine); `git fetch origin main` inside the fake (file remote) works; `pr_number` must return empty (not fail) when gh is absent; `--discover` must ignore `zzz` (excluded) and `common`? — `common` is listed as `self`, so it's excluded from discover already.

- [ ] **Step 5: Re-run all tests, rebuild index, commit**
```bash
for t in tests/*-test.sh tests/sync-smoke.sh; do bash "$t" || exit 1; done
python3 scripts/build-index.py
git add scripts/sync-consumers.sh tests/sync-smoke.sh index.json CATALOG.md
git commit -m "sync: consumer orchestrator (temp worktree per repo, branch common/vX.Y.Z, PR per repo, status/dry-run/discover)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: `scripts/release.sh`

**Files:**
- Create: `scripts/release.sh`, `tests/release-test.sh`

**Interfaces:**
- Consumes: `apply_block`, `write_lock` (Task 3); `CHANGELOG.md`; `build-index.py`.
- Produces: `release.sh <major|minor|patch> [-m NOTE] [--dry-run]` → commit `release: vX.Y.Z`, annotated tag, `git push origin main vX.Y.Z`. Env `RELEASE_NO_PUSH=1` skips the push (tests).

- [ ] **Step 1: Write the failing test**

`tests/release-test.sh`:
```bash
#!/usr/bin/env bash
# Tests scripts/release.sh on a temp clone with a bare origin (no network).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
C="$T/common"; mkdir -p "$C"
( cd "$R" && git ls-files -co --exclude-standard | grep -v '^state/' | tar -cf - -T - ) | tar -xf - -C "$C"
git -C "$C" init -q -b main && git -C "$C" add -A && git -C "$C" commit -qm base
git init -q --bare "$T/origin.git"; git -C "$C" remote add origin "$T/origin.git"; git -C "$C" push -q -u origin main

# guard: dirty tree refuses
echo x > "$C/junk"; out=$(cd "$C" && bash scripts/release.sh patch 2>&1); assert_eq "$?" 1 "dirty refuses"; rm "$C/junk"
# guard: bad bump arg
out=$(cd "$C" && bash scripts/release.sh nope 2>&1); assert_eq "$?" 2 "bad arg rc"
# first release → v1.0.0 regardless of bump kind
out=$(cd "$C" && bash scripts/release.sh patch 2>&1); assert_eq "$?" 0 "release rc"
assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v1.0.0" "first tag"
assert_eq "$(git -C "$T/origin.git" tag -l v1.0.0)" "v1.0.0" "tag pushed"
assert_eq "$(git -C "$C" log -1 --format=%s)" "release: v1.0.0" "commit subject"
assert_grep "^## \[v1\.0\.0\] - $(date -u +%F)$" "$C/CHANGELOG.md"
assert_grep '^## \[Unreleased\]$' "$C/CHANGELOG.md"
assert_eq "$(jq -r .version "$C/.claude/common.lock")" "v1.0.0" "self lock"
assert_count '^@AGENT-DIRECTIVE\.md$' "$C/CLAUDE.md" 1
assert_grep 'claude-common v1\.0\.0' "$C/CLAUDE.md"
# second: minor → v1.1.0 ; then patch → v1.1.1 ; major → v2.0.0
( cd "$C" && bash scripts/release.sh minor >/dev/null 2>&1 ); assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v1.1.0" "minor"
( cd "$C" && bash scripts/release.sh patch >/dev/null 2>&1 ); assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v1.1.1" "patch"
( cd "$C" && bash scripts/release.sh major >/dev/null 2>&1 ); assert_eq "$(git -C "$C" describe --tags --exact-match HEAD)" "v2.0.0" "major"
# --dry-run: no commit, no tag
before=$(git -C "$C" rev-parse HEAD); ( cd "$C" && bash scripts/release.sh patch --dry-run >/dev/null 2>&1 )
assert_eq "$(git -C "$C" rev-parse HEAD)" "$before" "dry-run no commit"; assert_eq "$(git -C "$C" tag -l v2.0.1)" "" "dry-run no tag"
finish release-test
```

- [ ] **Step 2: Run to verify it fails** — `bash tests/release-test.sh` → "No such file".

- [ ] **Step 3: Write the script**

`scripts/release.sh`:
```bash
#!/usr/bin/env bash
# meta: id=release kind=script group="Index & navigation" status=ready tags=release,tag,changelog intent="Cut a tagged claude-common release: rotate CHANGELOG, write self lock + CLAUDE.md block, rebuild index, tag vX.Y.Z, push"
# release.sh — cut a release of claude-common.
#   scripts/release.sh <major|minor|patch> [-m "note"] [--dry-run]
# Refuses unless on main, clean, and not behind origin/main. First release is always v1.0.0.
# Steps: CHANGELOG [Unreleased] -> [vX.Y.Z] - date; self lock + CLAUDE.md block; build-index;
#        commit "release: vX.Y.Z"; annotated tag; push main + tag (RELEASE_NO_PUSH=1 to skip).
set -uo pipefail
COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$COMMON" || exit 1
. scripts/lib/sync-apply.sh
BUMP="${1:-}"; shift || true; NOTE=""; DRY=0
while [ $# -gt 0 ]; do case "$1" in -m) NOTE="$2"; shift ;; --dry-run) DRY=1 ;; *) echo "unknown arg: $1" >&2; exit 2 ;; esac; shift; done
case "$BUMP" in major|minor|patch) ;; *) echo "usage: release.sh <major|minor|patch> [-m note] [--dry-run]" >&2; exit 2 ;; esac

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "release.sh: not on main" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "release.sh: working tree dirty" >&2; exit 1; }
if git remote get-url origin >/dev/null 2>&1; then
  git fetch -q origin main 2>/dev/null || true
  if git rev-parse -q --verify origin/main >/dev/null && [ "$(git rev-list --count HEAD..origin/main)" != 0 ]; then
    echo "release.sh: main is behind origin/main — pull first" >&2; exit 1; fi
fi

latest="$(git tag -l 'v*' --sort=-v:refname | head -n1)"
if [ -z "$latest" ]; then next=v1.0.0; else
  IFS=. read -r MA MI PA <<< "${latest#v}"
  case "$BUMP" in major) next="v$((MA+1)).0.0" ;; minor) next="v$MA.$((MI+1)).0" ;; patch) next="v$MA.$MI.$((PA+1))" ;; esac
fi
echo "release.sh: $latest -> $next"
[ $DRY = 1 ] && { echo "(dry-run) would rotate CHANGELOG, write self lock/block, commit, tag $next"; exit 0; }

# CHANGELOG: [Unreleased] -> [next] - date, then a fresh empty [Unreleased]
tmp="$(mktemp)"
awk -v v="$next" -v d="$(date -u +%F)" -v note="$NOTE" '
  /^## \[Unreleased\]/ && !done { print "## [Unreleased]"; print ""; print "## [" v "] - " d; if (note != "") { print ""; print "- " note }; done=1; next } { print }' CHANGELOG.md > "$tmp" && mv "$tmp" CHANGELOG.md

apply_block "$COMMON" "$next" claude-common "$COMMON"
write_lock "$COMMON" "$next" ""
python3 scripts/build-index.py >/dev/null

git add -A
git commit -q -m "release: $next

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
git tag -a "$next" -m "claude-common $next${NOTE:+ — $NOTE}"
if [ "${RELEASE_NO_PUSH:-0}" = 1 ]; then echo "release.sh: tagged $next (RELEASE_NO_PUSH=1, not pushed)"; exit 0; fi
if git remote get-url origin >/dev/null 2>&1; then git push -q origin main "$next" && echo "release.sh: pushed $next" || { echo "release.sh: push failed (tag exists locally)" >&2; exit 1; }
else echo "release.sh: no origin; tagged $next locally"; fi
```

- [ ] **Step 4: Run to verify it passes** — `chmod +x scripts/release.sh; bash tests/release-test.sh` → `PASS: release-test`. Note `write_lock … ""` produces `managed: []`.

- [ ] **Step 5: Rebuild index, commit**
```bash
python3 scripts/build-index.py
git add scripts/release.sh tests/release-test.sh index.json CATALOG.md
git commit -m "release: tagging script (changelog rotation, self lock/block, annotated tag, push)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Directive text, docs, workspace cutover

**Files:**
- Modify: `AGENT-DIRECTIVE.md` (lines 3-5, master-copy sentence), `CLAUDE.md` (Commands + new "Releases & consumer sync" section), `scripts/README.md` (list new scripts), `hooks/README.md` (done in Task 4)
- Workspace (not in any repo): `~/repos/AGENT-DIRECTIVE.md` → symlink; delete `~/repos/sync-directive.sh`; edit `~/repos/CLAUDE.md`

- [ ] **Step 1: Update the directive header**

Replace in `AGENT-DIRECTIVE.md` the two lines
```
Each repo's own `CLAUDE.md` imports it via `@AGENT-DIRECTIVE.md` and adds repo-specific rules on top — repo rules **never override** this.
Master copy: `~/repos/AGENT-DIRECTIVE.md`; propagate edits with `~/repos/sync-directive.sh`.
```
with
```
Each repo's own `CLAUDE.md` imports it via `@AGENT-DIRECTIVE.md` and adds repo-specific rules on top — repo rules **never override** this.
Master copy: `claude-common/AGENT-DIRECTIVE.md`, released as tags (`scripts/release.sh`) and delivered to every repo as a PR by `scripts/sync-consumers.sh`. Edit it there, never in a consumer.
```
Verify: `grep -c sync-directive AGENT-DIRECTIVE.md` → `0`.

- [ ] **Step 2: Document in `CLAUDE.md`**

Add to the `## Commands` block:
```bash
scripts/release.sh <major|minor|patch> [-m note]   # tag a release (rotates CHANGELOG, pushes tag)
scripts/sync-consumers.sh --status                # which repo is on which claude-common version
AUTO_PUSH=1 scripts/sync-consumers.sh             # PR every behind repo up to the newest tag
scripts/sync-consumers.sh --dry-run|--discover    # preview / find unlisted repos
for t in tests/*.sh; do bash "$t"; done           # the test suite (all bash, no deps beyond jq/git)
```
Add a section after "Cron setup":
```markdown
## Releases & consumer sync

Every repo under `~/repos` is a **consumer** of claude-common pinned to a tag (`sync/consumers.json`).
`AGENT-DIRECTIVE.md` is mastered here. To ship a change to all repos:
1. Merge it to `main`, note it under `[Unreleased]` in `CHANGELOG.md`.
2. `scripts/release.sh minor` (or `patch`/`major`) → tag `vX.Y.Z` pushed.
3. `AUTO_PUSH=1 scripts/sync-consumers.sh` → one PR per repo (`common/vX.Y.Z`); merge them.
   The weekly cron does step 3 automatically. `--status` shows drift; the shipped SessionStart hook
   (`hooks/version-check.sh`) warns inside any repo that is behind.
What lands in a consumer (all copies, committed): `AGENT-DIRECTIVE.md`; `.claude/commands|agents/*`
carrying `managed-by: claude-common`; `.claude/hooks/common/*.sh`; a jq-merged `.claude/settings.json`
(repo keys win); a marker block in `CLAUDE.md`; `.claude/common.lock`. Repo-local files are never touched.
Spec: `docs/superpowers/specs/2026-09-14-consumer-sync-design.md`. Tests: `tests/`.
```
Update the architecture tree in `CLAUDE.md` with lines for `sync/`, `templates/`, `tests/`, `CHANGELOG.md`.
In `scripts/README.md` "Current scripts", add `release.sh`, `sync-consumers.sh`, and `lib/` (sourced helpers).
Also update `CLAUDE.md`'s `.claude/settings.json` bullet if it lists allowed tools (unchanged), and `.gitignore` already covers `state/` — confirm with `git check-ignore state/sync-wt`.

- [ ] **Step 3: Workspace cutover (outside git)**
```bash
ln -sfn "$HOME/repos/claude-common/AGENT-DIRECTIVE.md" "$HOME/repos/AGENT-DIRECTIVE.md"
rm "$HOME/repos/sync-directive.sh"
```
Edit `~/repos/CLAUDE.md`: replace the two "Master copy / Propagate edits" bullets with
```
- **Master copy:** `~/repos/claude-common/AGENT-DIRECTIVE.md` (released as tags; `~/repos/AGENT-DIRECTIVE.md` is a symlink)
- **Deliver to all repos:** `AUTO_PUSH=1 ~/repos/claude-common/scripts/sync-consumers.sh` (one PR per repo; `--status` to see drift)
```
Verify: `readlink ~/repos/AGENT-DIRECTIVE.md`; `test ! -e ~/repos/sync-directive.sh`.

- [ ] **Step 4: Run everything, commit**
```bash
for t in tests/*.sh; do bash "$t" || exit 1; done; python3 scripts/build-index.py
git add -A && git commit -m "docs: directive mastered in claude-common; releases & consumer sync documented

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: First release and first sync (real, outward-facing)

**Files:** none new. Touches: origin of claude-common (tag), 12 consumer remotes (branches + PRs), langtutor-infra (local branch).

- [ ] **Step 1: Push claude-common main** — `git push origin main` (the plan/spec/impl commits). Confirm CI (`.github/workflows` smoke) is green: `gh run list -L1`.
- [ ] **Step 2: Dry-run the real sync** — `scripts/sync-consumers.sh --dry-run` will refuse (no tag yet); so first `scripts/release.sh minor --dry-run` (prints `-> v1.0.0`), then cut it: `scripts/release.sh minor -m "first tagged release; consumer sync"`. Verify `git tag -l` shows `v1.0.0` and `gh release`-less tag exists on origin: `git ls-remote --tags origin v1.0.0`.
- [ ] **Step 3: Dry-run against all 13 consumers** — `scripts/sync-consumers.sh --dry-run 2>&1 | tee state/sync-dryrun.log`. Expected per repo: `would change:` listing `AGENT-DIRECTIVE.md` (identical content → should NOT appear unless the header edit from Task 7 changed it — it did, so it appears), `.claude/commands/{contribute-to-common,triage-discoveries}.md`, `.claude/hooks/common/version-check.sh`, `.claude/settings.json`, `CLAUDE.md`, `.claude/common.lock`. `mix-hunters` and `vault` show a new `CLAUDE.md`. No repo shows unrelated paths. **Stop and show Luis the log if anything unexpected appears.**
- [ ] **Step 4: Real run** — `AUTO_PUSH=1 scripts/sync-consumers.sh 2>&1 | tee state/sync.log`. Expected: 12 lines `<repo>: PR https://github.com/liebanana/<repo>/pull/N`, `langtutor-infra: no remote — branch common/v1.0.0 left local`, `claude-common: self`, exit 0.
- [ ] **Step 5: Status** — `scripts/sync-consumers.sh --status` → all `pr-open #N`, langtutor-infra `no-remote`, claude-common `self v1.0.0`. Report the PR list to Luis for merging. After merges: `--status` shows `current`; open a Claude session in any merged repo and confirm the SessionStart hook prints nothing.

---

### Task 9: Cron

- [ ] **Step 1: Install the weekly line** (Mondays 09:30, after the 09:00 discovery job):
```bash
( crontab -l; echo '30 9 * * 1 AUTO_PUSH=1 /home/luisliev/repos/claude-common/scripts/sync-consumers.sh >> /home/luisliev/repos/claude-common/state/sync.log 2>&1' ) | crontab -
crontab -l | grep -c sync-consumers   # → 1
```
- [ ] **Step 2: Document it** in `CLAUDE.md` "Cron setup" (add the line next to the discover one) and commit:
```bash
git commit -am "docs: weekly consumer-sync cron

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" && git push origin main
```

---

## Self-review notes

- Spec §1 → Tasks 6, 7 (release, master move). §2 → Task 1 + `--discover` in Task 5. §3 → Task 3 (+ Task 2 merge, Task 4 hook). §4 → Task 5. §5 → tests in every task, Task 8 dry-run/real run. Cron → Task 9.
- Names used consistently: `apply_contract SRC DST VERSION REPO`, `apply_block DST VERSION REPO SRC`, `write_lock DST VERSION MANAGED`, branch `common/<tag>`, lock `.claude/common.lock`, env `GH_BIN`, `AUTO_PUSH`, `SYNC_SCRATCH`, `CLAUDE_COMMON_DIR`, `RELEASE_NO_PUSH`.
- Known judgment call: `sync-consumers.sh` resets `common/<tag>` to the base branch on every run (`-B`) and force-pushes with lease; identical content is detected and the old sha kept, so an open PR is not rewritten needlessly.
