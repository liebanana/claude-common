---
name: rehydrate
description: Use when the user says "rehydrate", "resume after crash", "Claude crashed", "recover the session", "pick up where we left off", or equivalent. Whole-project crash/cold-start recovery — reconstruct current truth from durable repo/git/PR state, reconcile crashed worktrees and leases without destroying local work, consume the latest review verdicts, and resume the highest-priority safe work. Not a status-only skill.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Crash/cold-start recovery — rebuild truth from git and repo docs, reconcile stale checkpoints, resume real work instead of just reporting status
tags: [skill, recovery, crash-recovery, handover, resume]
---

# Rehydrate: crash / cold-start recovery

**Trigger contract:** on a bare "rehydrate" (or equivalent), invoke this immediately — do not ask
what happened and do not rely on the previous conversation. Repo + remote (PRs, comments, CI) is the
recovery authority, not chat memory.

**Primary invariant:** `WORK EXISTS + SAFE TO EXECUTE => KEEP WORKING`.

**Safety invariant:** recovery must never destroy, overwrite, duplicate, or silently abandon
pre-crash work. Never `git reset --hard`, `git clean`, blanket `git stash`, or `git add -A`, and
never start a new writer/worktree until existing ownership and dirty state are reconciled.

## Outcome

Reconstruct current repo/remote truth without chat memory; inventory every relevant worktree, dirty
file, checkpoint and active writer; reconcile newer review verdicts into stale checkpoint state;
choose and **resume actual work**, not merely print status; restore any supervisor/daemon through a
controlled handoff only when safe; persist enough evidence that the next crash recovers the same
way. If one lane is unsafe or blocked, park it truthfully and continue an independent lane.

## Phase R0 — enter recovery mode

Confirm the working directory is the repo root (locate the checkout if it moved). Read, in order:
`AGENT-DIRECTIVE.md`, `CLAUDE.md`, this skill, and any control-plane index doc `CLAUDE.md` names.
Treat any static SHA/status already in prose as a historical observation until revalidated. A
crash-recovery invocation authorizes safe/reversible recovery and normal already-authorized work —
not new authorization for destructive production changes or other separately gated actions.

## Phase R1 — refresh durable git truth, without mutating work

For every checkout that exists locally: `git fetch --all --prune` (bounded; a failure is a
prerequisite problem, not permission to guess); record branch + full HEAD, remote branch/head,
`git status --short`, `git worktree list --porcelain`, and recent relevant commits; do **not**
pull/merge/reset/rebase yet — inventory before touching anything. Then `gh pr list`/`gh pr view` for
open PRs relevant to in-flight work and their latest comments/verdicts. If the remote is temporarily
unreachable, preserve local state, classify that lane `WAITING_PREREQUISITE`, and do not fabricate
remote truth — continue safe work that doesn't need remote freshness.

## Phase R2 — rebuild the picture

Durable truth sources, in this order: (1) the repo's latest `docs/handovers/*-session-handover.md`
(the `/session-handover` convention); (2) `.oracle/status.json`, if present; (3) `git status`/`git
log`/`git worktree list`, open PRs (`gh pr list`); (4) any `AGENT-DIRECTIVE.md`/`CLAUDE.md` rules;
(5) the repo's own control-plane files (task/backlog/checkpoint docs) **if** its `CLAUDE.md` names
them — otherwise the handover doc IS the checkpoint. Read the newest applicable PR/issue comments,
not just bodies — a later comment can override an earlier verdict. Build a short recovery table
before editing anything: `item | repo | branch | checkpoint state | actual local SHA | remote SHA |
dirty | holder | latest verdict | true NEXT`.

## Phase R3 — reconcile crash residue and ownership

For every non-done item, compare its last recorded checkpoint against actual branch/HEAD, all
dirty/untracked paths, worktree path, and any live holder/process identity. A crashed or dead holder
does **not** free a writer automatically — prove the old holder is gone before adopting its
worktree/branch, and record the ownership transition. Never spawn a duplicate writer for a task
whose worktree/branch/dirty state already exists. A newer verdict (PR review, CI result, an explicit
decision recorded in the repo) overrides a stale checkpoint's lifecycle for that exact target — an
approval applies only to the exact SHA it was given on, never to a later commit. If a checkpoint's
remote claim disagrees with the actual remote, resolve that drift before acting — don't repeat a
push/review request because a stale checkpoint said it was needed.

## Phase R4 — select actual work

Derive the validated executable next step, not the stale textual plan. Priority: a safe blocking fix
with a concrete next step, then already-approved standing-authorized work, then control-plane
defects that would make cold resume itself lose work, then other independent work. Human-only or
destructive actions block only their own lane. **Do not stop after producing a recovery report** —
once one safe lane is reconciled, execute its next concrete step; if it becomes blocked, checkpoint
it and move to another safe independent lane.

## Phase R5 — runtime recovery

If the repo runs a supervisor/daemon (systemd unit, pm2 app, cron job), discover its real name from
the repo's own docs — never guess it — and revalidate that the running code actually matches the
approved/intended HEAD before trusting it. Honor any STOP sentinel the repo defines; never delete or
bypass it. Before resuming or restarting the supervisor, do a controlled single-writer handoff:
finish the current bounded slice, update any checkpoint it affects, commit durable progress, confirm
no unreconciled dirty writer state remains, then hand back. If it's already active and healthy,
don't restart it gratuitously — reconcile whether this session would conflict and prefer one writer.

## Phase R6 — crash-proof the recovery itself

Before ending, persist: current repo/branch/HEAD identities, recovered worktree/holder decisions,
dirty-state disposition, the latest verdict consumed, work actually completed, the exact next
action, supervisor status if touched, and any true human-only blocker. Run any handoff validation
the repo defines for every item touched. A recovery is **not** successful if the only output is
"rehydrated" while safe executable work remains untouched.

## Hard rules

Read-only until the picture in R2 is rebuilt. Never `git stash`, `reset --hard`, or force-push as a
"fix" for drift. Never assume a child agent is dead without evidence. Re-arm any watches/monitors
the handover names. Always end with the compact report below. Finish by running `/oracle-status` if
that command exists in this repo.

## Compact report format

```text
REHYDRATED
Repos: <current branch/HEAD per repo>
Recovered: <task/worktree identities>
Executed: <what changed, with exact SHA if committed>
NEXT: <concrete next action>
Blockers: <none | exact human-only action required>
```

Then continue autonomous execution unless the session has intentionally handed the writer role back
to a supervisor.

Relationship: `/session-handover resume` is the 5-minute version of this; use this skill when the
last session did not end with a handover (crash, kill, context loss).
