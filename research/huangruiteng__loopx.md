# huangruiteng/loopx  ·  ⭐3883  ·  watch  ·  trending
https://github.com/huangruiteng/loopx · pushed 2026-08-10 · triaged 2026-08-10 · seen on github-trending

**What it is:** A provider-neutral, local-first "control plane" for long-running agent work — keeps objective, gates, todos, evidence, quota, and handoffs in a durable state layer so Codex/Claude Code/Cursor/etc. can execute bounded turns against it and pause for human judgment when needed. Early-stage (status badge: "loop agents early").
**Reusable for us:** Overlaps conceptually with our own `/loop` skill and the AGENT-DIRECTIVE autonomous/online mode split (durable goals, human-judgment gates, quota-aware pausing), but it's a much heavier standalone tool (Python package, its own state kernel, multi-agent handoff protocol) rather than something to vendor directly.
**Token / effectiveness angle:** Its "quota-aware auto-wake" and "bounded turn" framing matches the thrift goal of not letting a long-running loop spend unboundedly.
**How to adopt:** watch — re-check once past early-stage if our `/loop`/autonomous-mode needs outgrow the current lightweight approach.
