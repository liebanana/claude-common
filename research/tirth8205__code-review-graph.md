# tirth8205/code-review-graph  ·  ⭐22586  ·  adopt  ·  trending
https://github.com/tirth8205/code-review-graph · pushed 2026-07-18 · triaged 2026-07-20 · seen on github-trending

**What it is:** A local-first code-intelligence graph (Python, Tree-sitter based) that builds a persistent structural map of a codebase and tracks changes incrementally, so AI code-review/CLI tools read only what's relevant instead of re-reading large chunks of the repo. MCP-compatible, has a GitHub Action, publishes benchmarked context reductions.
**Reusable for us:** A concrete implementation of the "targeted reads" token-thrift principle, specifically tuned for review workflows — directly relevant to our own `/code-review` skill and to any repo-wide agent task that currently re-reads files per turn.
**Token / effectiveness angle:** Its whole pitch is context/token reduction on review and large-repo workflows — publishes reproducible benchmarks (`docs/REPRODUCING.md`).
**How to adopt:** Trial it (`pip install code-review-graph` / MCP) against this repo's `/code-review` flow and see if it measurably cuts context vs. our current grep+read approach; if it holds up, note field results here and flip status to `trialed`.
