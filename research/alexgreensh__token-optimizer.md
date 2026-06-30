# alexgreensh/token-optimizer  ·  ⭐1491  ·  adopt
https://github.com/alexgreensh/token-optimizer · pushed 2026-06-30 · triaged 2026-06-30

**What it is:** A Claude Code plugin (also OpenCode/Codex builds) that cuts context waste, "survives compaction" via checkpoint + restore, and shows a live dashboard of tokens / $ / turns plus a live context-quality score. Zero deps, zero telemetry, Python 3.9+. PolyForm Noncommercial license.
**Reusable for us:** Directly on-mission for `docs/token-thrift.md`. Two concrete techniques worth encoding: (1) **checkpoint/restore around compaction** — snapshot the salient state to a file so a compaction or `/clear` doesn't lose it; (2) a **context-quality / token-budget signal** the agent can watch. License blocks redistribution but the patterns are ours to reimplement.
**Token / effectiveness angle:** This is the repo's whole thesis — measurable token + dollar savings per session and avoiding context-quality decay. Strongest token-thrift match we've triaged.
**How to adopt:** Add the checkpoint-before-compaction + "save salient state to memory file" technique to `docs/token-thrift.md`; cross-reference our memory/`MEMORY.md` pattern. Don't vendor code (noncommercial license) — encode the practice.
