#!/usr/bin/env bash
# meta: id=push-guard kind=hook group="Reusable Claude Code assets" status=ready tags=hook,git,pretooluse,parallel-sessions intent="PreToolUse(Bash) hook: block git push when origin/<branch> has commits HEAD lacks (another session pushed to the same branch)"
# push-guard.sh — wire as PreToolUse/Bash. Exit 2 blocks the push when origin/<branch> advanced and HEAD does not contain it.
# Any failure of the hook itself (no network, branch missing remotely, odd JSON) exits 0: it never blocks by error.
# Note: it checks BEFORE the command runs, so "git pull --rebase && git push" in one command is still blocked; run them separately.
set -u

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  cmd=$(printf '%s' "$input" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass' 2>/dev/null)
fi
[ -n "$cmd" ] || exit 0

printf '%s\n' "$cmd" | grep -Eq '(^|[;&| ])git( -C [^ ]+)? push( |$)' || exit 0

# Argumentos de push: lo que sigue a "push" hasta el siguiente separador de shell.
seg=$(printf '%s\n' "$cmd" | grep -oE 'git( -C [^ ]+)? push[^;&|]*' | head -1)
push_args=${seg#*push}

# Refspec de destino: el lado derecho de "<origen>:<rama>" (HEAD:main -> main).
rama=""
read -r -a toks <<< "$push_args"
for tok in "${toks[@]+"${toks[@]}"}"; do
  case $tok in
    -*) ;;
    *:*) rama=${tok#*:} ;;
  esac
done
rama=${rama#refs/heads/}

if [ -z "$rama" ]; then
  rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
  [ -n "$rama" ] && [ "$rama" != "HEAD" ] || exit 0
fi

git rev-parse -q --verify HEAD >/dev/null 2>&1 || exit 0
GIT_TERMINAL_PROMPT=0 git fetch -q origin "$rama" >/dev/null 2>&1 || exit 0

git merge-base --is-ancestor FETCH_HEAD HEAD && exit 0

n=$(git rev-list --count HEAD..FETCH_HEAD 2>/dev/null)
{
  echo "origin/$rama moved: $n commit(s) your HEAD does not have:"
  git log --oneline HEAD..FETCH_HEAD 2>/dev/null | head -10
  echo "Files changed there:"
  git diff --stat=90 HEAD...FETCH_HEAD 2>/dev/null | tail -15
  echo "Rebase (in a separate command), check those changes against what you are about to push, then push."
} >&2
exit 2
