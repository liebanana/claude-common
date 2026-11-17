---
kind: doc
status: ready
group: Verification & quality gates
intent: Claim levels, non-vacuous gates and the review packet — what evidence a "fixed / tested / released" claim needs, why a green check over a skipped step is not green, and what a handoff for review must contain
tags: [verification, qa, evidence, ci, review, handover]
---

# Evidence and claim levels: a claim is only as strong as what ran

The worst failures look like perfect health: a nightly check that died on `command not found` and,
because it only reported *new* findings, said nothing for weeks; a database-backed suite that skipped
every DB case on the deploy host and still exited 0; a CI run that was green because its regression
step only covered the diff since the previous push, and that diff was docs. Each was a claim stronger
than its evidence.

## 1. Name the level of every claim

| Claim | Minimum evidence |
|---|---|
| Code present | path/symbol at a named commit (the `verify-fix-claims` grep) |
| Test passed | an identifiable run: command, where, when, result, **case count** (0 cases ≠ pass) |
| Data verified | the query or snapshot, its time, and the access limits |
| Journey verified | a real sequence on the tested build with observable results |
| Released and verified | the served build identity equals the intended SHA, plus a smoke of the affected behavior |

A weaker kind of evidence never supports a stronger claim. When evidence is missing, write
**UNVERIFIED** or **SKIP** with the reason, or **AMBIGUOUS** with the last known verification date.
Record claims about live state as `verified: <command or method> @ <UTC date>` so anyone can re-run
them — a bare "applied ✅" is worth nothing to a reviewer who cannot see the system.

## 2. Non-vacuity: every "0 findings" proves it could have been non-zero

A zero is a result only when you can state: the exact command, where it ran (host/branch/SHA) and when;
**how many items it examined** (zero examined = a failed check reported as a pass); a deliberate
known-bad case that goes RED (or a cited earlier RED); and what it structurally cannot see (skips,
sampling, unavailable dependencies).

Rules that follow:
- **Gates exercise the real artifact, not a proxy.** Load the route; transcribe the generated audio;
  run the validator on the real data. "The URL exists", "it built", "it looks right" are not gates.
- **A check that cannot look fails closed.** Missing tool, missing DB, unreadable input → non-zero
  exit, never a quiet pass. Notify on staleness, not only on new findings.
- **Green with a skipped step is not green.** Before merging or deploying, read the run log for the
  step that matters (regression, e2e) and its counts. "NOT RUN" because of an incremental diff scope →
  force the full run first.
- **Prove a new gate RED** on the old defect before trusting its GREEN.
- **Status prose about git rots.** Text like "unmerged" or "not pushed yet" in a tracking file is
  never re-checked when the work lands another way. Derive status from git/CI, or gate the claim.
- **Run the existing script, not a fresh eyeballed variant.** Any check done twice becomes a script
  that prints a human summary and machine-readable output.

## 3. The review packet (anything handed to a human or reviewer)

Required for any user-visible change and any finding sent for review or a manual test:

1. **Observation vs facts** — what was reported (verbatim), the hypothesis, what was verified; separate.
2. **Where** — route/screen, account/role, initial state, locale, viewport, theme.
3. **Identity** — the SHA (and data refs). Evidence from another SHA does not count.
4. **Scope** — journeys, consumers, variants and states covered; exclusions with a reason.
5. **Expected behavior** and acceptance criteria.
6. **Reference** — the approved design and before/after, embedded in the packet itself.
7. **Tests run** — command, environment, date, case count, result, skips with reasons.
8. **Human steps** — exact taps, what should happen, what to do if it fails.
9. **Open items** — blockers, decisions needed, the limits of the evidence.

Not approvable when a field is missing, the reference is unreachable, the evidence is from another
SHA, a SKIP is shown as PASS, or the executed scope differs from the declared one.

## 4. Handbacks between agents

- **Implementer:** scope, consumers touched, tests run *with claim levels*, evidence paths, what remains.
- **Auditor/reviewer:** the commit received, cases examined and skipped (with reasons), negative cases;
  it **re-runs the critical gates itself** — an implementer's report or a lone screenshot is not
  evidence. Can't verify → **UNVERIFIABLE** + reason. Reports findings; fixes only with a mandate.
- A bug fixed without a regression gate shown RED is **FIXED — UNGATED** (see `skills/defect-class-loop`).
