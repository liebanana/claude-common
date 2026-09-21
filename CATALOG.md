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
- 🟢 **Drive Google Stitch programmatically via mcp__stitch__* tools (design system + screen generation) instead of the web UI, with the token-cost trap and error-handling gotchas that aren't obvious from the tool schemas** → `docs/stitch-mcp-workflow.md` · _stitch, mcp, design-system, tokens_
- 🟢 **Long/background jobs get reaped — chunk with incremental output and bake into an invokable script** → `docs/long-running-jobs.md` · _practices, reliability, tokens_
- 🟢 **Token-thrift & effectiveness playbook (model choice, scripts-over-reruns, context hygiene)** → `docs/token-thrift.md` · _tokens, practices_

## Index & navigation
- 🟢 **Bring every consumer repo to the latest tagged claude-common release via one PR per repo (status/dry-run/discover modes)** → `scripts/sync-consumers.sh` · _sync, release, pr, cron_
- 🟢 **Cut a tagged claude-common release: rotate CHANGELOG, write self lock + CLAUDE.md block, rebuild index, tag vX.Y.Z, push** → `scripts/release.sh` · _release, tag, changelog_
- 🟢 **Regenerate index.json + CATALOG.md + research/INDEX.md from asset metadata and the research ledger** → `scripts/build-index.py` · _index, maintenance_

## Reusable Claude Code assets
- 🟡 **Give an agent live control of Chrome DevTools (traces, network/console inspection, Puppeteer automation) via MCP** → `mcp/chrome-devtools-mcp.md` · _mcp, browser, debugging_
- 🟢 **Pause/resume ritual for long autonomous lanes — nothing needed by the next session lives in a scratchpad, a monitor or chat** → `.claude/commands/session-handover.md` · _handover, context-clear, resume, durability, orchestration_
- 🟢 **SessionStart hook: warn when the repo's pinned claude-common version is behind the newest local tag** → `hooks/version-check.sh` · _hook, session-start, sync_
- 🟢 **Structured, agent-emitted project status that a cross-project board can trust — never inferred from prose** → `.claude/commands/oracle-status.md` · _status, handover, oracle, coordination_
- 🟢 **Symlink shared commands/agents into ~/.claude (and optionally a target repo)** → `install.sh` · _setup, install_

## Debugging techniques
- 🟢 **Prove/disprove phantom-scroll & layout-void bugs in Next.js/Tailwind apps without auth, dev servers, or browser installs** → `docs/layout-measure-repro.md` · _debugging, css, playwright, nextjs, layout_

## Harness configuration pitfalls
- 🟢 **Never name a user-invocable skill after a Claude Code built-in command — the skill shadows the builtin and makes it unreachable** → `docs/skill-naming-collisions.md` · _skills, slash-commands, claude-code, naming, harness_

