#!/usr/bin/env bash
# End-to-end: fake root with 5 repos, fake tagged claude-common clone, fake gh. No network.
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

# fake root: a (remote, CLAUDE.md, dirty file), b (no CLAUDE.md), c (worktree of a), d (no remote),
# e (remote, but a rejecting pre-commit hook — worktrees share the parent repo's hooks)
ROOT="$T/root"; mkdir -p "$ROOT" "$T/remotes"
mkrepo() { git init -q -b main "$ROOT/$1"; ( cd "$ROOT/$1" && echo "# $1" > README.md && git add -A && git commit -qm init ); }
mkrepo a; mkrepo b; mkrepo d; mkrepo e
( cd "$ROOT/a" && printf '# A\n\n@AGENT-DIRECTIVE.md\n\nlocal rules\n' > CLAUDE.md && git add -A && git commit -qm claude \
  && git init -q --bare "$T/remotes/a.git" && git remote add origin "$T/remotes/a.git" && git push -q -u origin main \
  && git remote set-head origin main && echo dirty > dirty.txt )
( cd "$ROOT/b" && git init -q --bare "$T/remotes/b.git" && git remote add origin "$T/remotes/b.git" && git push -q -u origin main && git remote set-head origin main )
( cd "$ROOT/e" && git init -q --bare "$T/remotes/e.git" && git remote add origin "$T/remotes/e.git" && git push -q -u origin main && git remote set-head origin main )
mkdir -p "$ROOT/e/.git/hooks"; printf '#!/usr/bin/env bash\nexit 1\n' > "$ROOT/e/.git/hooks/pre-commit"; chmod +x "$ROOT/e/.git/hooks/pre-commit"
git -C "$ROOT/a" worktree add -q "$ROOT/c" -b wt-branch
cat > "$T/manifest.json" <<EOF
{"root":"$ROOT","exclude":["zzz"],"consumers":[{"repo":"a","mode":"pr"},{"repo":"b","mode":"pr"},{"repo":"c","mode":"pr"},{"repo":"d","mode":"pr"},{"repo":"e","mode":"pr"},{"repo":"common","mode":"self"}]}
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
echo "$out" > "$T/run1.log"; assert_eq "$rc" 1 "run1 rc"   # e's pre-commit hook fails, others still succeed
assert_grep 'a: PR https://example.test/pr/7' "$T/run1.log"
assert_grep 'c: skip \(worktree\)' "$T/run1.log"
assert_grep 'd: no remote — branch common/v9.9.9 left local' "$T/run1.log"
assert_grep 'e: commit failed' "$T/run1.log"
assert_grep 'common: self' "$T/run1.log"
git -C "$T/remotes/a.git" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null || _fail "a branch not pushed"
git -C "$T/remotes/b.git" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null || _fail "b branch not pushed"
git -C "$ROOT/d" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null || _fail "d local branch missing"
git -C "$T/remotes/e.git" rev-parse -q --verify refs/heads/common/v9.9.9 >/dev/null 2>&1 && _fail "e branch pushed despite failed commit"
assert_file "$ROOT/a/dirty.txt"; assert_not_file "$ROOT/a/AGENT-DIRECTIVE.md"   # user tree untouched
assert_eq "$(git -C "$ROOT/a" rev-parse --abbrev-ref HEAD)" "main" "a still on main"
git -C "$ROOT/a" show common/v9.9.9:.claude/common.lock | jq -e '.version=="v9.9.9"' >/dev/null || _fail "lock on branch"
assert_eq "$(git -C "$ROOT/a" show common/v9.9.9:CLAUDE.md | grep -c '^@AGENT-DIRECTIVE.md$')" "1" "single import on branch"
git -C "$ROOT/b" show common/v9.9.9:CLAUDE.md | grep -q '^# b$' || _fail "b scaffolded CLAUDE.md"
assert_grep '^pr create' "$GH_LOG"
[ -z "$(ls -A "$C/state/sync-wt" 2>/dev/null)" ] || _fail "scratch worktrees not cleaned"
# second run: branches unchanged, no new push, PR reused. Run it under a `date` shim that reports
# a different day, to prove the lock's synced date comes from the target tag's commit date (I1),
# not wall-clock `date` — otherwise every weekly run would rewrite every already-open PR branch.
sha_before=$(git -C "$ROOT/a" rev-parse common/v9.9.9)
# Shim goes in $HOME/.local/bin (with HOME redirected to $T), not just prepended to $PATH: the
# script itself forces /usr/local/bin:/usr/bin:/bin ahead of whatever PATH it inherits (I2, so
# cron's minimal PATH still finds gh/git), which would otherwise shadow a plain $T/bin shim and
# make this test pass for the wrong reason (real `date` never even reached).
mkdir -p "$T/.local/bin"; printf '#!/usr/bin/env bash\necho 2099-01-01\n' > "$T/.local/bin/date"; chmod +x "$T/.local/bin/date"
out=$(HOME="$T" AUTO_PUSH=1 bash "$S" --manifest "$T/manifest.json" 2>&1); assert_eq "$?" 1 "run2 rc"   # e still fails every run
assert_eq "$(git -C "$ROOT/a" rev-parse common/v9.9.9)" "$sha_before" "run2 did not rewrite branch"
assert_grep 'a: pr-open #7 \(unchanged\)' <(echo "$out")
assert_eq "$(grep -c '^pr create' "$GH_LOG")" "2" "no third pr create (a,b once each)"
# --status after
out=$(bash "$S" --manifest "$T/manifest.json" --status); assert_grep '^a[[:space:]].*pr-open #7' <(echo "$out"); assert_grep '^d[[:space:]].*no-remote' <(echo "$out")

