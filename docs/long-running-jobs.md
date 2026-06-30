---
kind: doc
status: ready
group: Save tokens / work efficiently
intent: Long/background jobs get reaped — chunk with incremental output and bake into an invokable script
tags: [practices, reliability, tokens]
---

# Long-running & background jobs: don't trust one big detached process

**Lesson:** a single multi-hour background job is fragile in an agent harness — when it
dies, you can lose hours of work *and* burn tokens re-driving it. Design long flows to
survive a kill from the start.

## Why detached jobs die
Observed across agent harnesses (provenance: extracted while running a multi-hour
local STT/whisper sweep that an orchestrator was driving):

- **Subagent background children die when the subagent ends.** A subagent that launches a
  detached job (`nohup`, an orchestrator script) and then "waits" actually *stops*, and
  the harness reaps its children. The long job vanishes after the first unit completes.
- **A foreground/background tool call is capped by its own timeout** (often ~10 min max).
  A waiter set to watch a 3-hour job exits long before the job finishes.
- **Self-scheduling back into the same session may be unavailable** (some schedulers only
  spawn a *fresh* session, which loses your context — useless for resuming work in place).

A real `cron`/terminal process is **not** subject to this — the reaping is a harness/agent
artifact, not an OS limit.

## The pattern that survives
1. **Chunk the work into short (<~10 min) units** the harness won't reap mid-flight.
   For OOM-serial work (one whisper/model at a time) this is natural — process one
   item/language/shard per chunk.
2. **Write incremental per-unit output as you go** (one file/marker per completed unit), so
   a kill loses only the *in-flight* unit; completed units persist and a relaunch skips them.
3. **Detect completion cheaply** — a progress/sentinel file or a *re-armed* waiter
   (relaunch on each exit until the marker appears), not one long-lived watcher.
4. **Bake the chunked flow into a committed, parametrized script** (see
   `docs/token-thrift.md` → "Replace re-runs with scripts"). Then a human, a cron, or the
   next session can run it unattended without an agent babysitting it — and you stop
   re-driving the same sequence with tokens.

## Smell test
If your plan is "launch a 3-hour background job and wait for one notification," stop —
it will probably be reaped. Make it resumable and incremental instead.
