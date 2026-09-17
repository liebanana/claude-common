# cisco-ai-defense/mcp-scanner  ·  ⭐982  ·  watch  ·  emerging
https://github.com/cisco-ai-defense/mcp-scanner · pushed 2026-07-10 · triaged 2026-07-13 · seen on hackernews

**What it is:** A Python tool scanning MCP servers/tools for security findings, combining Cisco AI Defense's inspect API, YARA rules, and LLM-as-a-judge detection of malicious MCP tools.
**Reusable for us:** Same problem space as `riseandignite/mcp-shield` (see that note) but heavier — needs Python 3.11+ and optionally a Cisco AI Defense API key/account for the cloud-inspect features. mcp-shield's `npx`-only path is the lower-friction first choice; this is worth keeping in the back pocket for deeper/offline (YARA-based) scanning.
**Token / effectiveness angle:** n/a — security tool.
**How to adopt:** Watch. Prefer `mcp-shield` for quick checks; revisit this if we need YARA-rule-based or offline scanning without a cloud API dependency.
