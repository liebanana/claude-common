# mattpocock/skills  ·  ⭐n/a  ·  watch  ·  trending
https://github.com/mattpocock/skills · triaged 2026-07-27 · seen on github-trending

**What it is:** Matt Pocock's personal library of Claude Code / Codex agent skills for "real engineering" (alignment via grilling questions, verbosity control, ticket triage, docs, etc.), installable via `skills.sh` (copied, editable) or as a native Claude Code plugin (managed, read-only bundle).
**Reusable for us:** several individual skills look directly relevant to our own goals — `/grill-me` and `/grill-with-docs` overlap with our brainstorming/planning skills; worth diffing their skill set against our `.claude/commands` + `superpowers` skills for gaps (e.g. verbosity control, ticket-tracker integration).
**Token / effectiveness angle:** explicitly targets the "agent didn't do what I want" and "agent is too verbose" failure modes — same token-thrift spirit as this repo.
**How to adopt:** watch→trial — install via `npx skills@latest add mattpocock/skills` in a scratch repo, compare individual skills (esp. grill-me, triage) against what we already have, and port anything genuinely additive as its own asset with attribution rather than adopting the whole bundle.
