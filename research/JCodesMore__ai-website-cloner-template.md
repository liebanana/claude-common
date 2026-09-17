# JCodesMore/ai-website-cloner-template  ·  ⭐26115  ·  watch  ·  trending
https://github.com/JCodesMore/ai-website-cloner-template · pushed 2026-07-04 · triaged 2026-07-06 · seen on github-trending · 3246↑

**What it is:** A GitHub template repo + Claude Code skill (`/clone-website`) that points an agent at a URL, has it extract design tokens/assets, write component specs, and dispatch parallel builders to reconstruct the site as a Next.js codebase.
**Reusable for us:** Niche (web-cloning specifically), but the pattern — a skill that inspects a target, writes specs, then fans out parallel builder subagents — is a reusable orchestration shape worth remembering, not the template itself.
**Token / effectiveness angle:** n/a directly.
**How to adopt:** Watch. If we ever build a similar "inspect → spec → parallel build" skill, reference this repo's `/clone-website` skill structure rather than reinventing.