## From research (adopt)
_✅ = field-tested (trialed/in-use) · 🔬 = readme-verified only — trial before trusting._
- ✅ **Code-intelligence MCP: indexes a repo into a persistent knowledge graph for sub-ms queries so agents query instead of reading files (big token savings, 158 langs)** → `research/DeusData__codebase-memory-mcp.md` (`DeusData/codebase-memory-mcp` ⭐22669) · _trialed_
- 🔬 **Agentic dev methodology (spec to TDD to subagent-driven build) as auto-triggering composable skills; official Claude plugin marketplace** → `research/obra__superpowers.md` (`obra/superpowers` ⭐242371)
- 🔬 **Persistent cross-session memory: captures session activity, AI-compresses it, and injects relevant context into future sessions** → `research/thedotmack__claude-mem.md` (`thedotmack/claude-mem` ⭐85203)
- 🔬 **Claude Code skill/plugin: terse caveman-style output cuts ~75% of OUTPUT tokens while keeping technical accuracy** → `research/JuliusBrussee__caveman.md` (`JuliusBrussee/caveman` ⭐78262)
- 🔬 **Rust CLI proxy that filters/compresses common dev-command output (ls, cat, grep, git, test runners) before it reaches LLM context — 60-90% token reduction, single binary, <10ms overhead** → `research/rtk-ai__rtk.md` (`rtk-ai/rtk` ⭐72028)
- 🔬 **Lifecycle slash commands (spec→plan→build→test→review→ship) packaging engineering skills** → `research/addyosmani__agent-skills.md` (`addyosmani/agent-skills` ⭐68155)
- 🔬 **Pre-indexed semantic code-intelligence graph for Claude Code/Cursor/Codex/etc — surgical context, fewer tool calls, 100% local, auto-syncs on code changes** → `research/colbymchenry__codegraph.md` (`colbymchenry/codegraph` ⭐61096)
- 🔬 **Compress tool outputs/logs/files/RAG before they reach the LLM — 60-95% fewer tokens; library + proxy + MCP server** → `research/headroomlabs-ai__headroom.md` (`headroomlabs-ai/headroom` ⭐54550)
- 🔬 **Official Google MCP server: live Chrome control for perf traces, network/console inspection, Puppeteer automation** → `research/ChromeDevTools__chrome-devtools-mcp.md` (`ChromeDevTools/chrome-devtools-mcp` ⭐51916)
- 🔬 **Archive of leaked system prompts incl. Claude Code + tool defs** → `research/asgeirtj__system_prompts_leaks.md` (`asgeirtj/system_prompts_leaks` ⭐47357)
- 🔬 **Official plugin: invoke OpenAI Codex from inside Claude Code for review/delegate/adversarial-review** → `research/openai__codex-plugin-cc.md` (`openai/codex-plugin-cc` ⭐28302)
- 🔬 **Open-source AI memory platform: persistent long-term memory for agents via a self-hosted knowledge graph; ingest any format, recall across sessions** → `research/topoteretes__cognee.md` (`topoteretes/cognee` ⭐26088)
- 🔬 **Distills a book/doc into a structured Agent Skill loaded lazily by chapter, claims 24x-51x fewer tokens than dumping full doc into context** → `research/virgiliojr94__book-to-skill.md` (`virgiliojr94/book-to-skill` ⭐19833)
- 🔬 **Coding-agent skill for multi-phase security audits: coverage ledger + isolated hunters + adversarial verifiers + schema-validated findings — a reusable pattern for our own security-review skill** → `research/cloudflare__security-audit-skill.md` (`cloudflare/security-audit-skill` ⭐18707)
- 🔬 **Converts documentation sites, GitHub repos, and PDFs into Claude AI skills automatically, with conflict detection and an MCP integration** → `research/yusufkaraaslan__Skill_Seekers.md` (`yusufkaraaslan/Skill_Seekers` ⭐14506)
- 🔬 **AI red-team platform with standalone MCP/skill/agent security scanner CLIs** → `research/Tencent__AI-Infra-Guard.md` (`Tencent/AI-Infra-Guard` ⭐5726)
- 🔬 **Fast/accurate code search library for agents — ~98% fewer tokens than grep+read, CPU-only, MCP server/CLI/subagent, 200x faster indexing than a code-specialized transformer** → `research/MinishLab__semble.md` (`MinishLab/semble` ⭐5658)
- 🔬 **Curated MCP server catalog + security/sandboxing checklist** → `research/appcypher__awesome-mcp-servers.md` (`appcypher/awesome-mcp-servers` ⭐5655)
- 🔬 **Hand-crafted, minimal-token-footprint Claude Code skills/plugins for context engineering and result quality — directly matches our token-thrift mission** → `research/NeoLabHQ__context-engineering-kit.md` (`NeoLabHQ/context-engineering-kit` ⭐1716)
- 🔬 **Cut context waste; checkpoint/restore across compaction; live token/$ + context-quality dashboard** → `research/alexgreensh__token-optimizer.md` (`alexgreensh/token-optimizer` ⭐1491)
- 🔬 **PreToolUse hook that semantically parses and blocks destructive git/filesystem commands (rm -rf, git checkout --, etc.) before Claude Code/Codex/Pi/other agents run them** → `research/kenryu42__claude-code-safety-net.md` (`kenryu42/claude-code-safety-net` ⭐1452)
- 🔬 **Drop-in Claude Code output-style markdown files (answer-first, concise-by-default) that cut response tokens as a side effect of being kind to attention — small, directly reusable asset** → `research/alexgreensh__attention-span.md` (`alexgreensh/attention-span` ⭐1123)
- 🔬 **Fully-local Claude Code session memory — condenses session logs into a resume-ready summary via a classical (non-LLM) Python summarizer, avoiding the cold-start re-explain tax at zero extra model cost** → `research/raiyanyahya__recall.md` (`raiyanyahya/recall` ⭐717)
- 🔬 **npx CLI scanning installed MCP server configs for tool-poisoning/exfiltration/cross-origin-escalation vulnerabilities** → `research/riseandignite__mcp-shield.md` (`riseandignite/mcp-shield` ⭐554)
- 🔬 **Zero-dependency pure-bash MCP server implementation (JSON-RPC over stdio, function-naming tool discovery)** → `research/muthuishere__mcp-server-bash-sdk.md` (`muthuishere/mcp-server-bash-sdk` ⭐512)
- 🔬 **Injected ruleset (terse prose + YAGNI-first code + tool-output compression) that measurably cuts an agent's output tokens (44% of baseline in published benchmarks incl. losses) — zero-dep, directly on our token-thrift mission** → `research/JayPokale__Chisle.md` (`JayPokale/Chisle` ⭐492)
- 🔬 **Anthropic's official Agent Skills examples + spec/template; canonical pattern reference for authoring skills** → `research/anthropics__skills.md` (`anthropics/skills` ⭐0)
- 🔬 **Multi-language code knowledge-graph RAG exposed as an MCP server for Claude Code to query/edit codebases** → `research/vitali87__code-graph-rag.md` (`vitali87/code-graph-rag` ⭐0)

See [`research/INDEX.md`](research/INDEX.md) for every analyzed repo, and query [`index.json`](index.json) programmatically.
<!-- END GENERATED -->
