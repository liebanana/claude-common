# DeusData/codebase-memory-mcp  ·  ⭐22669  ·  adopt
https://github.com/DeusData/codebase-memory-mcp · pushed 2026-06-30 · triaged 2026-06-30

**What it is:** A high-performance code-intelligence MCP server that indexes a codebase into a persistent knowledge graph (tree-sitter + SQLite/Cypher), 158 languages, sub-ms queries. Single static binary, zero deps, MIT. Claims "99% fewer tokens" vs reading files.
**Reusable for us:** Strong general fit — agents query structure/symbols instead of reading whole files, which is exactly the token-thrift "targeted reads" principle but automated. Good `mcp/` template candidate for any code repo.
**Token / effectiveness angle:** Replaces broad file reads/greps with cheap graph queries; the biggest single lever on per-task token cost in code work.
**How to adopt:** Add an `mcp/codebase-memory.json` placeholder template + a `docs/` note on "query the graph before reading files." Validate query quality on one real repo first.
