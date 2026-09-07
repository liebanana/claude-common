# htdt/godogen  ·  ⭐6748  ·  watch  ·  trending
https://github.com/htdt/godogen · pushed 2026-09-04 · triaged 2026-09-07 · seen on hackernews

**What it is:** A generator (`godogen -> game repo -> game`) that publishes a thin per-engine skill kit (runtime manifest, one-page engine guide, cross-engine asset-generation skill) into a fresh repo, then lets Claude Code or Codex autonomously build, run, and record a Godot/Bevy/Babylon.js game from a short prompt.
**Reusable for us:** Not a drop-in asset (game-dev domain), but the **publish-time render** pattern is a good reference: source repo stays thin/generic, `publish.sh` renders engine + host-agent-specific variants into the target repo rather than shipping one bloated multi-engine bundle. Similar shape to how our own `install.sh` symlinks a subset of assets into a consuming repo.
**Token / effectiveness angle:** The agent "recreates everything else from the guide" rather than the repo carrying full scaffolding — keeps the published skill kit small, agent fills the gap at build time.
**How to adopt:** Watch. Revisit the publish-time-render idea if `install.sh`/asset distribution here ever needs per-consumer variants.
