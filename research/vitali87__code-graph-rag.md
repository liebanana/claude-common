# vitali87/code-graph-rag  ·  ⭐3407  ·  watch  ·  emerging
https://github.com/vitali87/code-graph-rag · pushed 2026-08-10 · triaged 2026-08-10 · seen on github-trending

**What it is:** Parses a multi-language monorepo with Tree-sitter into a knowledge graph (Memgraph), then exposes it as an MCP server so Claude Code and other MCP clients can query/edit the codebase in plain English via the graph instead of raw greps.
**Reusable for us:** Directly relevant category (large-monorepo context via a queryable graph instead of re-reading files), but non-trivial install (Docker + Memgraph + cmake + ripgrep) and a trust-signal caveat: the README itself notes the maintainer's GitHub account was suspended (badges commented out "while the GitHub account is suspended... Restore them when reinstated") — worth confirming project/maintainer status before relying on it.
**Token / effectiveness angle:** Its pitch is fewer exploratory reads on large codebases by querying a pre-built structural graph instead of grepping/re-reading files each session.
**How to adopt:** watch — re-check maintainer/account status, then trial the MCP server against a large mixed-language repo if the need arises.
