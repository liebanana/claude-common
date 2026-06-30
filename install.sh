#!/usr/bin/env bash
# meta: id=install kind=script group="Reusable Claude Code assets" status=ready tags=setup,install intent="Symlink shared commands/agents into ~/.claude (and optionally a target repo)"
# install.sh — make claude-common's shared assets available on this host.
#
# Symlinks (not copies, so edits propagate) every command/subagent into ~/.claude,
# and optionally into a target repo's .claude/. Re-running is safe (idempotent).
#
#   ./install.sh                 # link .claude/commands + .claude/agents into ~/.claude
#   ./install.sh /path/to/repo   # also link them into <repo>/.claude
#
# Scripts in scripts/ are meant to be run by path or put on PATH yourself:
#   export PATH="$HOME/repos/claude-common/scripts:$PATH"
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_dir() {  # link_dir <src_subdir> <dest_dir>
  local from="$SRC/$1" to="$2"
  [ -d "$from" ] || return 0
  mkdir -p "$to"
  shopt -s nullglob
  for f in "$from"/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    ln -sfn "$f" "$to/$(basename "$f")"
    echo "  linked $(basename "$f") -> $to"
  done
  shopt -u nullglob
}

echo "claude-common: installing into ~/.claude"
link_dir .claude/commands "$HOME/.claude/commands"
link_dir .claude/agents   "$HOME/.claude/agents"

if [ "${1:-}" != "" ]; then
  target="${1%/}"
  [ -d "$target" ] || { echo "target repo not found: $target" >&2; exit 1; }
  echo "claude-common: installing into $target/.claude"
  link_dir .claude/commands "$target/.claude/commands"
  link_dir .claude/agents   "$target/.claude/agents"
fi

echo "Done. (Scripts: add scripts/ to PATH if you want them by name.)"
