# Hainrixz/the-architect  ·  ⭐506  ·  watch  ·  emerging
https://github.com/Hainrixz/the-architect · pushed 2026-07-28 · triaged 2026-09-21 · seen on github

**What it is:** A Claude Code plugin/meta-agent that interviews the user about what to build, picks a stack, and writes a self-contained markdown "blueprint" (EARS-style acceptance criteria plus a runnable verify command per step) that a *different* Claude Code instance, with zero prior context, can build from without asking questions. Covers 14 project shapes, greenfield and brownfield, EN/ES.

**Reusable for us:** The "zero-context handoff blueprint with a runnable verify command per step" pattern is directly relevant to our `writing-plans` skill and `session-handover` skill — both already aim for a plan a fresh session can pick up, but this repo's EARS-acceptance-criteria + per-step verify command is a more rigorous, checkable format than plain prose steps.

**Token / effectiveness angle:** A zero-context-resumable blueprint avoids re-deriving intent/scope from a stale conversation — same motivation as `session-handover`.

**How to adopt:** Watch. Next time `writing-plans` or `session-handover` gets revised, compare its blueprint format (EARS criteria + per-step verify command) against ours for concrete phrasing/structure to borrow.
