# htdt/godogen  ·  ⭐5574  ·  watch  ·  emerging
https://github.com/htdt/godogen · pushed 2026-07-26 · triaged 2026-08-24 · seen on hackernews

**What it is:** A generator for autonomous game-development agent repos (Godot/Bevy/Babylon.js). `godogen -> game repo -> game`: publishing renders a deliberately thin target repo (a runtime manifest, one-page per-engine guide, and an asset-generation skill) into which Claude Code or Codex is pointed; the agent reconstructs the rest and proves the result via a live URL or a recorded clip rather than a clean compile.
**Reusable for us:** Not a drop-in asset (game-dev specific, pulls in Gemini/Grok/Tripo3D API keys), but the scaffolding pattern is a good reference for our own `.claude/commands` and `.claude/agents` design: publish the *minimum* an agent needs to regenerate the rest (manifest + guide + skill) instead of a full pre-built project, and judge completion by proof-of-running-artifact rather than by "it compiled."
**Token / effectiveness angle:** The thin-repo-plus-skill pattern is itself a token-thrift technique — the published repo carries no dead weight, only what's needed to bootstrap.
**How to adopt:** Watch. No direct install; mine the "thin published repo, agent reconstructs the rest, proof over claims" pattern next time we design a new command/skill scaffold.
