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
  mkdir -p "$(dirname "$dst")" || return 1
  if [ "$(head -n1 "$src")" = "---" ]; then
    { echo '---'; echo "$CC_MARK"; tail -n +2 "$src"; } > "$dst" || return 1
  else
    { echo '---'; echo "$CC_MARK"; echo '---'; cat "$src"; } > "$dst" || return 1
  fi
}

apply_block() {
  local dst="$1" version="$2" repo="$3" src="$4" f="$1/CLAUDE.md" tmp
  [ -f "$4/templates/claude-md-block.md" ] || { echo "apply_block: missing template in $4" >&2; return 1; }
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
  printf '%s\n' "$managed" | { grep -v '^$' || true; } | LC_ALL=C sort -u \
    | jq -R . | jq -s --arg v "$version" --arg d "$(date -u +%F)" '{version:$v, synced:$d, managed:.}' \
    > "$dst/.claude/common.lock"
}

apply_contract() {
  local src="$1" dst="$2" version="$3" repo="$4"
  [ -f "$src/AGENT-DIRECTIVE.md" ] || { echo "apply_contract: $src is not a claude-common export" >&2; return 1; }
  local managed="" old_managed=""
  [ -f "$dst/.claude/common.lock" ] && old_managed="$(jq -r '.managed[]?' "$dst/.claude/common.lock" 2>/dev/null || true)"

  cp "$src/AGENT-DIRECTIVE.md" "$dst/AGENT-DIRECTIVE.md" \
    || { echo "apply_contract: AGENT-DIRECTIVE.md copy failed for $repo" >&2; return 1; }
  managed+="AGENT-DIRECTIVE.md"$'\n'

  local f rel
  for f in "$src"/.claude/commands/*.md "$src"/.claude/agents/*.md; do
    [ -f "$f" ] || continue; [ "$(basename "$f")" = README.md ] && continue
    rel=".claude/$(basename "$(dirname "$f")")/$(basename "$f")"
    _copy_marked "$f" "$dst/$rel" \
      || { echo "apply_contract: copy of $rel failed for $repo" >&2; return 1; }
    managed+="$rel"$'\n'
  done
  for f in "$src"/hooks/*.sh; do
    [ -f "$f" ] || continue
    rel=".claude/hooks/common/$(basename "$f")"
    mkdir -p "$dst/.claude/hooks/common" && cp "$f" "$dst/$rel" && chmod +x "$dst/$rel" \
      || { echo "apply_contract: hook copy of $rel failed for $repo" >&2; return 1; }
    managed+="$rel"$'\n'
  done

  # settings: baseline merged under repo settings (repo wins)
  mkdir -p "$dst/.claude"
  local cur="$dst/.claude/settings.json" tmp; tmp="$(mktemp)"
  [ -f "$cur" ] || echo '{}' > "$cur"
  jq -s -f "$src/scripts/lib/merge-settings.jq" "$src/templates/settings.baseline.json" "$cur" > "$tmp" \
    || { rm -f "$tmp"; echo "apply_contract: settings merge failed for $repo" >&2; return 1; }
  mv "$tmp" "$cur"

  apply_block "$dst" "$version" "$repo" "$src" \
    || { echo "apply_contract: apply_block failed for $repo" >&2; return 1; }

  # delete previously-managed files that upstream no longer ships (only under managed prefixes)
  local p
  while read -r p; do
    [ -n "$p" ] || continue
    printf '%s\n' "$managed" | grep -qxF "$p" && continue
    case "$p" in .claude/commands/*|.claude/agents/*|.claude/hooks/common/*) rm -f "$dst/$p" ;; esac
  done <<< "$old_managed"

  write_lock "$dst" "$version" "$managed" \
    || { echo "apply_contract: write_lock failed for $repo" >&2; return 1; }
}
