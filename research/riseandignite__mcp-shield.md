# riseandignite/mcp-shield  ·  ⭐554  ·  adopt  ·  emerging
https://github.com/riseandignite/mcp-shield · pushed 2025-04-26 · triaged 2026-07-13 · seen on hackernews

**What it is:** An `npx` CLI that scans installed MCP server configs (`.mcp/*.json`, `claude_desktop_config.json`, etc.) for tool-poisoning attacks, exfiltration channels, and cross-origin escalations; optionally uses a Claude API key for deeper AI-assisted analysis.
**Reusable for us:** Directly useful defensive check before trusting any MCP server we add to `mcp/` or recommend adopting (including candidates surfaced by this very triage process) — a concrete guard against the "malicious MCP tool" risk this repo already worries about (see the discovery-engine's own permission-scoping).
**Token / effectiveness angle:** n/a — security tool, not a token optimizer.
**How to adopt:** Run `npx mcp-shield` against any newly-adopted MCP server config before recommending it further; cheap, zero-install-footprint sanity check.
