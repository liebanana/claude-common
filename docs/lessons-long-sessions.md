---
kind: doc
status: ready
group: Save tokens / work efficiently
intent: Concrete lessons from a long multi-agent build session — process, verification, git/LFS in cloud sessions, user communication, art pipelines, subagent hygiene and model-per-role
tags: [practices, lessons, process, subagents, communication]
---

# Lessons from long agent sessions

Short, concrete, learned the hard way on a multi-day build orchestrating dozens of subagents.

1. **Big work: brainstorm → spec → plan before any code, never skipped.** Use the superpowers flow: brainstorming (put the questions on a `decisions-page`), an approved spec in `docs/specs/`, a plan in `docs/plans/`, then implementation with TDD. Launching implementation before the spec was approved cost a rewrite.
2. **Research existing public solutions first.** Before building an engine, pipeline or tool, search for what already exists (repos, libraries, docs). Adopt, wrap or copy the approach; build only the gap.
3. **The gate is CI on a clean clone, not local `verify`.** A `.gitignore` pattern `data/` silently swallowed a source directory: it existed only in the session, local checks passed, a clean clone broke. After every push check CI, or run the full verify in a fresh clone. Review `git status --ignored` when a directory seems "missing" from commits.
4. **Git LFS is blocked in cloud sessions.** Keep raw/large artifacts (audio, PSDs, renders) out of git, or handle LFS from a local machine. Do not rely on `git lfs` working inside the sandbox.
5. **User communication: short chat.** A few lines: what to see, what to do, what to decide. Details go to files or pages (link only). No recaps, progress tables or narration of agents. Ask via a decisions page, not in chat. Debate decisions with evidence and a counter-proposal, in both directions: correct the user when needed, and let them reopen yours; the final call is theirs and gets logged.
6. **Art by agents "drawing" pixel-by-pixel failed.** Hand-written sprite text/code looks wrong and burns tokens. Use a generation pipeline with specialist tools (image/music/voice generators, palette and atlas compilers), keep a human approving outputs, and gate paid calls (`paid-generation-gate`).
7. **Kill subagents that linger.** Agents that leave background work running keep spending; stop them (TaskStop) as soon as their report is in. Subagents never commit; the main session integrates, tests and pushes.
8. **Set an explicit model per role.** Cheap models for brainstorming banks, mid-tier for implementation and research, the strongest for design/art direction review and final audits. Inheriting the session model over- or under-provisions every stage.
9. **Map dependencies before changing a feature** (`feature-impact-graph`): the neighbours of a rule are its other side, UI, tests and docs.
10. **Verify before claiming.** Grep for each fix you are about to claim (`verify-fix-claims`) and cite commands that actually exist (`ls` first).
