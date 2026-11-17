---
name: backlog-by-impact
description: Use when the user asks what is pending, for a backlog recap, "what's next", or to "work the backlog by priority". Review mode (default, read-only) scores every open item by impact — not ease — and prints a one-screen, decision-ready recap; execute mode runs only the items the user picked, each through the full workflow in its own worktree. Never starts work from the review.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Look before you leap on a backlog — a read-only, impact-scored recap the human picks from, then execution of only the picked items through the full workflow
tags: [skill, backlog, prioritization, planning, orchestration]
---

# Backlog by impact: review first, then execute what was picked

Executing "the next thing" straight from a backlog picks whatever is easiest or most recent, and the
human loses the chance to redirect before work starts. This skill splits it: a **read-only review**
that the human chooses from, then **execution** of exactly those items.

## Scoring (record it on each picked item: `score: "<n> = <breakdown>"`)
- **A direct user/stakeholder ask that isn't done outranks everything else.**
- **Impact = audience weight × severity.** Define audience weights once per project (e.g. paying
  customers 3, end users 2, internal 1). Severity: blocks the core job / wrong output 4 · misleads or
  delivers nothing 3 · friction (slow, confusing) 2 · polish 1.
- **Reach:** +1 per extra surface or data set one fix covers (one root cause → many surfaces wins).
- **Priority field:** P1 +3, P2 +1.
- **Cost (S/M/L) is a tie-break only.** Ease is never the reason to pick something.
- Blocked items (open dependency, waiting on a human, migration not applied) are listed as blocked with
  the reason — never scored into the top.

## Review mode (default) — read-only
1. Read the tracker and live state **now** (tracker file/issues, in-flight work, last deploy, served
   build id). Never restate status from conversation memory.
2. Bucket open items: **needs the human** · released but unverified · in progress (days since last
   movement; > 14 days = stale) · ready (scored) · blocked (with what it waits on).
3. Reply in one phone screen: how many need the human (and the first step), how many await a
   verification, the top items by score with one-line reasons, stale and blocked counts. A dashboard
   page is fine; regenerate its data from a script, don't hand-build it.
4. Offer the next step as clickable options, recommendation first: execute the top N (default 2),
   pick specific items, clear the human's items first, or stop. **Do nothing until they answer.**
   No edits, branches, writes or deploys in this mode.

## Execute mode — only on an explicit pick
1. At most **2 independent items** at a time, each in its own `git worktree` (never two writers in one
   checkout; never branch in a checkout that is deploying).
2. Each item runs the full workflow visibly: ANALYZE → BRAINSTORM → SPEC → PLAN → IMPLEMENT (explicit
   model tier per role) → deterministic QA with a deliberate RED → UX/interaction gate for user-facing
   UI → release with the regression step actually run → serving check from the entry point.
3. Before a user-reported item leaves IMPLEMENT, run the **applicability sweep**: name the concept,
   list every surface that shares it (by query, not memory), fix or file each, and gate the class over
   the whole domain. Record it on the item (`sweep: "<concept>: <surfaces> -> <ids>; gate <name>"`).
4. Checkpoint each item (status, SHAs, next action) in the tracker and push.
5. Report briefly: what shipped, what waits on the human (as one runnable line each), what is next by
   score.

Ask the human only for decisions that are truly theirs, as clickable options with a recommendation.
