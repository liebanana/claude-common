# DeusData/codebase-memory-mcp  ·  ⭐22669  ·  adopt
https://github.com/DeusData/codebase-memory-mcp · pushed 2026-06-30 · triaged 2026-06-30

**What it is:** A high-performance code-intelligence MCP server that indexes a codebase into a persistent knowledge graph (tree-sitter + SQLite/Cypher), 158 languages, sub-ms queries. Single static binary, zero deps, MIT. Claims "99% fewer tokens" vs reading files.
**Reusable for us:** Strong general fit — agents query structure/symbols instead of reading whole files, which is exactly the token-thrift "targeted reads" principle but automated. Good `mcp/` template candidate for any code repo.
**Token / effectiveness angle:** Replaces broad file reads/greps with cheap graph queries; the biggest single lever on per-task token cost in code work.
**How to adopt:** Add an `mcp/codebase-memory.json` placeholder template + a `docs/` note on "query the graph before reading files." Validate query quality on one real repo first.

**Field notes (2026-07-01):** installed + uninstalled on Linux; status → trialed.
- The one-line installer configures **globally by default** — it wrote `~/.claude/.mcp.json`,
  a top-level `mcpServers` entry in `~/.claude.json`, a global Claude Code skill, and
  PreToolUse/SessionStart hooks. That activates it in *every* project on the host. Use
  `--skip-config` (binary only) and add a per-project `.mcp.json` instead:
  `{"mcpServers":{"codebase-memory-mcp":{"command":"~/.local/bin/codebase-memory-mcp"}}}`
- `codebase-memory-mcp uninstall` cleanly removed all the configs/skills/hooks **but also
  deleted the binary** — contrary to its README, which claims uninstall keeps it.
- Binary is large (~266 MB) but truly standalone. Not yet exercised on a real index/query
  workload — that's the remaining step before `in-use`.
