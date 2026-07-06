# manzaltu/claude-code-ide.el  ·  ⭐1611  ·  watch  ·  emerging
https://github.com/manzaltu/claude-code-ide.el · pushed 2026-07-02 · triaged 2026-07-06 · seen on hackernews · 334d↑

**What it is:** An Emacs package giving Claude Code a bidirectional MCP bridge into Emacs — LSP/xref navigation, tree-sitter, Imenu, project awareness, Flycheck/Flymake diagnostics, ediff-based diff review, and the ability to expose arbitrary Elisp functions as MCP tools.
**Reusable for us:** Niche — only useful for Emacs users of Claude Code, which we have no evidence of being the case here. The pattern (exposing an editor's own introspection commands as MCP tools) is a reusable idea for any editor integration, just not directly applicable without Emacs.
**Token / effectiveness angle:** Could reduce redundant file reads by letting Claude query Emacs' own LSP/tree-sitter state instead of re-parsing files, if adopted.
**How to adopt:** Watch. Only relevant if/when an Emacs-based workflow shows up.
