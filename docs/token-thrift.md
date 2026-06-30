---
kind: doc
status: ready
group: Save tokens / work efficiently
intent: Token-thrift & effectiveness playbook (model choice, scripts-over-reruns, context hygiene)
tags: [tokens, practices]
---

# Token-thrift & effectiveness playbook

Distilled, durable practices for getting more out of Claude Code / agents per token.
Sources: the workspace `AGENT-DIRECTIVE.md` and field tips (incl.
[changtimwu's gist](https://gist.github.com/changtimwu/48a6daaa6d8343174a5b8a2eab60a70d)).
Add to this as you learn — keep each item one or two lines.

## Model & spawning
- Use the **lowest-cost capable model**; never default to Opus. Push mechanical/bulk
  work to Sonnet/Haiku; reserve Opus for genuinely hard reasoning.
- **Don't spawn subagents** unless the task needs real fan-out (broad multi-location
  search) or the user asks — each spawn starts cold and re-derives context.
- For broad read-only searches use the **Explore** agent (returns conclusions, cheap),
  not a full general-purpose agent.

## Replace re-runs with scripts (the core idea of this repo)
- If you find yourself (or the cron) running the **same command sequence** repeatedly,
  encode it once as a deterministic `scripts/` script. One script call ≫ N agent
  round-trips that re-read state and re-reason each time.
- Scripts self-document, take args, are idempotent, and exit non-zero on failure so a
  caller can branch without parsing prose.

## Context / token hygiene
- **Don't re-read** files you just wrote/edited — the harness tracks them.
- **Targeted reads** — read the section you need, not whole large files.
- **Don't dump** huge command output into context; filter (`head`, `grep`, `wc -l`,
  `--quiet`). When a human is online, hand them the noisy command and ask for the
  one-line verdict.
- Don't re-derive facts already established earlier in the conversation.

## Workflow leverage
- **Plan first** for non-trivial work (Plan mode / a written plan), iterate on the plan
  cheaply before executing.
- **Give the agent a way to verify** its own work (tests, lint, build, a smoke script).
  A feedback loop is the highest-ROI quality lever — it removes guess-and-recheck
  cycles that burn tokens.
- **Pre-allow safe commands** via `.claude/settings.json` permissions instead of
  blanket skip-permissions, so routine calls don't stall on prompts.
- **PostToolUse hooks** for formatting/the "last 10%" so the agent doesn't spend turns
  hand-fixing style.
- **Long/background jobs get reaped** — don't trust one big detached process; chunk with
  incremental output and bake into an invokable script. See `docs/long-running-jobs.md`.

## Decide your mode first (this workspace)
- Scheduled / `claude -p` / `/loop` / cron → **autonomous**, always.
- Interactive → read `~/.claude/.online`: fresh (<4h) = **online** (hand human-runnable
  work — auth/2FA, GUI, live monitors, high-output commands — to the user in one
  `! <command>` block, ask for just the result); absent/stale = **autonomous**.
