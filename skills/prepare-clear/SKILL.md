---
name: prepare-clear
description: Use when the user says "clear", "clear properly", "prepare to clear", "safe clear", "compact safely", "prepare to compact", or equivalent. Whole-session intentional context-retirement gate — drains new delegation, persists every session-owned task to a durable checkpoint, reconciles child/writer state, validates the handoff, preserves worktrees/dirty state/any supervisor mode, and emits CLEAR READY only when a cold session can safely rehydrate. This skill prepares a clear; it does not perform the actual context clear itself.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Drain-and-checkpoint gate before a context clear/compact — persist every session-owned task so a cold session can safely rehydrate
tags: [skill, handover, context-clear, resume, durability]
---

# Prepare to clear / compact safely

**Naming note:** never name a user-invocable skill after a Claude Code built-in (e.g. `clear`) — it shadows the built-in and makes the real command unreachable. This skill only prepares for the clear; the harness's own `/clear`/compact performs it, and the next session's recovery instruction is simply "rehydrate" (the `rehydrate` skill).

**Primary invariant:** a context window is disposable; task/worktree/control-plane state is not. **Never-stop invariant:** draining pauses this writer only long enough to make the handoff durable — it never marks the project blocked. **Forbidden:** `git reset --hard`, `git clean`, blanket `git stash`, `git add -A`/`.`, or any discard used to make a clear "look clean."

## Outcome

Every active writer/task has a valid durable identity; branch/HEAD/worktree/dirty state is recorded honestly; the latest review verdicts (PR comments, CI) are reconciled into next-actions; session-owned children are checkpointed or explicitly classified crashed/lost with worktrees preserved; no new task was admitted during the drain; leases/supervisor mode survive the clear; any repo-defined handoff validation passes for every task retiring; durable state is committed/pushed per repo policy; the final response is `CLEAR READY`, not "I saved some notes." If a task cannot be made recoverable without destructive guessing, return `CLEAR BLOCKED` with the exact failing task.

## Phase 0 — enter drain mode

Stop admitting new tasks, spawning subagents, or acquiring new writer leases; start no new implementation slice; do only bounded work required to make existing work recoverable; do not release current leases merely because context is ending. Track this internally as `DRAINING_FOR_CLEAR` — a transient session mode, never written as a project/task status.

## Phase 1 — refresh identity before writing the handoff

Read `AGENT-DIRECTIVE.md`, `CLAUDE.md`, this skill, and any task/checkpoint schema doc the repo defines, then inspect current durable state without pulling/resetting over work: the repo's own control-plane files if `CLAUDE.md` names them, and current repo/worktree state for every session-owned task. Per relevant repo/worktree record: repo, worktree, branch, full HEAD, remote branch/HEAD if available, `git status --short`, holder/session identity if known, task ID, latest applicable review verdict. A bounded `git fetch` may validate identity; never merge/rebase/reset.

## Phase 2 — drain and reconcile children/writers

Inventory every specialist/child/worktree this session owns or launched; classify each:
- **Done:** consume its handback, update the checkpoint, retire its lease only if the task is truly
  finished and policy says to release it.
- **Alive with work in progress:** require it to checkpoint/retire itself first, or hand off cleanly
  — never clear the parent while it holds uncheckpointed unique work.
- **Crashed/disappeared:** do not release/redelegate blindly — preserve its branch/worktree/dirty
  state, prove the old holder is gone when possible, reconcile the checkpoint with what you observe,
  and never spin up a replacement writer during drain.
- **Shared-worktree collision:** if multiple task identities own the same dirty paths, classify the
  collision explicitly and stop unsafe retirement for those tasks — never "solve" it with
  stash/reset/add-all.

## Phase 3 — reconcile verdicts before checkpointing NEXT

Refresh the latest applicable review verdict (PR review/comment, CI result) for every session-owned task in review/remediation/release. A newer verdict overrides a stale lifecycle projection — e.g. a blocking review comment on a "ready for review" task makes remediation the next action, on the same branch/worktree, blocker recorded. An approval applies only to the exact SHA it was given on, never a later commit. If remote state contradicts the checkpoint, reconcile that drift now, before Phase 4, so the cold session doesn't wake into a false review wait — don't schedule a duplicate push/review from stale prose.

