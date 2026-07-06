# alibaba/page-agent  ·  ⭐24486  ·  watch  ·  trending
https://github.com/alibaba/page-agent · pushed 2026-07-06 · triaged 2026-07-06 · seen on github-trending · 3151↑

**What it is:** A JS library that embeds a GUI agent directly into a webpage — one script tag gives any page its own AI agent that manipulates the DOM via text (no screenshots, no multi-modal model needed), plus an optional Chrome extension for multi-page tasks and a beta MCP server to control it externally.
**Reusable for us:** Different niche from Claude Code itself (this is for embedding an agent *into a product's UI*, not for coding-agent tooling), but the MCP server surface means it could be a control point if we ever needed an agent to drive a specific web app's own in-page agent rather than a generic browser.
**Token / effectiveness angle:** Text-based DOM manipulation instead of screenshots is a real token/cost win for anyone building this kind of product feature, but it's orthogonal to our own Claude Code workflows.
**How to adopt:** Watch. Not directly actionable for this repo's mission; relevant only if a downstream project embeds an in-page agent.
