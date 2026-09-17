# TencentCloud/TencentDB-Agent-Memory  ·  ⭐trending(+3637/wk)  ·  watch  ·  trending
https://github.com/TencentCloud/TencentDB-Agent-Memory · pushed 2026-08-17 · triaged 2026-08-17 · seen on github-trending

**What it is:** A team-level shared memory hub (memory-core + memory-hub + proxy services) that multiple agent CLIs — including Claude Code — point at via a single proxy URL, so project context, docs already read, and working workflows persist and are shared across a team's agents without per-tool plugins/hooks.
**Reusable for us:** Overlaps conceptually with our own per-session memory system, but at team scale and as a multi-service self-hosted deployment (needs LLM config for two service groups, a DB backend). Not a lightweight drop-in.
**Token / effectiveness angle:** Directly targets the "don't re-explain your project every session" problem — same goal as our memory system, but for a whole team instead of one user's local `~/.claude`.
**How to adopt:** watch — worth revisiting if the user ever wants team-shared (not just personal) agent memory; would need real deployment effort to trial.
