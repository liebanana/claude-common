---
kind: doc
status: ready
group: Parallel agents & shared hosts
intent: Running several agents, builds, CI and deploys on one machine without them corrupting each other — one writer per checkout, frozen deploy checkouts, no deploy while self-hosted CI runs, a heavy-build cap against PSI/OOM session kills, delegates that commit per slice, and subagent permission limits
tags: [practices, git, worktrees, ci, deploy, subagents, reliability]
---

# Parallel writers and shared hosts

Every rule here came from an incident where two things that were each fine on their own broke each
other because they shared a checkout, a database, a cgroup, or a permission scope.

## Git: one writer per checkout
- **Subagents share the parent's working tree.** Two writers in one checkout sweep each other's
  uncommitted edits into the wrong commit, and one writer's `git checkout`/`reset` can destroy the
  other's work. Run at most one writer per checkout; give every parallel writer its own
  `git worktree add` directory and branch.
- **Stage your own files by name** (`git add path/a path/b`). Never `git add -A`/`.`, blanket
  `git stash`, `git reset --hard` or `git clean` to make a tree look clean.
- **`ln -s TARGET NAME` onto an existing directory (or a link to one) creates the link *inside* it** —
  e.g. a self-link in the main checkout's `node_modules`. Guard with `[ -e NAME ] || ln -s …` or use
  `ln -sfn`, and remove only what you created. Some bundlers reject a symlinked `node_modules`; use a
  hardlink copy (`cp -al`) for builds.

## Deploys
- **A deploying checkout is frozen.** No branch switch and no commit there while a deploy builds from
  it — the build can ship the new, ungated commit instead of the reviewed one. New work goes in a
  worktree.
- **After every deploy, compare the served build id with the intended SHA.** "Deploy succeeded" is
  not "the right code is serving".
- **No deploy or DB-heavy suite while a self-hosted CI run is in progress on the same host.** A
  self-hosted runner shares the host's local services; concurrent suites produce deadlocks and
  "concurrently updated" errors that read as real regressions. Check
  `gh run list --status in_progress` is empty first, and push the next branch only after the deploy
  finishes. A RED made only of concurrency errors gets one retry on a quiet host — never a waiver.
  Agents run targeted DB tests and leave the full suite to CI.

## Memory pressure: cap heavy work
- On systemd hosts, `systemd-oomd` kills the **whole cgroup** hosting an interactive session (the
  session, every subagent, every build) when memory *pressure* (PSI) stays over its limit (Ubuntu's user
  default is 50% for 20 s). Pressure spikes long before RAM is exhausted, e.g. while swapping. Several
  parallel framework builds, test servers and frontier-model subagents are enough to trigger it.
- Demand side: **at most 1–2 heavy jobs at a time** (production builds, full verify suites, speech-to-text
  or media sweeps), a small number of concurrent frontier subagents, `nice` for batch work, lighter
  checks (typecheck + unit) in place of full verifies while iterating, and prune stale worktrees.
- Supply side is the human's call (sudo): `ManagedOOMMemoryPressure=auto` or a higher
  `ManagedOOMMemoryPressureLimit` on `user@<uid>.service`. Check `journalctl -u systemd-oomd` first.
- Commit work in progress often, so a kill costs minutes, not hours.

## Delegation
- **Every delegation prompt says, in so many words: commit each finished slice on a clean tree before
  starting the next; an honest partial commit is a correct outcome.** An uncommitted delegate that
  dies costs a full re-verification from the files.
- **A delegate does not outlive the parent's pass.** In a headless or supervised pass, run delegates in
  the foreground (several independent ones as parallel calls in one message) so the turn cannot end
  with a live child. Don't exit a pass while a delegate you depend on is still running.
- **Subagents have a narrower permission scope than the parent.** Reads of production data and writes
  to shared resources that the parent may do can be denied inside a subagent. Do those steps in the
  parent before delegating, or queue them as human items. Never route a denied action through another
  agent or another tool — that launders the denial.
- Before standing down because "another holder is running", prove that process is alive (pid/etime).
- Every wait loop has a deadline (`timeout`/iteration cap) — in your prompts to delegates too.

## Recurring automation
- **One recurring control loop per project.** New monitoring or gatekeeping duties extend the existing
  loop in place. Two overlapping recurring tasks drift into parallel ownership and conflicting writes;
  when you find duplicates, keep the canonical one and disable the rest.
