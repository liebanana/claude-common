# claude-common

A **self-growing toolkit for working with Claude Code and AI agents** — shared scripts,
slash commands, subagents, hooks, MCP templates, and a living playbook that make agent
work more effective and cheaper in tokens.

It is **agent-first, human-second**: structured so an agent planning a task can find the
right tool fast — but written so a human understands it too.

**Agents: start with [`AGENTS.md`](AGENTS.md)** — one screen, tells you how to find an
asset and how to contribute, no further input needed.

## How to use it

1. **Planning a task? Check what exists first.** Query the generated machine index:
   ```bash
   jq -r '.assets[]|"\(.path) — \(.intent)"' index.json   # or read CATALOG.md (human)
   ```
   Use the linked asset instead of starting from scratch.
2. **Install the shared assets** on your host:
   ```bash
   ./install.sh                 # symlink commands + agents into ~/.claude
   ./install.sh /path/to/repo   # also into a specific repo's .claude/
   export PATH="$PWD/scripts:$PATH"   # optional: scripts by name
   ```
3. **Contribute back.** From *any* repo, `/contribute-to-common` scans your session for a
   reusable, general learning and opens a PR here. Or add the asset + metadata by hand and
   run `python3 scripts/build-index.py`.

## The discovery engine

`claude-common` keeps learning two ways, both feeding one `research/ledger.jsonl`:

```
# 1. crawl the ecosystem (unattended, weekly cron) — multi-source
scripts/discover.sh        # GitHub + Hacker News + Lobsters + Reddit(opt); merges sources,
                           # keeps tools w/ signals (stars/points/score/age) -> _candidates.jsonl
  -> /triage-discoveries   # analyze each: verdict + maturity (stable/trending/emerging)
  -> research/ledger.jsonl + notes ; build-index.py regenerates index.json + CATALOG.md
scripts/cron-discover.sh   # chains the above + opens a PR; run weekly from cron

# 2. reflect on a working session (any repo, on demand)
/contribute-to-common      # finds a general learning in this session -> opens a PR here
```

Each tracked tool records **where it was seen** (`sources`), its **buzz** (`signals`), and
a **maturity** tag, so you can query `index.json` for the stable vs the new/trending.

`index.json`, `CATALOG.md`, and `research/INDEX.md` are **generated** by
`build-index.py`; edit the source (asset metadata / `ledger.jsonl`), never them.
See [`CLAUDE.md`](CLAUDE.md) for the full architecture and cron setup.

## Public repo — no secrets

Anyone (human or agent) can clone and use this — [MIT licensed](LICENSE). **Never commit
tokens, private endpoints, or org-specific data.** MCP/config files use placeholders only.

## Layout

| Path | What |
|-----|------|
| `AGENTS.md` | agent bootstrap — read first |
| `index.json` | **generated** machine index (query with `jq`) |
| `CATALOG.md` | **generated** human render of the index |
| `.claude/commands/` | slash commands (`/triage-discoveries`, `/contribute-to-common`) |
| `.claude/agents/` | subagents |
| `hooks/` | shareable Claude Code hooks |
| `scripts/` | deterministic helpers (`build-index.py`, `discover.sh`, …) |
| `mcp/` | MCP / integration config templates |
| `docs/` | token-thrift & ways-of-working playbook |
| `research/` | analyzed external repos (`ledger.jsonl` = source; `INDEX.md` + notes = views) |
