# wonderwhy-er/DesktopCommanderMCP  ·  ⭐8154  ·  watch  ·  stable
https://github.com/wonderwhy-er/DesktopCommanderMCP · pushed 2026-07-13 · triaged 2026-07-13 · seen on github-trending

**What it is:** An MCP server giving Claude (mainly Claude Desktop) terminal control, filesystem search, and diff-based file editing — a mature project (created Dec 2024), with third-party trust badges (AgentAudit, Smithery, Archestra).
**Reusable for us:** Overlaps heavily with what Claude Code's native Bash/Read/Edit tools already provide, so lower value for CLI-based Claude Code work. Its main value is extending Claude Desktop (the GUI app, no native terminal/file tools) with equivalent capability.
**Token / effectiveness angle:** n/a for Claude Code; for Claude Desktop users it avoids re-implementing an MCP file/terminal bridge from scratch.
**How to adopt:** Watch. Only relevant if a user needs Claude Desktop (not Claude Code CLI) to have terminal/file access — then it's a ready-made MCP server rather than something to build.
