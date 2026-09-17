# openai/codex-plugin-cc  ·  ⭐26096  ·  adopt  ·  trending
https://github.com/openai/codex-plugin-cc · pushed 2026-06-23 · triaged 2026-07-06 · seen on github-trending · 3405↑

**What it is:** An official OpenAI-published Claude Code plugin that lets you invoke Codex from inside a Claude Code session — `/codex:review`, `/codex:adversarial-review`, plus `/codex:rescue`/`/codex:transfer`/`/codex:status`/`/codex:result`/`/codex:cancel` to delegate work and manage background jobs. Requires a ChatGPT subscription or OpenAI API key.
**Reusable for us:** A genuine cross-model second-opinion workflow — similar in spirit to this repo's own `/code-review` but backed by a different model family, useful for catching blind spots a single model might share with itself.
**Token / effectiveness angle:** Not about Claude token cost — it's a way to get independent review without spinning up a separate tool, and its own usage draws from Codex/ChatGPT limits, not Claude's.
**How to adopt:** Install via `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai-codex` in a session that already has a ChatGPT/OpenAI credential. Not stubbed into this repo (it's an external plugin marketplace entry, not something we vendor) — recommend to the user rather than auto-installing, since it needs a separate paid credential.
