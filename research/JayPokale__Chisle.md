# JayPokale/Chisle  ·  ⭐492  ·  adopt  ·  emerging
https://github.com/JayPokale/Chisle · pushed 2026-09-19 · triaged 2026-09-21 · seen on github

**What it is:** An injected ruleset (terse prose, YAGNI-first code, tool-output compression) that measurably cuts a coding agent's output tokens — the README shows a side-by-side benchmark (142 lines/1506 tokens bare vs. 35 lines/602 tokens with Chisle) and claims 44% of a bare model's output tokens on coding prompts across 11 agents (Claude Code, Pi, Cursor, Codex, Gemini, +more). Zero dependencies, one command to install, and it publishes the runs where it *lost* — a genuine effort at honest benchmarking rather than marketing-only numbers.

**Reusable for us:** This is claude-common's own mission in a single competing package. Worth reading the actual ruleset content (not just the README) to see if any of its three axes (terse prose / YAGNI-first / tool-output compression) sharpen our `docs/token-thrift.md` guidance, and whether its benchmark methodology (publishing losses, verbatim committed raw outputs) is worth imitating for any future token-thrift claims we make ourselves.

**Token / effectiveness angle:** Directly on-mission — this is a token-thrift tool with published, falsifiable benchmarks.

**How to adopt:** Pull the actual ruleset text (not just README) and diff it against `docs/token-thrift.md`; fold in anything genuinely new. Consider citing its benchmark methodology as a model for validating our own thrift claims.
