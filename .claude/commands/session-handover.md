---
description: Pause a long autonomous lane safely (everything durable in git, dated handover with exact resume steps) and resume it in the next session (rehydrate from the repo, re-arm watches, continue)
argument-hint: "[pause | resume]"
kind: command
status: ready
group: Reusable Claude Code assets
intent: Pause/resume ritual for long autonomous lanes — nothing needed by the next session lives in a scratchpad, a monitor or chat
tags: [handover, context-clear, resume, durability, orchestration]
---

# /session-handover [pause | resume]

Full protocols: the `prepare-clear` skill (drain + checkpoint before a clear) and the `rehydrate`
skill (recover after a crash) — this command is the short form.

The next session has none of this one's memory, background tasks, monitors or scratch files.
Only the repository (and its remote: PRs, comments, CI) survives. This command makes a
deliberate context clear safe, and makes resuming mechanical. Default to `pause` when the user
says "pause", "clear", "handover"; to `resume` on "resume", "pick up where we left off", or when a
`docs/handovers/*-session-handover.md` newer than the current work exists.

## `pause` — before the clear

Do every item; do not skip one because it "probably" holds.

1. **Stop mutations.** Finish or cancel in-flight workers; start no new source change. Note every
   background task / monitor / workflow id and what it was waiting for — they die with the session.
2. **Scratch → repo.** List the session scratchpad and temp dirs. Anything the next session would
   need — a drafted handoff or PR comment, a reusable orchestration script, a prepared migration,
   a gate runner, evidence numbers, an execution log — moves INTO the repository under a dated,
   discoverable path (`docs/handovers/`, `docs/prompts/`, `scripts/`, the lane's evidence record).
   Prefer a deterministic *generator* (a script that regenerates the artifact from current sources
   and refuses on drift) over a snapshot that goes stale.
3. **Status docs current.** The lane's evidence/status docs carry exact HEAD SHAs, what is
   converged / held / blocked, and who owns the next action (agent, reviewer, human). Placeholders
   only where a value cannot exist yet (a future CI run id), and list them by name in the handover.
   - Run `/oracle-status` so `.oracle/status.json` matches the handover (the board reads only that file).
4. **Every worktree clean and pushed.** Per worktree: `git status` clean; `git rev-parse HEAD` equals
   `origin/<branch>`; the PR head equals it. Never force-push; never checkout across worktrees.
5. **Write the handover** `docs/handovers/<YYYY-MM-DD>-session-handover.md`:
   - a state table (lane / branch / PR / HEAD / state), naming the *source* head separately from
     docs-only commits on top and giving the one command that verifies the source tree is unchanged
     (`git diff --stat <source-sha> origin/<branch> -- src` must be empty);
   - the read order of authorities (project directives, live gate, protocol docs, status docs,
     the PR comment channel);
   - every HELD item with its exact external unblock (who, the one verbatim command);
   - an ORDERED resume procedure with exact commands and exact conditions ("steps > 0", "must end
     red", SHA equalities);
   - the hard rules still in force; the lessons this session recorded.
6. **Memory.** Update persistent memory with a pointer to the handover and one line of state per
   lane; correct anything now stale.
7. **Commit and push** the handover, the moved artifacts and any generator scripts on the lane's
   branch — docs/scripts only; never smuggle a source change into a handover commit. Re-verify the
   equalities from step 4 (the API can lag a push by a few seconds; read again).
8. **Final message:** the HEADs, the one external step a human owns (verbatim), the resume command.

## `resume` — first thing in the next session

1. **Rehydrate from git, never from chat.** `git fetch`; read the newest `docs/handovers/*.md`, then
   the authorities it names.
2. **Verify the state table.** Every SHA equality must hold now. If something moved (a reviewer's
   commit, a verdict), read that first — a governance head may have advanced.
3. **Check the durable channels** for events during the pause: PR comments (verdict / directive /
   human signals), CI and runner state, whatever the handover said to watch. Act in the order the
   handover's resume procedure gives.
4. **Re-arm the watches** the handover lists — poll loops that parse JSON and validate it (a
   transient API error must never read as state), long intervals, one notification per event.
5. **Continue from the handover's next step.** Do not re-run a completed gate because local state
   was lost; do not re-litigate decisions the record shows as made.

## Checklist (paste into the pause turn)

- [ ] in-flight workers finished/cancelled; task ids noted
- [ ] scratch artifacts moved into the repo, or replaced by a generator script
- [ ] status/evidence docs carry exact SHAs and next-action owners
- [ ] all worktrees clean; local = remote = PR head, each
- [ ] handover written: state table, read order, held items + unblocks, ordered resume steps, placeholders named
- [ ] memory updated with the handover pointer
- [ ] committed + pushed; equalities re-verified
- [ ] final message: HEADs, the human's verbatim step, resume command
