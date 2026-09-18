---
kind: doc
status: ready
group: Harness configuration pitfalls
intent: Never name a user-invocable skill after a Claude Code built-in command — the skill shadows the builtin and makes it unreachable
tags: [skills, slash-commands, claude-code, naming, harness]
---

# Skill naming collisions — a skill named after a builtin shadows it

**When to use:** naming any new user-invocable skill or slash command (`.claude/skills/<name>/`,
`.claude/commands/<name>.md`) in any repo.

## The failure (observed in production, Zonti, 2026-09-18)

A repo skill was named `clear`. Typing `/clear` then invoked the SKILL instead of Claude Code's
built-in `/clear` context-reset — so the user literally could not clear the session: every attempt
re-ran the preparation skill and the context kept growing. The collision is silent: nothing warns
that a builtin is being shadowed, and the skill works fine under its name, so the problem only
surfaces when someone needs the builtin.

## The rule

1. **Never give a user-invocable skill or command the same name as a Claude Code built-in**
   (`clear`, `help`, `config`, `compact`, `init`, `review`, `model`, `fast`, `artifacts`, …).
   Check the CLI's current builtin list when in doubt — it grows over releases, so prefer names
   that could never plausibly become a builtin.
2. If the skill's job is *related* to a builtin, name it by its relationship: `prepare-clear`,
   `pre-compact-checkpoint`, `post-init-audit`. This reads better anyway — the Zonti skill never
   cleared anything; it prepared a safe clear.
3. Keep natural-language triggers independent of the slash name. The model can still respond to a
   user saying the plain word ("clear", "compact safely") via the skill description/CLAUDE.md
   mapping; only the `/name` needs to avoid the collision.

## Renaming an existing collision safely

`git mv .claude/skills/<old> .claude/skills/<new>` → update the frontmatter `name:` → grep the repo
for `skills/<old>` references (CLAUDE.md entrypoints, sibling skills that compose with it) and update
them all in the same commit. Sessions started on other branches keep the old name until they pick up
the rename; note that in the commit message if it matters.
