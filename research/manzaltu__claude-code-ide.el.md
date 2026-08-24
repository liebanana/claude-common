# manzaltu/claude-code-ide.el  ·  ⭐1650  ·  watch  ·  stable
https://github.com/manzaltu/claude-code-ide.el · pushed 2026-08-07 · triaged 2026-08-24 · seen on hackernews

**What it is:** Emacs package giving Claude Code a native, bidirectional MCP bridge into Emacs — exposes LSP (eglot/lsp-mode), tree-sitter, Imenu, project.el, Flycheck/Flymake diagnostics, and arbitrary Elisp functions as MCP tools, plus an ediff-based diff view and active-buffer/selection awareness.
**Reusable for us:** Not directly transferable (Emacs-specific, no equivalent in this toolkit's target editors) but a clean reference implementation for "expose editor internals to Claude via MCP" if the user or any consumer of this repo works in Emacs.
**Token / effectiveness angle:** n/a directly — better editor context (LSP/tree-sitter) can reduce exploratory reads, but that's incidental to the plugin's purpose.
**How to adopt:** Watch. Only actionable if an Emacs user on this team wants Claude Code IDE integration; otherwise no action.
