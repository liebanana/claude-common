# yonatangross/orchestkit  ·  ⭐280  ·  watch  ·  emerging
https://github.com/yonatangross/orchestkit · pushed 2026-09-21 · triaged 2026-09-21 · seen on github

**What it is:** "The Complete AI Development Toolkit for Claude Code" — 107 skills, 36 agents, 171 hooks, its own `ork` CLI installer, skill browser, demo gallery, setup wizard, and a WhatsApp community. Also ships a slimmed-down Cursor variant.

**Reusable for us:** No single asset to extract — it's a large, actively maintained, heavily productized bundle that overlaps broadly with claude-common's own scope (skills + agents + hooks for Claude Code). Given the scale (171 hooks alone), it's a plausible source of specific hook ideas we haven't thought of, but adopting wholesale would duplicate/compete with our own curated catalog rather than complement it.

**Token / effectiveness angle:** Not assessed at README level — would need to install and inspect specific hooks/skills to judge overhead vs. value.

**How to adopt:** Watch. If we need a hook for a specific problem (e.g. a particular lint/format/test gate) and can't find one in our own `hooks/`, check this repo's 171 hooks before writing one from scratch.
