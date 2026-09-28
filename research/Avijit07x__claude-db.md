# Avijit07x/claude-db  ·  ⭐227  ·  watch  ·  emerging
https://github.com/Avijit07x/claude-db · pushed 2026-08-30 · triaged 2026-09-21 · seen on github

**What it is:** "Persistent memory for Claude Code. Bring your own database." Capture and recall run as hooks (no explicit command needed — context is injected automatically every prompt). A separate `claude-db scan` command builds a code graph, exposed to Claude via MCP in four modes: `text` (live grep), `usages`, `explain`, `path`.

**Reusable for us:** A different memory architecture from ours: pluggable DB backend instead of flat markdown files, plus a code-graph layer (usages/explain/path) that our own memory system doesn't attempt — ours is purely conversational/preference memory, not code-structure memory. Worth watching as a possible complement (code-graph MCP) rather than a replacement.

**Token / effectiveness angle:** Same "inject automatically, never ask for it" philosophy as our own MEMORY.md — no incremental token savings idea beyond what we already do.

**How to adopt:** Watch. If we ever want code-structure-aware memory (call graphs, usage sites) rather than just preference/project memory, evaluate this repo's MCP modes before building one.
