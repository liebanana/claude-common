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
- 🟢 **Find new agent/tooling candidates across GitHub + forums (HN, Lobsters, Reddit), merge cross-source signals, dedupe against the ledger** → `scripts/discover.sh` · _discovery, multi-source_
- 🟢 **Run the discovery loop unattended (discover → triage → rebuild index → open a PR)** → `scripts/cron-discover.sh` · _discovery, cron_

## Contribute back
- 🟢 **Scan the current session for a reusable, general learning and open a PR to claude-common** → `.claude/commands/contribute-to-common.md` · _contribution, pr, session_

## Save tokens / work efficiently
- 🟢 **Long/background jobs get reaped — chunk with incremental output and bake into an invokable script** → `docs/long-running-jobs.md` · _practices, reliability, tokens_
- 🟢 **Token-thrift & effectiveness playbook (model choice, scripts-over-reruns, context hygiene)** → `docs/token-thrift.md` · _tokens, practices_

## Index & navigation
- 🟢 **Regenerate index.json + CATALOG.md + research/INDEX.md from asset metadata and the research ledger** → `scripts/build-index.py` · _index, maintenance_

## Reusable Claude Code assets
- 🟢 **Symlink shared commands/agents into ~/.claude (and optionally a target repo)** → `install.sh` · _setup, install_

## From research (adopt)
_✅ = field-tested (trialed/in-use) · 🔬 = readme-verified only — trial before trusting._
- ✅ **Code-intelligence MCP: indexes a repo into a persistent knowledge graph for sub-ms queries so agents query instead of reading files (big token savings, 158 langs)** → `research/DeusData__codebase-memory-mcp.md` (`DeusData/codebase-memory-mcp` ⭐22669) · _trialed_
- 🔬 **Agentic dev methodology (spec to TDD to subagent-driven build) as auto-triggering composable skills; official Claude plugin marketplace** → `research/obra__superpowers.md` (`obra/superpowers` ⭐242371)
- 🔬 **Persistent cross-session memory: captures session activity, AI-compresses it, and injects relevant context into future sessions** → `research/thedotmack__claude-mem.md` (`thedotmack/claude-mem` ⭐85203)
- 🔬 **Claude Code skill/plugin: terse caveman-style output cuts ~75% of OUTPUT tokens while keeping technical accuracy** → `research/JuliusBrussee__caveman.md` (`JuliusBrussee/caveman` ⭐78262)
- 🔬 **Lifecycle slash commands (spec→plan→build→test→review→ship) packaging engineering skills** → `research/addyosmani__agent-skills.md` (`addyosmani/agent-skills` ⭐68155)
- 🔬 **Compress tool outputs/logs/files/RAG before they reach the LLM — 60-95% fewer tokens; library + proxy + MCP server** → `research/headroomlabs-ai__headroom.md` (`headroomlabs-ai/headroom` ⭐54550)
- 🔬 **Archive of leaked system prompts incl. Claude Code + tool defs** → `research/asgeirtj__system_prompts_leaks.md` (`asgeirtj/system_prompts_leaks` ⭐47357)
- 🔬 **Open-source AI memory platform: persistent long-term memory for agents via a self-hosted knowledge graph; ingest any format, recall across sessions** → `research/topoteretes__cognee.md` (`topoteretes/cognee` ⭐26088)
- 🔬 **Curated MCP server catalog + security/sandboxing checklist** → `research/appcypher__awesome-mcp-servers.md` (`appcypher/awesome-mcp-servers` ⭐5655)
- 🔬 **Cut context waste; checkpoint/restore across compaction; live token/$ + context-quality dashboard** → `research/alexgreensh__token-optimizer.md` (`alexgreensh/token-optimizer` ⭐1491)

See [`research/INDEX.md`](research/INDEX.md) for every analyzed repo, and query [`index.json`](index.json) programmatically.
<!-- END GENERATED -->
