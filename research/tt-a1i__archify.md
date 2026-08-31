# tt-a1i/archify  ·  ⭐37413  ·  adopt  ·  trending
https://github.com/tt-a1i/archify · pushed 2026-08-31 · triaged 2026-08-31 · seen on github-trending

**What it is:** A Node.js rendering/validation system that turns a codebase or system description into a polished, interactive system map, directly from agent chat. Agents emit typed JSON IR; Archify deterministically compiles it into self-contained HTML/SVG (plus PNG/WebM/share-card exports) — five diagram types, before/after diff review for architecture changes, and revision-verified source tracing.
**Reusable for us:** Installable as a global Agent Skill (`npx skills add tt-a1i/archify -g`) for Claude Code, Cursor, Codex CLI, OpenCode. Could replace ad-hoc ASCII/mermaid diagrams in our own docs or PR descriptions with something more inspectable and shareable.
**Token / effectiveness angle:** Deterministic compile step (not another LLM call) keeps diagram generation cheap and repeatable once the JSON IR is produced.
**How to adopt:** Trial it in a real repo (`npx skills add tt-a1i/archify -g`) on an architecture-review task and record field notes before recommending wider use.
