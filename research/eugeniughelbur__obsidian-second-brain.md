# eugeniughelbur/obsidian-second-brain  ·  ⭐4566  ·  watch  ·  emerging
https://github.com/eugeniughelbur/obsidian-second-brain · pushed 2026-09-20 · triaged 2026-09-21 · seen on github

**What it is:** Cross-CLI persistent memory (Claude Code, Codex, Gemini, OpenCode, Antigravity, Hermes, Pi, Grok Bot) stored as plain markdown in an Obsidian vault. 45 commands covering hybrid semantic search, self-rewriting notes, key-less web research, and scheduled agents that maintain the vault unattended.

**Reusable for us:** A different architecture from our own file-based memory system: it stores memory in a user-facing Obsidian vault (so a human can browse/edit it directly), does semantic (not just keyword) recall, and has notes that rewrite themselves over time instead of just accumulating. Our current memory is closer to append-only markdown + an index. Worth comparing if our memory system ever needs semantic search or self-pruning.

**Token / effectiveness angle:** "Claude gets the same context injected on every prompt" (proactive push, not on-demand grep) is the same philosophy our MEMORY.md index already uses; the semantic-search and self-rewriting-note pieces are the novel bits.

**How to adopt:** Watch. If our own memory system starts feeling stale (notes never revised, only added) or recall-by-keyword starts missing things, revisit this repo's self-rewriting-note and semantic-search design.
