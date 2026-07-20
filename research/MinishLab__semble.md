# MinishLab/semble  ·  ⭐5658  ·  adopt  ·  trending
https://github.com/MinishLab/semble · pushed 2026-07-17 · triaged 2026-07-20 · seen on github

**What it is:** A CPU-only code search library purpose-built for agents — natural-language query in, exact relevant snippets out, using ~98% fewer tokens than grep+read. Claims ~200x faster indexing and ~10x faster queries than a code-specialized transformer retriever at 99% of its retrieval quality. Usable as an MCP server, CLI (via AGENTS.md), or a dedicated sub-agent.
**Reusable for us:** Directly on-mission and the most rigorously benchmarked of the three code-search/graph candidates triaged this run (published quality-vs-speed comparison against a transformer baseline, not just marketing claims).
**Token / effectiveness angle:** Core claim (~98% fewer tokens than grep+read for code search) is exactly this repo's mission.
**How to adopt:** `uv tool install semble && semble install` in a trial repo, run it as an MCP server or sub-agent against a real search task, and compare token/quality against plain grep — the strongest candidate of this batch to actually trial first.
