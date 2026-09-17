# vitali87/code-graph-rag  ·  ⭐trending(+1686/wk)  ·  adopt  ·  trending
https://github.com/vitali87/code-graph-rag · pushed 2026-08-17 · triaged 2026-08-17 · seen on github-trending

**What it is:** A multi-language code knowledge-graph RAG tool. It parses a monorepo into a graph and exposes it as an MCP server so Claude Code (and other MCP clients) can query and edit the codebase by graph traversal instead of raw grep/read.
**Reusable for us:** A concrete MCP server candidate for large-codebase work — querying a pre-built graph is cheaper than repeated broad reads/greps for "where is X used" style questions once the graph exists.
**Token / effectiveness angle:** Directly on-mission: trades an upfront indexing cost for much cheaper per-query codebase understanding versus re-reading files every session.
**How to adopt:** trial on a large repo before recommending broadly — needs a graph DB backend (see `docs/guide/mcp-server.md`) and initial indexing; not zero-setup. If it holds up, stub an `mcp/` template here pointing at it.
