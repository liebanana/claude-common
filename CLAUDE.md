# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENT-DIRECTIVE.md

## What this repo is

`claude-common` is a **self-growing, agent-first toolkit** for working with Claude Code
and AI agents more effectively and with fewer tokens. It holds shared scripts, slash
commands, subagents, hooks, MCP templates, a token-thrift playbook, and a research
ledger of external agent tooling. It is a **public repo** — anyone (human or agent) can
clone it, so **no secrets ever** (use placeholders + env vars).

The product is the **knowledge map**, not any single file: an agent should be able to
land here, find the right asset for its task, and avoid re-deriving things.

## The one rule that drives everything

**Before planning a task, check what already exists** — query `index.json` with `jq`
(agents) or read [`CATALOG.md`](CATALOG.md) (humans); [`AGENTS.md`](AGENTS.md) is the
one-screen bootstrap with the exact query patterns. If an asset fits, use it instead of
building from scratch. If nothing fits and you solve it yourself, **add what you wished
existed** (see "Growing the catalog") — or from another repo, `/contribute-to-common`.

## Architecture

The repo is **two-way**: agents *consume* it (find the right asset) and *contribute* to
it (open PRs). Both revolve around a **generated index**.

```
AGENTS.md             ★ agent bootstrap — how to consume + contribute, zero further input
index.json            ★ GENERATED machine index — agents query with jq
CATALOG.md              GENERATED human render of index.json (body between markers)
docs/token-thrift.md    durable practices (model choice, scripts-over-reruns, hygiene)
.claude/commands/     slash commands (auto-discovered; /triage-discoveries, /contribute-to-common)  ─┐
.claude/agents/       subagents (auto-discovered)                                                   ├─ install.sh
hooks/                shareable hook scripts (wired via settings.json)                               │   symlinks
mcp/                  MCP / integration templates                                                   ┘   cmds+agents
.claude/settings.json scoped permission allowlist for the headless triage run
scripts/              deterministic helpers; build-index.py regenerates the index
research/             external repos analyzed by the discovery engine
  ledger.jsonl          ★ SOURCE of truth (one JSON record per repo; dedup + index feed)
  INDEX.md              GENERATED human view of the ledger
  <owner>__<repo>.md    per-repo prose note
state/                runtime logs (gitignored)
```

### The index (single source → generated views)
Assets carry inline **metadata** — `.md` frontmatter (`kind/status/group/intent/tags`)
or a `# meta:` line in scripts. `research/ledger.jsonl` holds one structured record per
analyzed repo. `scripts/build-index.py` reads both and regenerates `index.json` (machine),
`CATALOG.md` body, and `research/INDEX.md`. **Never hand-edit the three generated files**
— edit the source and rerun `build-index.py`. Agents find assets with `jq` over
`index.json` (see `AGENTS.md` for query patterns); that's far cheaper than reading prose.

### Discovery engine (how the repo learns)
Two front-ends feed the same ledger/index:
1. **GitHub crawl** — `scripts/discover.sh` searches GitHub (REST via `curl`+`jq`, **no
   `gh` dep**; optional `$GITHUB_TOKEN`), dedupes against `research/ledger.jsonl`, writes
   `research/_candidates.tsv`. `/triage-discoveries` analyzes each → prose note + a
   `ledger.jsonl` line, then runs `build-index.py`. `scripts/cron-discover.sh` chains
   discover → headless `claude -p /triage-discoveries` → rebuild index → **open a PR**
   (on a `discover/<timestamp>` branch; never pushes to the default branch).
2. **Session reflection** — `/contribute-to-common` runs in **any** repo, finds a
   reusable/general learning from the current session, adds it (with metadata), rebuilds
   the index, and opens a **PR**. Installed globally by `install.sh`, so it's available
   everywhere — that's how other projects feed knowledge back.

Both a cron job **and** an interactive agent use the same pieces — nothing is cron-only.

## Commands

```bash
./install.sh [/path/to/repo]      # symlink commands + agents into ~/.claude (+ a repo)
python3 scripts/build-index.py    # regenerate index.json + CATALOG.md + research/INDEX.md
jq -r '.assets[]|"\(.path) — \(.intent)"' index.json   # how an agent finds an asset
bash scripts/discover.sh          # find new candidate repos (prints count; writes _candidates.tsv)
MIN_STARS=100 bash scripts/discover.sh   # tune: MIN_STARS, PUSHED_SINCE, PER_PAGE, QUERIES
bash scripts/cron-discover.sh     # full unattended loop (discover→triage→index→PR). AUTO_PUSH=1 to push+PR
/triage-discoveries               # (in a Claude session) analyze the current candidates
/contribute-to-common             # (from any repo) package a session learning → PR here
```

There is no build/test suite — assets are scripts and Markdown. Always run
`build-index.py` after changing an asset or the ledger (the cron/triage do this). Validate
a shell script with `bash -n scripts/<name>.sh`; sanity-check `index.json`/ledger with `jq`.

## Cron setup (the discovery job)

Weekly is plenty. Add to `crontab -e` (matches the existing workspace pattern of a
wrapper script that logs):

```cron
0 9 * * 1 /home/luisliev/repos/claude-common/scripts/cron-discover.sh >> /home/luisliev/repos/claude-common/state/discover.log 2>&1
```

- **Prerequisite:** the headless triage only honors `.claude/settings.json` if this
  workspace is **trusted**. Trust it once (interactively accept the trust dialog when you
  first run `claude` here, or set
  `projects["<repo path>"].hasTrustDialogAccepted: true` in `~/.claude.json`). Until
  trusted, the run logs "Ignoring N permissions.allow entries" and `/triage-discoveries`
  won't be found.
- `cron-discover.sh` prepends `~/.local/bin` to PATH (cron's PATH omits it, where the
  `claude` CLI lives) and runs the triage under a hard `timeout`.
- It **opens a PR, never pushes to the default branch.** Changes land on a
  `discover/<timestamp>` branch and `gh pr create` opens a reviewable PR. `AUTO_PUSH=1`
  (the installed cron sets it) enables push + PR; unset/0 leaves the commit on a local
  branch only. Needs `origin` + an authed `gh`.
- The triage step runs plain `claude -p "/triage-discoveries"` — permissions are **not**
  bypassed. `.claude/settings.json` pre-allows exactly the tools triage needs
  (Read/Write/Edit, `curl`, the discover script, `build-index.py`, candidates cleanup)
  and denies `git push` + reading `.env`. Anything else is auto-denied headless, so a
  malicious candidate README can't escalate. Branching/commit/push/PR are done by the
  wrapper, not the agent.

## Growing the catalog (do this — it's the point)

When you build or discover something reusable:
1. Put the asset in the right dir (`scripts/`, `.claude/commands/`, `.claude/agents/`,
   `hooks/`, `mcp/`) **with metadata** (`.md` frontmatter or a `# meta:` line).
2. For external repos, append a `research/ledger.jsonl` record and write the prose note.
3. Run `python3 scripts/build-index.py` — it regenerates `index.json`, `CATALOG.md`, and
   `research/INDEX.md`. Never hand-edit those three.
4. From another project, just run `/contribute-to-common` — it does all of the above and
   opens a PR. Keep entries terse and honest — mark experimental/untested assets as such.

## Conventions

- **No secrets, ever** (public repo). Placeholders + documented env vars only.
- Scripts follow the contract in `scripts/README.md` (self-documenting, idempotent,
  non-zero exit on failure, no secrets).
- Prefer Bash; use Python/other when it genuinely fits better.
- Token thrift always — this repo exists to save tokens, so practice what it preaches
  (see `docs/token-thrift.md`).
