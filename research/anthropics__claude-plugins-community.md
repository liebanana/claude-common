# anthropics/claude-plugins-community  ·  ⭐1234  ·  adopt  ·  stable
https://github.com/anthropics/claude-plugins-community · pushed 2026-08-23 · triaged 2026-08-24 · seen on github-trending

**What it is:** Anthropic's official read-only mirror of the community Claude Code / Claude Cowork plugin marketplace — `.claude-plugin/marketplace.json` lists every plugin that's passed automated security review, synced nightly from Anthropic's internal pipeline. Install via `claude plugin marketplace add anthropics/claude-plugins-community` then `claude plugin install <name>@claude-community`.
**Reusable for us:** A standing discovery source we don't currently crawl — `scripts/sources/*.sh` covers GitHub/HN/Lobsters/Reddit but not this marketplace index directly. Periodically diffing `marketplace.json` against our `research/ledger.jsonl` would surface vetted plugins we haven't triaged yet, pre-filtered by Anthropic's own security scan (a stronger prior than an arbitrary GitHub-trending repo).
**Token / effectiveness angle:** n/a directly — it's a catalog, not a technique.
**How to adopt:** Reference it directly: `curl -fsSL https://raw.githubusercontent.com/anthropics/claude-plugins-community/HEAD/.claude-plugin/marketplace.json | jq` for a quick browse. Optionally add as a new `scripts/sources/claude-plugins-marketplace.sh` discovery source in a future iteration.
