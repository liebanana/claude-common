---
name: backlog-execute
description: Use when asked to work the backlog by priority and usefulness ("implement what's next", "work the audit findings"), or as the executor step of the project's single recurring loop. Scores open backlog rows by impact (not ease), shows the picked items with reasons, and runs each through the full workflow ANALYZE -> BRAINSTORM -> SPEC -> PLAN -> IMPLEMENT -> deterministic QA -> review gate -> release with serving verification, asking the owner only for decisions that are truly theirs. Supports --dry-run (score and explain only).
kind: skill
status: experimental
group: Reusable Claude Code assets
intent: Execute the top-scored backlog items (max N, one git worktree each) through analyze-to-release with deterministic QA, review gate and serving verification; never bypasses a gate
tags: [skill, backlog, workflow, worktree, release, qa, prioritization]
---

# Backlog executor

Takes the highest-impact open backlog rows and drives each through a visible, gated workflow. Composes with
`solution-audit` (files the rows), `backlog-review` (the mandatory first step), and the project's handoff/rehydrate skills.

## Adapting to your project

The project must supply (declare in its CLAUDE.md or a docs page; ask once and record if missing):

- Everything `backlog-review` needs: backlog file + row schema, status vocabulary, audience weights, severity scale, owner decision step.
- **Concurrency cap N** (default 2) and the rule for worktrees (location, naming, cleanup).
- **Spec/plan location** (where SPEC and PLAN documents are persisted so a cold agent can resume).
- **QA commands**: type-check, lint, tests, project-specific consistency gates (docs freshness, solutions-index check...).
  Deterministic tests should include a deliberate-RED proof (the new test fails without the fix).
- **Review gate** for user-facing changes (screenshots on declared devices/themes/locales, a founder/owner-proxy reviewer,
  persona or domain-expert passes, accessibility). Which changes require which review.
- **Model policy**: which model tier per role. If none, the floor is: implementer from prose = mid tier; mechanical
  transcription = low tier; final review / hard judgment = top tier; never default everything to the top tier.
- **Release procedure**: CI-green-on-exact-SHA rule, merge method, deploy command, **serving verification** (how to prove
  the intended SHA/build is what is actually live), the release/deploy log to append, rollback.
- **Operational constraints**: deploy-freeze windows (e.g. no deploy while CI runs on a shared host), the data/schema
  change path (e.g. migrations only through a reviewed owner script), and where secrets live (never in the repo).
- **Escalation channel** for owner-only actions (login, sudo, a decision, a production apply the automation may not run).

## Hard rules

- **Never bypass a gate.** No `--no-verify`, no skipping CI, no merging without the review gate the project requires, no
  weakening a test to get green, no production data/schema change outside the project's declared path. A gate that cannot
  run is a blocker to report, not a step to skip.
- **Ease is never the reason to pick an item.** Order comes from `backlog-review` scoring.
- **One writer per checkout.** At most N items at a time, each in its **own git worktree** off the default branch; never
  branch or commit in a checkout that a deploy is using.
- **Every wait/poll loop is bounded:** `timeout <s> bash -c 'until <cond>; do sleep <n>; done' || echo FAIL`, or an iteration
  cap that prints FAIL on expiry. Never `pgrep -f` a pattern contained in the loop's own command. Prove CLI JSON field names
  once before polling on them. Put this rule in every sub-agent prompt that may wait on CI. If a notification reveals a
  long-running agent or loop, inspect it and stop it at once.
- **Phases scale with size, none is skipped silently** - a one-line fix compresses them into a few visible sentences.
- No secrets in files, rows, logs or commit messages.

## Steps

1. **Run `backlog-review` first** and wait for the owner to choose - never start work "all in" unprompted. Only an explicit
   pick (or a loop run carrying a standing instruction) proceeds. `--dry-run` stops after the review (no writes at all).
2. **Pick up to N independent items** (no shared files or ordering dependency). Create one worktree per item.
3. **Run the workflow visibly for each item:**
   - **ANALYZE** - facts from code/data/logs, reproduce, root cause before remedy.
   - **BRAINSTORM** - real options including "do nothing", with trade-offs. For a design question ask the owner with
     options, recommendation first.
   - **SPEC** - what changes, what "done" means, non-goals, how it will be verified; persist it in the spec location.
   - **PLAN** - ordered steps, touch points, tests, deploy/rollback, sibling consumers of any shared primitive.
   - **IMPLEMENT** - test-first, via the right agent/role with an explicit `model:` per the model policy; update solutions-index
     or documentation cells the change touches.
   - **Deterministic QA** - the project's QA commands, plus the deliberate-RED proof; fix root causes rather than loosening checks.
   - **Review gate** - for user-facing changes run the project's declared review (real screenshots, owner-proxy, persona,
     expert); fold in must-fix findings and re-run QA. Cap review ping-pong at 3 NOT-READY rounds per item, then freeze,
     disclose what is unresolved, and move on.
   - **Release** - CI green on the exact SHA -> merge as the project dictates -> check deploy-freeze constraints -> deploy ->
     **serving verification** (the live build/version equals the intended SHA; re-runnable evidence) -> append the release log.
     Anything the automation may not run (production apply, login, sudo) becomes an owner-only action: package the exact
     command, say what to paste back, and continue on unblocked work.
4. **Checkpoint each row** (status, SHAs, next action) in the backlog and push per the project's flow, so a cold agent can resume.
5. **Report in chat (short):** what shipped (one line each, with the verified SHA/version), what waits on the owner (exact
   commands + what to paste back), what is next by score, and anything frozen after 3 rounds.
