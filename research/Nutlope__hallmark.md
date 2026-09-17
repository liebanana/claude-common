# Nutlope/hallmark  ·  ⭐n/a  ·  watch  ·  trending
https://github.com/Nutlope/hallmark · triaged 2026-07-27 · seen on github-trending

**What it is:** A design skill for Claude Code/Cursor/Codex (by Together AI) that picks a macrostructure + one of twenty themes, runs 57 "slop-test" gates plus a pre-emit self-critique, to stop generated UI looking like default AI-generated templates. Ships `audit`/`redesign`/`study` verbs too.
**Reusable for us:** overlaps with our existing `frontend-design` skill's goal (distinctive, non-templated UI); its slop-test-gate + self-critique mechanism is a concrete technique we don't currently encode.
**Token / effectiveness angle:** n/a directly, but a good gate pattern (self-critique before emit) is generally reusable for quality control in any generation skill.
**How to adopt:** watch — compare its slop-test gate list against `frontend-design`'s current heuristics; if it's meaningfully more rigorous, port the gate-list technique (not the whole skill) into ours.
