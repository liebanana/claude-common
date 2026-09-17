# mksglu/context-mode  ·  ⭐19116  ·  adopt  ·  trending
https://github.com/mksglu/context-mode · pushed 2026-07-20 · triaged 2026-07-20 · seen on github (HN #1, 570+ points)

**What it is:** A context-window optimizer for AI coding agents: sandboxes tool output before it reaches the model (claims ~98% reduction), persists session memory across restarts, and enforces routing rules across 17 agent platforms via MCP + hooks.
**Reusable for us:** A concrete, viral (HN #1) implementation of "don't dump huge output into context" — one of our own token-thrift bullets — generalized across many harnesses via hooks. Worth understanding its output-sandboxing mechanism even if we don't install it wholesale.
**Token / effectiveness angle:** Core pitch is context/token reduction (tool-output sandboxing) plus cheap session-memory persistence.
**How to adopt:** Trial the MCP+hooks install in a side repo, compare its output-sandboxing approach to our own `hooks/` conventions; record field notes before considering wider adoption (it's ELv2-licensed, not fully permissive — check terms before vendoring code).
