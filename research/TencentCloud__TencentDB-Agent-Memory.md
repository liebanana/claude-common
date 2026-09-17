# TencentCloud/TencentDB-Agent-Memory  ·  ⭐19259  ·  watch  ·  trending
https://github.com/TencentCloud/TencentDB-Agent-Memory · pushed 2026-08-10 · triaged 2026-08-10 · seen on github-trending

**What it is:** A team-level "memory hub" for AI agents — turns conversations, docs, and code into four shared memory assets (Chat Memory, Skill, LLM-Wiki, Code-Graph) that multiple agents/frameworks can read and write, deployed as three services (memory-core, memory-hub, proxy) via Docker.
**Reusable for us:** Conceptually adjacent to our own memory system, but it's a heavy multi-service install (Docker, LLM API keys for two service groups, a web panel) rather than a drop-in asset — not something to vendor.
**Token / effectiveness angle:** Its pitch (shared, governed memory across a team of agents so context isn't re-derived per session) is exactly our thrift goal, just solved with infra instead of files.
**How to adopt:** watch — re-check if team-shared (not per-user) agent memory becomes a real need.
