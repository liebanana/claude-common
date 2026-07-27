# KnockOutEZ/wigolo  ·  ⭐3690  ·  watch  ·  trending
https://github.com/KnockOutEZ/wigolo · triaged 2026-07-27 · seen on github, github-trending

**What it is:** A local-first MCP server giving agents web search/fetch/crawl/extract/cache/find-similar/research tools with no API keys and no per-query cloud bill — runs a local browser engine + on-device models, wires into Claude Code (and Cursor/Codex/etc.) via one `npx wigolo init --agents=claude-code` command.
**Reusable for us:** a potential zero-cost alternative/complement to the built-in WebSearch/WebFetch tools for research-heavy work (e.g. the discovery engine's own source scripts), if its keyless local pipeline proves accurate enough.
**Token / effectiveness angle:** removes API-key/cloud cost for web research entirely; `research`/`agent` verbs can synthesize cited answers locally instead of round-tripping through a paid search API.
**How to adopt:** watch — public beta, unverified accuracy/latency of the local browser+model pipeline. Worth a hands-on trial (`npx wigolo init`) before recommending it as an MCP addition in `mcp/`.
