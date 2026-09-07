# manzaltu/claude-code-ide.el  ·  ⭐1659  ·  watch  ·  stable
https://github.com/manzaltu/claude-code-ide.el · pushed 2026-08-07 · triaged 2026-09-07 · seen on hackernews

**What it is:** Native Emacs integration for Claude Code via MCP — a bidirectional bridge exposing Emacs state (LSP, project management, tree-sitter, xrefs, Flycheck diagnostics, custom Elisp functions) as MCP tools, plus terminal integration (vterm/eat/ghostel).
**Reusable for us:** Not directly (Emacs-only, GPLv3), but a clean reference for the **editor-state-as-MCP-tools** pattern — exposing live IDE context (diagnostics, symbol info, project structure) to Claude Code via a local MCP server rather than having the agent re-derive it by reading/grepping files.
**Token / effectiveness angle:** Surfacing structured editor state (e.g. current diagnostics) via MCP instead of asking the agent to shell out and parse output is a context-economy win — same principle as our `mcp/` templates aim for.
**How to adopt:** Watch. Reference if we ever build/curate an MCP template for a different editor's live state.
