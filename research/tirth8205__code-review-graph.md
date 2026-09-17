# tirth8205/code-review-graph  ·  ⭐n/a  ·  watch  ·  trending
https://github.com/tirth8205/code-review-graph · triaged 2026-07-27 · seen on github-trending

**What it is:** An MCP server that builds a Tree-sitter structural map of a codebase, tracks changes incrementally, and hands an AI coding assistant only the precise context a review needs — claims 38x-528x token reduction vs. naive full-file review across benchmarked repos. One-command install (`code-review-graph install`) auto-detects and configures Claude Code, Codex, Cursor, Windsurf, Zed, Copilot, and more.
**Reusable for us:** directly on-mission — this is exactly the kind of token-thrift MCP asset this repo exists to surface, and it explicitly targets our own "code review" use case (`/code-review`, `/security-review`).
**Token / effectiveness angle:** the whole pitch is token reduction via incremental structural context instead of re-reading full files on every review pass.
**How to adopt:** trial candidate — `pip install code-review-graph && code-review-graph install --platform claude-code` in a scratch repo, compare its MCP-served context against our existing `/code-review` flow before recommending adoption; has a clean symmetric `uninstall` if it doesn't pan out.