# --- C1: force-with-lease must be pinned to the sha we last pushed, not neutralized by a
# pre-push fetch. Simulate a reviewer pushing a commit directly onto a's PR branch.
git clone -q "$T/remotes/a.git" "$T/reviewer" >/dev/null 2>&1
( cd "$T/reviewer" && git checkout -q common/v9.9.9 && echo reviewer >> README.md \
  && git commit -qam reviewer && git push -q origin common/v9.9.9 )
reviewer_sha=$(git -C "$T/reviewer" rev-parse HEAD)
# 1) content we'd produce is identical to what's already on the branch locally -> the
#    "(unchanged)" short-circuit fires and never touches the remote at all (sanity baseline).
out=$(AUTO_PUSH=1 bash "$S" --manifest "$T/manifest.json" --repo a 2>&1); assert_eq "$?" 0 "lease-1 rc (unchanged short-circuit)"
assert_grep 'a: pr-open #7 \(unchanged\)' <(echo "$out")
assert_eq "$(git -C "$T/remotes/a.git" rev-parse refs/heads/common/v9.9.9)" "$reviewer_sha" "reviewer commit survives (unchanged short-circuit)"
# 2) force a real push attempt: drop the local branch ref so $prev is empty and the lease can't
#    be pinned to a known sha. A fetch-then-push would refresh the stale remote-tracking ref and
#    let a plain --force-with-lease clobber the reviewer's commit; without the fetch, the lease is
#    checked against our stale local knowledge of the remote and git must refuse the push.
git -C "$ROOT/a" branch -D common/v9.9.9 >/dev/null
out=$(AUTO_PUSH=1 bash "$S" --manifest "$T/manifest.json" --repo a 2>&1); assert_eq "$?" 1 "lease-2 rc (push refused)"
assert_grep 'a: push failed' <(echo "$out")
assert_eq "$(git -C "$T/remotes/a.git" rev-parse refs/heads/common/v9.9.9)" "$reviewer_sha" "reviewer commit still survives (lease refused)"

# merge a's PR (fast-forward main) → status current, run is a no-op
( cd "$ROOT/a" && git merge -q --ff-only common/v9.9.9 && git push -q origin main )
# I5: --status must read the pin from origin/<default-branch> when available, not just the local
# branch, so a repo whose local branch hasn't advanced still resolves correctly. Drop b's fake-PR
# flag (pr list now returns nothing for b) so its state falls through to branch-local.
rm -f "$GH_LOG.created.b"
out=$(bash "$S" --manifest "$T/manifest.json" --status); assert_grep '^a[[:space:]].*current' <(echo "$out")
assert_grep '^b[[:space:]].*branch-local' <(echo "$out")

# I5, genuine origin-vs-local check: simulate b's PR having been merged upstream via the GitHub UI
# (a push straight to the bare remote's main, never touching $ROOT/b's local main) plus a prior
# `sync` invocation having already fetched it (this is what updates refs/remotes/origin/main;
# --status itself must never fetch). Reading the local main (stale, no lock) would still say
# branch-local/behind; reading origin/main (has the merged lock at v9.9.9) must say current.
git clone -q "$T/remotes/b.git" "$T/reviewer-b" >/dev/null 2>&1
( cd "$T/reviewer-b" && mkdir -p .claude \
  && printf '{"version":"v9.9.9","synced":"2020-01-01","managed":[]}' > .claude/common.lock \
  && git add -A && git commit -qm "external merge" && git push -q origin main )
git -C "$ROOT/b" fetch -q origin main
out=$(bash "$S" --manifest "$T/manifest.json" --status); assert_grep '^b[[:space:]].*current' <(echo "$out")
finish sync-smoke
