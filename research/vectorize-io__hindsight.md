# vectorize-io/hindsight  ·  ⭐40042  ·  watch  ·  trending
https://github.com/vectorize-io/hindsight · pushed 2026-09-28 · triaged 2026-09-28 · seen on github-trending

**What it is:** An agent memory system (server + clients) built around retain/recall/reflect operations, claiming SOTA on the LongMemEval benchmark and used in production at some enterprises.
**Reusable for us:** None directly — it's a Docker/Postgres server + Python/Node client stack, not a script or command we'd drop in. Worth noting the pattern of shipping an installable "docs skill" for coding agents (`npx skills add <repo> --skill hindsight-docs`) — a distribution technique claude-common could imitate for its own docs.
**Token / effectiveness angle:** Persistent cross-session agent memory is conceptually adjacent to what `/contribute-to-common` does manually (durable knowledge instead of re-deriving); Hindsight automates that for conversational agents, but at the cost of running a full server.
**How to adopt:** watch — re-check if a lightweight (no-server) memory technique emerges from this project.
