# openai/codex-plugin-cc  ·  ⭐28302  ·  adopt  ·  trending
https://github.com/openai/codex-plugin-cc · pushed 2026-07-08 · triaged 2026-07-13 · seen on github, github-trending

**What it is:** Official Claude Code plugin that lets you invoke OpenAI Codex from inside a Claude Code session — `/codex:review`, `/codex:adversarial-review`, plus delegate/transfer/status/cancel commands for background Codex jobs.
**Reusable for us:** A second-opinion/adversarial code-review pathway without leaving Claude Code — complements our own `/code-review` skill rather than replacing it (different model, same session). Requires a ChatGPT/OpenAI Codex subscription or API key.
**Token / effectiveness angle:** Delegating a review to a different model is a cheap way to get an independent pass without spending our own context re-reading the diff.
**How to adopt:** Recommend to the user if they have Codex access: `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai-codex`. Not installed by us (needs external subscription + user's own decision).
