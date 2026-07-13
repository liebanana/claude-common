# htdt/godogen  ·  ⭐4687  ·  watch  ·  emerging
https://github.com/htdt/godogen · pushed 2026-07-12 · triaged 2026-07-13 · seen on hackernews

**What it is:** A generator that publishes a "thin" game repo (runtime manifest + one-page engine guide + an asset-generation skill) which an autonomous Claude Code/Codex agent then expands into a full playable game (Godot/Bevy/Babylon.js), running the engine and recording proof of the result.
**Reusable for us:** Not a tool we'd adopt directly, but a good reference pattern for "thin scaffold + skill + agent fills in the rest" — the same shape as this repo's own skill/command model, applied to a different domain.
**Token / effectiveness angle:** n/a directly; the pattern (ship a short guide, let the agent regenerate the rest) is itself a token-thrift technique worth remembering.
**How to adopt:** Watch as a design-pattern reference, not as a dependency.
