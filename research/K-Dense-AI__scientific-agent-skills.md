# K-Dense-AI/scientific-agent-skills  ·  ⭐40446  ·  watch  ·  stable
https://github.com/K-Dense-AI/scientific-agent-skills · pushed 2026-08-31 · triaged 2026-08-31 · seen on github-trending

**What it is:** A large, actively maintained collection of 163 domain-specific research skills (genomics, PK/PD modelling, literature retrieval, molecular dynamics, etc.) packaged as one portable Agent Plugin, working across Claude Code, Cursor, Codex, and any Agent Skills-standard client.
**Reusable for us:** The domain skills themselves don't apply to us, but the packaging shape — a single `plugin.json` bundling many independent `skills/` — is a concrete precedent for bundling claude-common's own commands/agents as one installable plugin instead of relying on install.sh symlinks.
**Token / effectiveness angle:** n/a for us directly; the pattern (one plugin, many skills, works across multiple agent clients) is the transferable part.
**How to adopt:** watch — revisit plugin.json layout if/when claude-common moves from symlink install to a proper Claude Code plugin.
