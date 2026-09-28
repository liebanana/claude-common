# anthropics/knowledge-work-plugins  ·  ⭐25329  ·  watch  ·  trending
https://github.com/anthropics/knowledge-work-plugins · pushed 2026-09-21 · triaged 2026-09-21 · seen on github-trending

**What it is:** Anthropic's own open-source plugin marketplace: 11 plugins (productivity, sales, customer-support, product-management, marketing, ...) built for Claude Cowork and compatible with Claude Code. Each plugin bundles the skills, connectors (Slack/Notion/Asana/Linear/Jira/HubSpot/etc.), slash commands, and sub-agents for one job function.

**Reusable for us:** No single extractable asset — it's a reference for how Anthropic itself structures a role-scoped plugin (skills + connectors + commands + subagents bundled together, meant to be customized per-company). Worth reading if we ever bundle a claude-common asset set into an installable plugin rather than loose files.

**Token / effectiveness angle:** n/a directly — this is about task completeness/consistency per role, not token thrift.

**How to adopt:** Watch. If a future claude-common asset needs company-specific customization (tools/terminology/process), model it on one of these plugins' structure rather than inventing a format from scratch.
