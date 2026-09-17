# kunchenguid/firstmate  ·  ⭐5881  ·  watch  ·  emerging
https://github.com/kunchenguid/firstmate · pushed 2026-09-14 · triaged 2026-09-14 · seen on github-trending

**What it is:** An "agent distro" (not an app/MCP/skill — a cloned directory of instructions + tooling) that turns a primary agent (Claude Code, Grok, Pi, Codex, etc.) into a "first mate" supervising a crew of sub-agents, each in its own git worktree and visible terminal session (tmux/etc.), with event-driven "zero-token" supervision (a bash watcher wakes the first mate only when something needs attention) and optional persistent "secondmates" on remote hosts.
**Reusable for us:** The zero-token event-driven supervision pattern (a bash watcher instead of a polling agent loop) and worktree-per-crewmate isolation are both directly relevant techniques — conceptually close to what `ScheduleWakeup`/`EnterWorktree`/the Workflow tool already do in this harness, so it's more a point of comparison than something to install wholesale.
**Token / effectiveness angle:** The "zero-token supervision" framing is exactly our mission's language; worth understanding the mechanism even without adopting the distro.
**How to adopt:** watch — read `docs/architecture.md` for the supervision-loop mechanism if we ever build something similar; adopting the distro itself is out of scope (it wants to own the whole session).
