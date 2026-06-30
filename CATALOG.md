# CATALOG — what to reach for, by task

> **Agents: read this first when planning a task.** This is the index of everything
> `claude-common` provides. Find your intent below, use the linked asset instead of
> building from scratch. If nothing here fits, do the task — then add what you wished
> existed (see [CLAUDE.md](CLAUDE.md) → "Growing the catalog").
>
> Entries are intentionally one line each so the whole map fits in a glance (and a
> small context window). Follow the path for detail.

Legend: 🟢 ready · 🟡 experimental · 🔬 from external research (see `research/`)

---

## Discover & adopt external agent tooling
- 🟢 **Find new GitHub agent/plugin repos** → `scripts/discover.sh` — searches GitHub topics, dedupes against `research/seen.tsv`, writes new candidates.
- 🟢 **Analyze candidates & file them** → `/triage-discoveries` (`.claude/commands/triage-discoveries.md`) — turns raw candidates into `research/*.md` notes + catalog entries.
- 🟢 **Run the whole discovery loop unattended** → `scripts/cron-discover.sh` — discover → triage → commit. Wire to cron (see CLAUDE.md).
- 🔬 **Browse what's already been analyzed** → `research/INDEX.md`.

## Save tokens / work efficiently
- 🟢 **Token-thrift practices** → `docs/token-thrift.md` — model choice, subagents, read/output hygiene, when to hand off to a human.
- 🟢 **Replace a repeated agent command sequence with a script** → add it to `scripts/` (contract: `scripts/README.md`). One deterministic script beats N re-runs.

## Reusable Claude Code assets
- 🟢 **Install shared slash commands / subagents into this host** → `install.sh` — symlinks `.claude/commands/` and `.claude/agents/` into `~/.claude/` (and optionally a target repo).
- 🟡 **Shared subagents** → `.claude/agents/` (see `.claude/agents/README.md`).
- 🟡 **Shared hooks** (formatting, guards) → `hooks/` (see `hooks/README.md`).
- 🟡 **MCP / integration config templates** → `mcp/` (see `mcp/README.md`).

---

_When you add an asset, add its one-liner here under the right intent. The catalog is
the product; the files are the implementation._
