---
name: solution-audit
description: Use when asked to audit "solutions" (the project's canonical ways of doing things) across the codebase — what is done well, what is duplicated, what exists in one place and should be replicated — when a scheduled audit step comes up, or after a new standard, guardrail or bug class lands. FINDINGS ONLY - refreshes the project's solutions index against the real code and files one backlog row per actionable finding. It never edits product code, never merges, never closes rows; each row then goes through the normal workflow (implementation is the backlog-execute skill's job).
kind: skill
status: experimental
group: Reusable Claude Code assets
intent: Findings-only audit of canonical solutions vs real code - verified, evidence-backed, deterministic-id backlog rows, no product edits
tags: [skill, audit, backlog, duplication, consistency, workflow]
---

# Solution audit (findings only)

A **solution** is a project's canonical answer to a recurring problem (a shared component, a validation helper, a
guardrail, a UX/security standard). Over time a solution gets applied in one place, forgotten in another, or
re-implemented in parallel. This skill compares the *solutions index* with the *real code* and turns every gap into a
backlog row. It does not fix anything.

## Adapting to your project

The project must supply (declare them in its CLAUDE.md or a docs page; if one is missing, ask once and record the answer):

- **Solutions index**: a file listing each solution with an id, the canonical primitive (file/symbol), the surfaces it
  applies to, and a per-surface status (`applied` / `partial` / `missing` / `n/a` / `unknown`) with evidence paths.
  If none exists, creating a first version is the first run's output (as a PR), not a prerequisite.
- **Index validation command** (schema/consistency check), run after any index edit. Optional but recommended.
- **Backlog file and row schema** (see `backlog-review`): at minimum id, title, severity, priority, status, evidence,
  audience, class, governing/source.
- **Surface inventory** (routes, screens, endpoints, jobs...) to enumerate "where could this apply".
- **Severity rubric** and **audience weights** (who is hurt: end users, admins, internal). Defaults below; override freely.
- **Duplicate register** if the project keeps one (a stable id per duplicate pair, so findings reference instead of re-describe).
- **Probes** per solution kind: how to exercise the behaviour at runtime (browser script, test harness, read-only query).
- Optional **read-only mapping/audit agents** the project already has; otherwise do the mapping inline.

## Hard rules

- **Findings only.** Allowed writes: refreshes to the solutions index (in a worktree on a branch, merged through the
  project's normal review/CI like any change) and backlog rows. Never edit product code, never merge a fix, never close or
  downgrade a row someone else owns.
- **Deterministic ids:** one row per finding, id `SOLN-<solution-id>-<surface-id>` (uppercase, separators normalized to `-`).
  A re-run updates the row's `evidence` / `checked` fields; it never files a duplicate. A finding that is now fixed is noted
  (`resolved_seen: <date, SHA>`), not deleted - the row owner closes it.
- **Evidence, not opinion.** Every finding names the files/lines (or the missing ones) and the check or gate run that shows it.
- **One control plane.** Run on request or as a step of the project's existing recurring loop; never create a second
  recurring task for it.
- **Bounded everything.** Every wait/poll loop has a hard deadline, e.g. `timeout 600 bash -c 'until <cond>; do sleep 10; done' || echo FAIL`;
  never `pgrep -f` a pattern contained in the loop's own command. Read-only toward production.
- Never put secrets, tokens or personal data in index entries, rows, or evidence.

## Steps

1. **Refresh the map (diff-driven).** In a git worktree off the default branch: take the commit SHAs recorded in the index
   (`source_shas` or equivalent) -> current HEAD; re-examine every cell whose evidence files changed, every `unknown` cell,
   every new surface, and every solution added since. Each re-examined cell gets fresh evidence (grep the canonical
   primitive; run the solution's own check where one exists). Run the index validation command - it must pass. Push the
   branch; it merges like any change.
2. **Classify every solution x surface cell:**
   - `CANONICAL` - applied through the canonical primitive (no finding).
   - `SINGLE-SITE-SHOULD-REPLICATE` - status `missing`/`partial` where it applies (finding).
   - `DUPLICATE` - a parallel implementation of the same rule (finding; reference the duplicate register id, never re-describe).
   - `DRIFT` - applied but diverged from the canonical (finding).
   - `UNKNOWN` left after the refresh (finding of kind `unexamined`, low priority).
3. **Verify every finding before filing it.** A static read is a hypothesis, not a finding. For each candidate finding
   (every top-priority one, and every SINGLE-SITE / DUPLICATE / DRIFT), have one reviewer per root-cause group try to
   **refute** it with runtime evidence (a separate read-only agent, lowest capable model; at most 2 at a time; never during
   a deploy or CI run on shared hosts). Use the project's probes; generic ones:
   - *latency / feedback*: measure ms from action to first visible change against a stated budget;
   - *validation / input handling*: submit the bad input and record what the system does;
   - *coverage* (e.g. "tested only what was taught"): count items in the tested set missing from the taught set via a read-only query/script;
   - *DUPLICATE*: diff the copies - the finding stands only if they are the same responsibility.

   Verdict per cell: `CONFIRMED` (runtime evidence attached), `REFUTED` (update the index cell to applied/n-a with the
   evidence), or `UNVERIFIABLE` (say exactly why: needs a device, a login, production data, a decision). File only
   CONFIRMED and UNVERIFIABLE; the row `class` gets `-verified` or `-unverified`. Report REFUTED as a count only.
4. **Severity rubric (apply literally, no gut feel; the project may replace it):**
   - **blocks (4):** the user is wrong-data-served, loses work, is blocked, or hits a security/correctness failure.
   - **misleads (3):** the interface suggests something untrue or gives no way to know what to do.
   - **friction (2):** works but slow or clumsy.
   - **polish (1):** cosmetic.

   If the project marks a surface or audience as high-bar, add a floor (e.g. "admin-facing friction is at least misleads").
5. **Index gaps:** list every recent (e.g. last 30 days) bug class or standard the project recorded that has no entry in the
   solutions index. File ONE row `SOLN-INDEX-GAPS-<date>` naming them, to be indexed on the next run.
6. **File / update backlog rows** (one per finding, in the project's row format; validate the file parses afterwards).
   Fields: `id`, `title` ("<solution> missing on <surface>: <what is absent>"), `severity`, `verified`
   (`CONFIRMED|UNVERIFIABLE` + evidence path), `priority` (high if it blocks/misleads or hits the high-bar audience, mid
   friction, low polish), `status` = the workflow's first phase (ANALYZE), `depends_on: []`, `governing`
   ("SOLUTION-AUDIT <date>: <class>"), `audience`, `evidence`, `class`. One root cause covering several surfaces (a shared
   component) = ONE row listing all surfaces.
7. **Commit + push** the backlog/index changes through the project's normal flow (run its pre-push hooks; never skip them).
8. **Report in chat (short):** counts per class, the top 5 by impact (audience x severity), and the ids filed/updated.
   Full detail lives in the rows. Do not start implementing - say that `backlog-execute` picks these up.
