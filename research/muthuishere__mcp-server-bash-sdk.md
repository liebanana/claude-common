# muthuishere/mcp-server-bash-sdk  ·  ⭐512  ·  adopt  ·  emerging
https://github.com/muthuishere/mcp-server-bash-sdk · pushed 2026-02-21 · triaged 2026-07-13 · seen on hackernews

**What it is:** A zero-dependency (bash + jq) implementation of an MCP server — full JSON-RPC 2.0 over stdio, dynamic tool discovery via function-naming convention, external JSON config — as an alternative to Node/Python MCP SDKs.
**Reusable for us:** Matches this repo's own conventions exactly ("Prefer Bash" per `CLAUDE.md`, `mcp/` holds integration templates). A lightweight pattern for stubbing a custom MCP server here without pulling in a Node/Python runtime.
**Token / effectiveness angle:** No runtime dependency to install/maintain — cheaper to stand up and audit than a full SDK for a simple tool-exposing server.
**How to adopt:** Worth trialing as the basis for a `mcp/` template next time we need a small custom MCP server — clone the core script pattern (`mcpserver_core.sh` + function-naming convention) rather than the whole repo.
