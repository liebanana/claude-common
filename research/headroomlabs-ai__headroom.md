# headroomlabs-ai/headroom  ·  ⭐54550  ·  adopt
https://github.com/headroomlabs-ai/headroom · pushed 2026-06-30 · triaged 2026-06-30

**What it is:** Compresses tool outputs, logs, files, and RAG chunks *before* they reach the LLM — "60-95% fewer tokens, same answers." Ships three ways: a library, a transparent proxy, and an MCP server (Apache-2.0, Python/TypeScript).
**Reusable for us:** Directly on-mission. The proxy/MCP form could sit in front of token-heavy tools (verbose builds, large file reads, RAG) across projects. Candidate for an `mcp/` template + a `docs/token-thrift.md` technique.
**Token / effectiveness angle:** This *is* the mission — cut input tokens on noisy payloads without losing signal. Highest-value find in this batch.
**How to adopt:** Trial the MCP server against a token-heavy workflow; if it holds up, add an `mcp/headroom.json` placeholder template + write up the "compress-before-context" pattern in `docs/`.
