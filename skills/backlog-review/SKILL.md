---
name: backlog-review
description: Use when asked what is pending - a backlog recap, summary, analysis, "what's next", "before we start" - and ALWAYS as the first step of backlog-execute. READ-ONLY - reads the project's backlog (and in-flight work / release log if it keeps them) and prints a short decision-ready recap - what waits on the owner, what is in flight, what is released but unchecked, the top items by impact score with reasons, what is blocked and why, and stale rows - then offers the next step as options. Never starts work, never edits rows.
kind: skill
status: experimental
group: Reusable Claude Code assets
intent: Read-only, scored, decision-ready backlog recap (impact x severity + reach, never ease) that waits for the owner's pick before anything runs
tags: [skill, backlog, prioritization, recap, read-only, workflow]
---

# Backlog review (read-only recap)

The look-before-you-leap step: the owner sees the whole picture and chooses; **nothing runs from here.**

## Adapting to your project

The project must supply (declare in its CLAUDE.md or a docs page):

- **Backlog file** and its **row schema**. Needed fields: `id`, `title`, `status`, `priority`, `severity`, `audience`,
  `depends_on`, `governing` (where the ask came from), last-touched date. Missing fields are treated as unknown, not guessed.
- **Status vocabulary** and which statuses mean open / in flight / released-unchecked / blocked / done.
- **Audience weights** (default: primary paying/decision audience 3, end users 2, internal 1) and **severity scale**
  (blocks / wrong data 4 · misleads 3 · friction 2 · polish 1; the `solution-audit` rubric).
- **Owner decision step**: who picks (a person, a review board, an automated reviewer) and how they are asked
  (an interactive multiple-choice prompt with the recommendation first, a PR comment, a ticket).
- Optional: in-flight work register, release/deploy log, list of pending owner-only commands, a live "what is deployed"
  check (version endpoint, tag), and a dashboard or page to refresh. Skip any the project lacks.
- **Staleness threshold** (default: untouched > 14 days) and **recap language/format** (default: plain words, one screen).

## Hard rules

- **Read-only.** No edits to the backlog or any state file, no branches, no writing agents, no deploys. A fix you notice goes
  in the recap as a suggestion.
- **Fresh facts only.** Read the files and the deployed-version check now; never restate status from conversation memory.
- **Short.** The recap fits one screen on a phone: plain words, no bare ids without a human title next to them.
- **Bounded.** Any wait/poll (e.g. fetching a version endpoint) has a timeout; on expiry print FAIL and say the fact is unknown.
- Never print secrets that appear in state files; redact.

## Scoring (the same rule `backlog-execute` uses)

Score each open, unblocked row; record `score: "<n> = <breakdown>"`:

- **Owner ask first:** a row whose `governing` quotes the owner directly and is not done outranks everything else.
- **Impact** = audience weight x severity.
- **Reach:** +1 per extra surface or dataset one fix covers (one root cause -> many surfaces wins).
- **Priority field:** high +3, medium +1.
- **Cost** (rough S/M/L): tie-break only. **Ease never counts as a reason to pick something.**
- Rows that are blocked (`depends_on` open, waiting on the owner, a prerequisite change not yet applied) are not scored;
  list them as blocked with the reason.

## Steps

1. **Regenerate the data (read-only):** if the project has a script for it, run it; otherwise read the backlog directly
   (a small throwaway script in the scratchpad is fine). Bucket every open row: waits-on-owner / released-unchecked /
   in-flight / ready / blocked. Mark rows untouched beyond the staleness threshold as stale.
2. **Optionally refresh the project's dashboard or page** if one is declared. Never create one unasked.
3. **Reply (short):** counts per bucket (and the first owner-only action to take), how many released items wait for a
   manual check, and the #1 scored item with its reason; then the top 5 with score breakdowns, blocked-with-reason, stale rows.
4. **Offer the next step as options** via the project's owner decision step, recommendation first: run `backlog-execute` on
   the top N (default 2), pick specific ids, clear the owner's own items first, or stop here. **Do nothing until the owner answers.**
