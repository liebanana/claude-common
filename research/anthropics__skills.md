# anthropics/skills  ·  ⭐trending(+2698/wk)  ·  adopt  ·  stable
https://github.com/anthropics/skills · pushed 2026-08-17 · triaged 2026-08-17 · seen on github-trending

**What it is:** Anthropic's own repository of example Agent Skills (creative, technical, enterprise, plus the docx/pdf/pptx/xlsx skills that power Claude's document features) and the Agent Skills spec/template — the canonical reference for how `SKILL.md` (frontmatter + instructions) should be structured. Installable as a Claude Code plugin marketplace.
**Reusable for us:** Canonical pattern reference for authoring our own `.claude/commands/` and any future skills in this repo — when writing a new skill, check the `template-skill` and a few example skills here for structure/conventions before inventing our own.
**Token / effectiveness angle:** Skills are Anthropic's own token-thrift mechanism (load instructions only when relevant) — directly on-mission as a reference implementation.
**How to adopt:** adopt as a reference — no code to copy in, just consult when authoring skills; optionally `/plugin marketplace add anthropics/skills` if the user wants the example/document skills installed.
