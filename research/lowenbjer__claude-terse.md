# lowenbjer/claude-terse  ·  ⭐0  ·  adopt  ·  emerging
https://github.com/lowenbjer/claude-terse · pushed 2026-10-12 · triaged 2026-10-12 · seen on hackernews

**What it is:** Claude Code plugin cutting reply length ~45-54% via anti-filler/anti-mannerism rules; benchmarked on Opus 5.5/Fable 5.1
**Reusable for us:** Rule list for suppressing filler, recaps, slogans, 'X not Y' reframes, first-person narration; ships a benchmark methodology (docs/benchmark.md).
**Token / effectiveness angle:** Output tokens cost ~5x input on Opus/Fable; README reports -45% output tokens, -32..51% cost (self-measured, 12-20 prompts, one run each).
**How to adopt:** Compare against caveman (already in ledger); trial the plugin and mine its rule list for AGENT-DIRECTIVE terse-output guidance. Claims unverified.
