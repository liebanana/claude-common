# lharries/whatsapp-mcp  ·  ⭐6190  ·  watch  ·  stable
https://github.com/lharries/whatsapp-mcp · pushed 2025-07-13 · triaged 2026-08-24 · seen on hackernews

**What it is:** MCP server connecting a personal WhatsApp account (via the `whatsmeow` multidevice Web API) to an LLM — search/read messages and contacts, send text and media, all stored locally in SQLite and only sent to the LLM when a tool is actually invoked.
**Reusable for us:** General-purpose personal-data MCP, not coding-agent-specific, so out of scope to vendor. Worth noting for its own README's explicit callout of the "lethal trifecta" (prompt injection + private data access + exfiltration channel) — a good citation next time this toolkit documents MCP security guidance.
**Token / effectiveness angle:** n/a.
**How to adopt:** Watch / reference only. If a future MCP template here needs a lethal-trifecta warning example, cite this repo's own caution note.
