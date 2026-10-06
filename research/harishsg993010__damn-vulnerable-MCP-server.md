# harishsg993010/damn-vulnerable-MCP-server  ·  ⭐1352  ·  watch  ·  stable
https://github.com/harishsg993010/damn-vulnerable-MCP-server · pushed 2025-12-08 · triaged 2026-09-28 · seen on hackernews

**What it is:** A Docker-based, deliberately vulnerable MCP implementation with 10 graded CTF-style challenges (easy→hard) covering prompt injection, tool poisoning, excessive permission scope, rug-pull attacks, tool shadowing, indirect prompt injection, token theft, malicious code execution, remote access, and multi-vector attacks.
**Reusable for us:** Not a code asset to import, but its vulnerability taxonomy is a ready-made checklist for reviewing any MCP server we ship under `mcp/` or recommend to consumers, and for the `security-review` skill when the diff touches MCP tool definitions.
**Token / effectiveness angle:** n/a (security posture, not token thrift) — but relevant given claude-common templates and helps consumer repos wire up MCP servers.
**How to adopt:** watch — reference its 10-category list next time we author or review an MCP server template.
