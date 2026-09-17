# rtk-ai/rtk  ·  ⭐72028  ·  adopt  ·  trending
https://github.com/rtk-ai/rtk · pushed 2026-07-20 · triaged 2026-07-20 · seen on github

**What it is:** "Rust Token Killer" — a single-binary CLI proxy that filters and compresses the output of 100+ common dev commands (`ls`, `cat`, `grep`, `git status/diff/log`, test runners, linters) before they reach an LLM's context. Claims 60-90% token reduction with <10ms overhead; installable via Homebrew.
**Reusable for us:** A ready-made, zero-dependency implementation of exactly the "don't dump huge output; filter with head/grep/--quiet" principle already in `docs/token-thrift.md` — this repo's own core value proposition, done as an external tool.
**Token / effectiveness angle:** Its published benchmark table (30-min Claude Code session, ~118k → far fewer tokens across ls/cat/grep/git/test-runner calls) is directly relevant evidence for our own thrift playbook.
**How to adopt:** Install via Homebrew, run a real session with/without it, and record actual token deltas as field notes; if it holds up, reference it from `docs/token-thrift.md` as a concrete tool option alongside the existing hygiene bullets.
