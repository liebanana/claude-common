# yusufkaraaslan/Skill_Seekers  ·  ⭐14506  ·  adopt  ·  stable
https://github.com/yusufkaraaslan/Skill_Seekers · pushed 2026-07-20 · triaged 2026-07-20 · seen on github

**What it is:** A mature (v3.7, 3700+ tests, MCP integration with 40 tools) tool that converts documentation websites, GitHub repos, and PDFs into Claude AI skills automatically, with conflict detection against existing skills.
**Reusable for us:** Directly useful for claude-common's own "growing the catalog" workflow — instead of hand-writing a skill stub for every adopted external tool, this could generate a first draft skill from a tool's own docs, which we then review/trim. Also useful for onboarding third-party library docs (e.g. framework docs) into skill form for other repos.
**Token / effectiveness angle:** Speeds up skill authoring (a one-time cost), which indirectly saves tokens by avoiding future agents re-deriving usage patterns from raw docs each session.
**How to adopt:** Trial it against one pending "watch"/"adopt" candidate from this ledger (e.g. generate a skill draft from `rtk-ai/rtk`'s docs) and see if the output is usable with light editing; record field notes.
