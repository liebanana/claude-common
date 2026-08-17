# manzaltu/claude-code-ide.el  ·  ⭐n/a  ·  watch  ·  stable
https://github.com/manzaltu/claude-code-ide.el · triaged 2026-08-17 · seen on hackernews

**What it is:** Native Emacs integration for Claude Code via MCP — a bidirectional bridge exposing Emacs' LSP/xref, tree-sitter, imenu, project, and arbitrary Elisp functions as MCP tools, plus diff view, diagnostics (Flycheck/Flymake), and active-buffer/selection awareness.
**Reusable for us:** A solid worked example of "expose your editor as MCP tools" for deep IDE-aware context, but Emacs-specific and not portable to our (editor-agnostic) toolkit as-is.
**Token / effectiveness angle:** Giving Claude direct LSP/tree-sitter access instead of shelling out to greps/reads is a real token-thrift pattern, just packaged for one editor.
**How to adopt:** watch — recommend directly to the user only if they use Emacs; otherwise just a pattern reference.
