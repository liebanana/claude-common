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
key="$(basename "$PWD")"   # per-repo flag: caller cd's into either the repo or its scratch worktree, both named after the repo
case "$1 $2" in
  "pr list")   if [ -f "$GH_LOG.created.$key" ]; then echo 7; fi ;;   # mimics `--json number -q '.[0].number'`
  "pr create") touch "$GH_LOG.created.$key"; echo "https://example.test/pr/7" ;;
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
