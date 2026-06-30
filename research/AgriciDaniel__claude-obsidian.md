# AgriciDaniel/claude-obsidian  ·  ⭐8350  ·  watch
https://github.com/AgriciDaniel/claude-obsidian · pushed 2026-05-28 · triaged 2026-06-30

**What it is:** A self-organizing "AI second brain" for Obsidian + Claude Code (MIT). 15 Claude Code skills that ingest sources into a compounding Markdown wiki. v1.7 adds hybrid retrieval (contextual prefix + BM25 + cosine rerank, per Anthropic's contextual-retrieval research) and per-file advisory locking for multi-writer safety.
**Reusable for us:** Two memory techniques worth noting against our `memory/` + `MEMORY.md` system: (1) **per-file advisory locking** to avoid multi-writer corruption when several agents touch the same memory store; (2) **hybrid retrieval** (contextual prefix + BM25 + rerank) for recalling the right note. Both are tied to Obsidian here but portable in principle.
**Token / effectiveness angle:** Contextual retrieval pulls only the relevant note instead of loading a whole vault — directly a context-economy play; compounding wiki avoids re-deriving prior research.
**How to adopt:** Watch. If our memory store ever gets multi-writer (concurrent agents) or large enough to need ranked recall, lift the advisory-lock + hybrid-retrieval patterns. Not actionable now.
