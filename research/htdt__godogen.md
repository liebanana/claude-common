# htdt/godogen  ·  ⭐n/a  ·  watch  ·  emerging
https://github.com/htdt/godogen · triaged 2026-08-17 · seen on hackernews

**What it is:** A generator that publishes thin per-game repos (runtime manifest + one-page engine guide + asset-generation skill) which a Claude Code or Codex agent then runs to build a full Godot/Bevy/Babylon.js game — generating assets via Gemini/Grok/Tripo3D and proving results from a live/recorded run rather than a clean compile.
**Reusable for us:** Niche (game dev), but the pattern — publish a minimal guide + skill, let the agent regenerate the rest, and judge success from a live artifact/recording instead of "it compiled" — is a good example of "proof over claims" agent design worth remembering.
**Token / effectiveness angle:** Thin published repos (guide + skill, not full scaffolding) keep the agent's context small; regenerating boilerplate beats re-reading it.
**How to adopt:** watch — not directly portable outside game dev, but revisit the "thin manifest + agent regenerates scaffold" pattern if we build a similar generator here.
