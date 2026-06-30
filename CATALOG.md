# CATALOG — what to reach for, by task

> **Agents:** for machine use, query [`index.json`](index.json) (`jq`) — this file is the
> human-readable render of the same data. Both are **generated** by
> `scripts/build-index.py` from per-asset metadata + `research/ledger.jsonl`; don't
> hand-edit below the marker. To add an asset: drop it in the right dir with metadata,
> then run `python3 scripts/build-index.py`.

Legend: 🟢 ready · 🟡 experimental · 🔬 from external research (see `research/`)

---

<!-- BEGIN GENERATED -->
## Discover & adopt external agent tooling
- 🟢 **Analyze new GitHub candidates into research notes + the research ledger** → `.claude/commands/triage-discoveries.md` · _discovery, triage_
- 🟢 **Find new GitHub agent/plugin/MCP repos (search + dedupe against the research ledger)** → `scripts/discover.sh` · _discovery, github_
- 🟢 **Run the discovery loop unattended (discover → triage → rebuild index → open a PR)** → `scripts/cron-discover.sh` · _discovery, cron_

## Contribute back
- 🟢 **Scan the current session for a reusable, general learning and open a PR to claude-common** → `.claude/commands/contribute-to-common.md` · _contribution, pr, session_

## Save tokens / work efficiently
- 🟢 **Token-thrift & effectiveness playbook (model choice, scripts-over-reruns, context hygiene)** → `docs/token-thrift.md` · _tokens, practices_

## Index & navigation
- 🟢 **Regenerate index.json + CATALOG.md + research/INDEX.md from asset metadata and the research ledger** → `scripts/build-index.py` · _index, maintenance_

## Reusable Claude Code assets
- 🟢 **Symlink shared commands/agents into ~/.claude (and optionally a target repo)** → `install.sh` · _setup, install_

## From research (adopt)
- 🔬 **Lifecycle slash commands (spec→plan→build→test→review→ship) packaging engineering skills** → `research/addyosmani__agent-skills.md` (`addyosmani/agent-skills` ⭐68155)
- 🔬 **Compress tool outputs/logs/files/RAG before they reach the LLM — 60-95% fewer tokens; library + proxy + MCP server** → `research/headroomlabs-ai__headroom.md` (`headroomlabs-ai/headroom` ⭐54550)
- 🔬 **Archive of leaked system prompts incl. Claude Code + tool defs** → `research/asgeirtj__system_prompts_leaks.md` (`asgeirtj/system_prompts_leaks` ⭐47357)
- 🔬 **Code-intelligence MCP: indexes a repo into a persistent knowledge graph for sub-ms queries so agents query instead of reading files (big token savings, 158 langs)** → `research/DeusData__codebase-memory-mcp.md` (`DeusData/codebase-memory-mcp` ⭐22669)
- 🔬 **Curated MCP server catalog + security/sandboxing checklist** → `research/appcypher__awesome-mcp-servers.md` (`appcypher/awesome-mcp-servers` ⭐5655)
- 🔬 **Cut context waste; checkpoint/restore across compaction; live token/$ + context-quality dashboard** → `research/alexgreensh__token-optimizer.md` (`alexgreensh/token-optimizer` ⭐1491)

See [`research/INDEX.md`](research/INDEX.md) for every analyzed repo, and query [`index.json`](index.json) programmatically.
<!-- END GENERATED -->
