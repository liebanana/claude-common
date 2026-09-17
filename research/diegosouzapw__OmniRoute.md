# diegosouzapw/OmniRoute  ·  ⭐16629  ·  watch  ·  trending
https://github.com/diegosouzapw/OmniRoute · pushed 2026-07-13 · triaged 2026-07-13 · seen on github-trending

**What it is:** A free AI gateway/router — one endpoint fronting 250+ providers (90+ free tiers), with auto-fallback and "RTK + Caveman" compression claimed to save 15-95% of tokens. Targets Claude Code, Codex, Cursor, Cline, Copilot.
**Reusable for us:** The token-compression claim is directly on-mission (token thrift), but the README is heavily marketing-driven (star-begging, aggressive claims about aggregating free-tier inference across 90+ providers) and the "free tier aggregation" model raises ToS-compliance questions worth checking before relying on it.
**Token / effectiveness angle:** If the compression technique is real and documented, it could be a useful pattern regardless of whether we use the gateway itself — but unverified from README alone.
**How to adopt:** Watch only. Don't route production traffic through it without reading `docs/reference/FREE_TIERS.md` and verifying provider ToS compliance first.