## Phase 4 — checkpoint every session-owned task

The checkpoint is the handover doc — `docs/handovers/<date>-session-handover.md`, the format `/session-handover pause` defines — plus `.oracle/status.json` if this repo runs the oracle board. Do not invent a second format; if the repo's own `CLAUDE.md`/`AGENT-DIRECTIVE.md` names its own task/backlog/checkpoint files, update those too, in their own schema, alongside the handover. Make exact: status, updated timestamp, lease/branch/worktree identity, base SHA, head SHA, every dirty/untracked path classified `mine`/`other`/`unexpected`, completed work, current work, `next_exact_action` (executable and specific — "continue X" is invalid), findings handed upward, tests/evidence run, blockers (and whether human-only), a short cold-resume read-order, and control-plane artifacts touched.

**Dirty-work policy:** a safe clear does not require a clean tree. Commit on a clearly named branch when the slice is genuinely commit-ready under branch policy; otherwise leave the files where they are, list every dirty path truthfully, never fake a "WIP cleanup" commit to hide uncertainty, never stash, never discard, and make `next_exact_action` precise enough to continue from the dirty worktree. Persist reasoning that exists only in chat into the canonical spec/plan/decision/task artifact it belongs to — don't create a parallel narrative doc when one already exists.

## Phase 5 — validate every retiring task

If the repo defines a handoff-check command (named in its `CLAUDE.md`), run it for every task checkpoint this session hands off — every relevant task must pass; otherwise validate the handover doc against Phase 4's field list by hand. On failure, fix the checkpoint, not the validator, and rerun — never emit `CLEAR READY` while any is invalid. A missing checkpoint is itself a failure, and so is a vague next-action ("continue", "resume work", "check review") even if a schema parser would accept it.

## Phase 6 — persist the handoff durably

Stage exact paths only — never `git add -A`/`.`. Commit checkpoint/control-plane updates when valid and coherent; push per repo/branch policy and available credentials. If remote persistence is unavailable, record the exact prerequisite/blocker and keep local files intact. Never force unrelated task-implementation code into the same commit merely to land the checkpoint, and re-run handoff validation if the recorded HEAD/dirty state changed after a checkpoint commit.

## Phase 7 — preserve supervisor mode

An intentional clear is not automatically a handoff to an unattended supervisor/daemon (systemd unit, pm2, cron). Inspect current supervisor state, any STOP sentinel, and current child/lock/heartbeat identity when relevant. If the supervisor is intentionally stopped while this session works, leave it stopped — never delete a STOP sentinel the repo defines, never start/restart the supervisor merely because context is clearing, and never re-pin supervised code during clear preparation unless that was independently the current authorized task. After the actual clear, the `rehydrate` skill decides whether a controlled single-writer handoff back is appropriate.

## Phase 8 — final retirement gate

Verify all before declaring clear-safe:
- [ ] no new task/delegation admitted after drain began
- [ ] every session-owned task/worktree identity is known
- [ ] no unclassified dirty paths remain
- [ ] active child contexts are checkpointed or explicitly reconciled as crashed
- [ ] latest review verdicts are reflected in task status/blockers/next-action
- [ ] every retiring task passes the repo's handoff validation (if it defines one)
- [ ] durable checkpoint/control-plane changes are persisted as far as credentials permit
- [ ] leases were not silently released
- [ ] supervisor state was preserved; no competing writer was started
- [ ] the next cold action is simply the `rehydrate` skill / `/session-handover resume`

Only then respond:

```text
CLEAR READY
Tasks: <task IDs checkpointed>
Dirty: <none | preserved accurately in named worktrees>
Handoff validation: PASS <n>/<n> | not defined by this repo
Control plane: <commit/SHA, or exact local-only prerequisite>
Supervisor: <preserved state; no competing writer started>
After /clear: rehydrate
```

If any gate is unmet, respond instead with `CLEAR BLOCKED`, the failing task, the exact reason, and the specific bounded action required before clear — then perform that fix if it is safe to do so. Never call an unsafe handoff "good enough," and stop doing implementation work once `CLEAR READY` is sent — the user may now invoke the actual clear.

Relationship: `/session-handover pause` is the short form; this skill is the full drain protocol for sessions that own child agents, worktrees, or a supervisor.
