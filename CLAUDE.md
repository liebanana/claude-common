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

**Read [`CATALOG.md`](CATALOG.md) before planning a task.** It maps task intent → the
existing asset that handles it. If something fits, use it instead of building from
scratch. If nothing fits and you end up solving it yourself, **add what you wished
existed** (see "Growing the catalog"). CATALOG.md is deliberately one line per asset so
the whole map fits a small context window.

## Architecture

```
CATALOG.md            ★ intent → asset index. The entry point for any agent.
docs/token-thrift.md    durable practices (model choice, scripts-over-rereruns, hygiene)
.claude/commands/     slash commands (auto-discovered here; /triage-discoveries lives here)  ─┐
.claude/agents/       subagents (auto-discovered here)                                       ├─ install.sh
hooks/                shareable hook scripts (wired via settings.json)                        │   symlinks
mcp/                  MCP / integration templates                                             ┘   cmds+agents
.claude/settings.json scoped permission allowlist for the headless triage run
scripts/              deterministic helpers (replace repeated agent command sequences)
research/             external repos analyzed by the discovery engine
  INDEX.md              one line per analyzed repo
  seen.tsv              dedup ledger (every repo ever triaged)
  <owner>__<repo>.md    per-repo note + verdict
state/                runtime logs (gitignored)
```

Three things wire together into the **discovery engine** (how the repo learns on its
own):

1. `scripts/discover.sh` — searches GitHub (REST API via `curl`+`jq`, **no `gh`
   dependency**; optional `$GITHUB_TOKEN`) for agent/plugin/MCP repos, dedupes against
   `research/seen.tsv`, writes new candidates to `research/_candidates.tsv`.
2. `.claude/commands/triage-discoveries.md` (`/triage-discoveries`) — an agent reads the
   candidates, analyzes each (what it is, what's reusable, token angle, how to adopt),
   writes `research/*.md` + `CATALOG.md`/`INDEX.md`/`seen.tsv` entries.
3. `scripts/cron-discover.sh` — chains discover → headless `claude -p /triage-discoveries`
   → `git commit`. This is what cron runs.

Both a cron job **and** an interactive agent use the same pieces — nothing is
cron-only.

## Commands

```bash
./install.sh [/path/to/repo]      # symlink commands + agents into ~/.claude (+ a repo)
bash scripts/discover.sh          # find new candidate repos (prints count; writes _candidates.tsv)
MIN_STARS=100 bash scripts/discover.sh   # tune: MIN_STARS, PUSHED_SINCE, PER_PAGE, QUERIES
bash scripts/cron-discover.sh     # full unattended loop (discover→triage→commit). AUTO_PUSH=1 to push
/triage-discoveries               # (in a Claude session) analyze the current candidates
```

There is no build/test suite — assets are scripts and Markdown. Validate a shell script
with `bash -n scripts/<name>.sh` before committing; smoke-test `discover.sh` by running
it (it's read-only against GitHub).

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
- It **commits but does not push** by default. Set `AUTO_PUSH=1` (the installed cron
  uses it) once an `origin` remote exists and you trust the loop.
- The triage step runs plain `claude -p "/triage-discoveries"` — permissions are **not**
  bypassed. `.claude/settings.json` pre-allows exactly the tools triage needs
  (Read/Write/Edit, `curl`, the discover script, candidates cleanup) and denies
  `git push` + reading `.env`. Anything else is auto-denied headless, so a malicious
  candidate README can't escalate. `git push` is done by the wrapper, not the agent.

## Growing the catalog (do this — it's the point)

When you build or discover something reusable:
1. Put the asset in the right dir (`scripts/`, `commands/`, `agents/`, `hooks/`, `mcp/`).
2. Add **one line** to `CATALOG.md` under the matching intent.
3. For external repos, file a `research/<owner>__<repo>.md` note and update
   `research/INDEX.md` + `research/seen.tsv`.
4. Keep entries terse and honest — mark experimental/untested assets as such.

## Conventions

- **No secrets, ever** (public repo). Placeholders + documented env vars only.
- Scripts follow the contract in `scripts/README.md` (self-documenting, idempotent,
  non-zero exit on failure, no secrets).
- Prefer Bash; use Python/other when it genuinely fits better.
- Token thrift always — this repo exists to save tokens, so practice what it preaches
  (see `docs/token-thrift.md`).
