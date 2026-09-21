# AMAP-ML/LongHorizon-Harness  ·  ⭐1610  ·  watch  ·  emerging
https://github.com/AMAP-ML/LongHorizon-Harness · pushed 2026-08-20 · triaged 2026-09-21 · seen on github

**What it is:** An arXiv-backed (2608.01964) "loop engineering" harness for computer-use agents: plan → act → verify → checkpoint-or-recover → repeat, aimed at keeping an agent working reliably across desktop apps and the CLI for dozens of hours. Natively integrates with Claude Code, Codex, OpenCode, and DeepSeek Harness; benchmarked on WeaveBench/OSWorld 2.0/Terminal-Bench 2.1.

**Reusable for us:** The plan/act/verify/checkpoint-recover loop is conceptually the same problem our `session-handover` skill and AGENT-DIRECTIVE §3 (autonomous mode) solve for long-running agent work — durable checkpoints, recoverable progress, independent auditing of claimed progress. Worth reading its checkpoint format if we ever harden session-handover for multi-hour unattended runs.

**Token / effectiveness angle:** "Durable verified state" avoids re-deriving progress from scratch after an interruption — same motivation as our own git-based handover notes.

**How to adopt:** Watch. Revisit when improving `session-handover` or writing a longer-horizon autonomous loop — check their checkpoint/recovery format against ours for gaps.
