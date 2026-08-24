# volcengine/OpenViking  ·  ⭐32857  ·  watch  ·  trending
https://github.com/volcengine/OpenViking · pushed 2026-08-24 · triaged 2026-08-24 · seen on github-trending

**What it is:** Open-source "context database" for AI agents — stores memories/resources/skills as a virtual filesystem (`viking://`) with tiered loading (L0 abstract → L1 overview → L2 full detail), so an agent browses context like a directory tree instead of querying an opaque vector store. Ships as a Python server (`pip install openviking`) with providers for Volcengine/OpenAI/Codex OAuth/Kimi/GLM/Ollama.
**Reusable for us:** Not a drop-in asset — it's a standalone server/dependency, not a script or hook. The *technique* is the reusable part: tiered (abstract/overview/detail) context loading is directly the same problem our own memory system and `research/INDEX.md` solve, just formalized. Their published benchmarks (LoCoMo, tau2-bench) claim 34–91% input-token reduction and accuracy gains vs native agent memory.
**Token / effectiveness angle:** Directly on-mission (token thrift via tiered retrieval) — worth reading their benchmark write-up for retrieval-design ideas even without adopting the server.
**How to adopt:** Watch. Too heavy to vendor (own server + provider config); revisit if a lightweight client/MCP wrapper emerges, or mine the architecture doc for retrieval-tiering ideas.
