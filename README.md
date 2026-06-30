# claude-common

A **self-growing toolkit for working with Claude Code and AI agents** — shared scripts,
slash commands, subagents, hooks, MCP templates, and a living playbook that make agent
work more effective and cheaper in tokens.

It is **agent-first, human-second**: structured so an agent planning a task can find the
right tool fast — but written so a human understands it too.

## How to use it

1. **Planning a task? Read [`CATALOG.md`](CATALOG.md) first.** It maps intent → the
   asset that already solves it, so you don't start from scratch.
2. **Install the shared assets** on your host:
   ```bash
   ./install.sh                 # symlink commands + agents into ~/.claude
   ./install.sh /path/to/repo   # also into a specific repo's .claude/
   export PATH="$PWD/scripts:$PATH"   # optional: scripts by name
   ```
3. **Grow it.** When you do something an agent shouldn't have to re-figure-out, add a
   script/command/doc and a one-line `CATALOG.md` entry.

## The discovery engine

`claude-common` keeps learning from the ecosystem on its own:

```
scripts/discover.sh        # search GitHub for new agent/plugin/MCP repos (curl+jq, no gh)
  -> /triage-discoveries   # an agent analyzes each: what it is, what's reusable, how to adopt
  -> research/*.md         # durable notes + verdicts (adopt / watch / skip)
scripts/cron-discover.sh   # chains the above + commits; run weekly from cron
```

See [`CLAUDE.md`](CLAUDE.md) for the architecture and the cron setup.

## Public repo — no secrets

Anyone (human or agent) can clone and use this. **Never commit tokens, private
endpoints, or org-specific data.** MCP/config files use placeholders only.

## Layout

| Dir | What |
|-----|------|
| `commands/` | shareable slash commands |
| `agents/` | shareable subagents |
| `hooks/` | shareable Claude Code hooks |
| `scripts/` | deterministic helpers (replace repeated agent re-runs) |
| `mcp/` | MCP / integration config templates |
| `docs/` | token-thrift & ways-of-working playbook |
| `research/` | analyzed external repos (`INDEX.md`, per-repo notes, `seen.tsv` ledger) |
