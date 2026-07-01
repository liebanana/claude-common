# AGENTS.md — start here (agent bootstrap)

You are an agent with access to **claude-common**: a shared, public, self-growing
toolkit for working with Claude Code / agents more effectively and with fewer tokens.
This file is all you need to start using and improving it. No further instructions
required.

## Using it (do this when planning a task)
1. **Check what already exists before building anything.** Query the machine index:
   ```bash
   jq -r '.assets[] | "\(.status) \(.path) — \(.intent) [\(.tags|join(","))]"' index.json
   jq -r '.assets[]|select(.tags|index("tokens"))|.path' index.json   # filter by tag
   jq -r '.research[]|select(.verdict=="adopt")|"\(.repo): \(.intent)"' index.json
   # external tools, sliced by maturity / buzz / corroboration:
   jq -r '.research[]|select(.maturity=="stable")|.repo' index.json    # battle-tested
   jq -r '.research[]|select(.maturity=="trending")|.repo' index.json  # new & hot
   jq -r '.research[]|select((.sources|length)>1)|"\(.repo) \(.sources)"' index.json  # seen on multiple sources
   ```
   Each research record carries `source`/`sources` (github, github-trending, hackernews, lobsters, reddit),
   `signals` (stars/points/score/comments/repo_age_days/seen_age_days), `maturity`, and a
   lifecycle `status` (`recommended` = readme-verified only; `trialed`/`in-use` =
   field-tested; `rejected` = tried and dropped). Trust field-tested over readme-only:
   `jq -r '.research[]|select(.status=="in-use" or .status=="trialed")|.repo' index.json`
   (`CATALOG.md` is the same data as readable markdown if you prefer prose.)
2. **Use it or surface it — never silently skip, never reinvent.** For each relevant asset:
   - **Fits the task perfectly** → just use it (follow its `path`).
   - **Relevant but adoption needs a step you shouldn't take unilaterally** — installing a
     plugin, running/setting up a script, adding an MCP server, or pulling in an external
     tool from `research/` (verdict `adopt`/`watch`) — **recommend it to the user**: name
     the asset, say what it does and why it fits, and give the one step to adopt it. Then
     let them decide.
   - **Do not rebuild** something this repo already provides without first telling the user
     it exists.
3. Token discipline lives in `docs/token-thrift.md` — apply it always.

## Improving it (do this when you learn something reusable)
If you build or discover something that would help **any** project — a script that
replaced repeated commands, a slash command/hook, a token-saving trick, a recurring-
mistake fix, or a genuinely useful external tool — **contribute it back as a PR**:
```
/contribute-to-common            # works from any repo; scans this session → opens a PR
```
Or do it by hand: add the asset (with metadata), run `python3 scripts/build-index.py`,
then open a PR. Never push to `main` directly from another project.

## Non-negotiables
- **Public repo → no secrets, ever.** Sanitize paths, tokens, internal URLs, proprietary
  logic to placeholders, or don't contribute it.
- **`index.json`, `CATALOG.md`, `research/INDEX.md` are generated** — never hand-edit;
  edit the source (asset metadata / `research/ledger.jsonl`) and rerun `build-index.py`.
- Only contribute things that **generalize** across projects.

## Map
- `index.json` — machine index (query this). `CATALOG.md` — human render.
- `.claude/commands/`, `.claude/agents/` — shareable commands/subagents (`install.sh` links them globally).
- `scripts/` — deterministic helpers. `docs/` — playbooks. `hooks/`, `mcp/` — shareable configs.
- `research/` — external repos analyzed (`ledger.jsonl` = source, `INDEX.md`/notes = views).
- `CLAUDE.md` — full architecture + rationale.
