# raiyanyahya/recall  ·  ⭐717  ·  adopt  ·  emerging
https://github.com/raiyanyahya/recall · pushed 2026-07-18 · triaged 2026-07-20 · seen on github

**What it is:** Fully-local project memory for Claude Code. Logs sessions and condenses them into a resume-ready `context.md` summary using a classical (non-LLM) Python summarizer — no API key, nothing sent anywhere, zero model tokens spent to capture/update memory.
**Reusable for us:** Solves the same "cold start, re-explain the project every session" problem our own persistent memory system (`~/.claude/projects/.../memory/`) addresses, but scoped to raw Claude Code (any project, no built-in memory harness) and at literally zero token cost since it doesn't call an LLM to summarize.
**Token / effectiveness angle:** Two-sided: capturing memory costs zero tokens (classical summarizer, not an LLM call), and resuming from a ~1-2K token `context.md` beats re-explaining a project from scratch.
**How to adopt:** Trial on a project that lacks harness-level persistent memory (e.g. a host without this memory system wired up) and compare resume quality/cost against manually re-explaining context; record field notes before recommending broadly.
