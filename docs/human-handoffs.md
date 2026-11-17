---
kind: doc
status: ready
group: Working with humans
intent: Communicating with a busy, often-remote human — short visual status replies, full documents printed in chat, decisions as clickable options with the recommendation first, human-only steps packaged as one paste-safe script, every ask admitted to the backlog the same day, and examples treated as seeds
tags: [practices, communication, handover, decisions, human-in-the-loop]
---

# Working with a busy, remote human

The human reviews from a phone or a remote-control client more often than from a desk. Long replies
scroll away, committed files can't be opened, and pasted commands get mangled. Every rule here removes
a round-trip.

## Replies
- **Short and outcome-first, with a visual status header**: one line per item with a state marker
  (🟢 done · 🟡 in progress · 🔴 broken · 🟣 needs you) and text progress bars (`▓▓▓▓░░ 4/6`). Details
  only on request.
- **Print deliverables in full in the chat** — specs, plans, reports, checklists — in addition to
  committing them. A pushed file a remote reader can't open has not been delivered.
- Images and references go **on the review page** next to the step that uses them, not only as a
  separate file send.

## Decisions
- **Ask with clickable options, your recommendation first** (marked as recommended) plus 1–3
  alternatives; one decision per question. The human clicks or adds a note instead of composing an
  answer from scratch.
- **Option labels name the concrete thing in plain words**, and the description states the scope the
  choice implies (how many, which). An ambiguous label hides a plan the human never saw.
- Batch true human-only decisions into one list; never drip them one per message.

## Steps only the human can do
- **Run it yourself first.** Read-only checks and already-authorized scripts are never the human's.
  Hand a step over only after a real denial in this session (quote it) or when it needs their secret,
  login, device, physical action or decision.
- **Package each human step as a script file** (`set -euo pipefail`, pinned SHAs, a dry-run mode, a
  final VERIFY line) and give **one** short `! <path>` line to run. Remote clients can duplicate a paste
  or append characters; a multi-line paste is fragile, a one-line path is not.
- State exactly what to paste back ("the VERIFY line", "pass/fail").
- **Don't litter the home directory.** Scratch goes to the session scratchpad; human scripts and their
  logs go in one per-project folder; delete a script after its verified run.
- Gather the open human-only items from durable state (tracker, comments, denials), verify each is
  still needed, and print one complete step-by-step checklist — never a one-line mention buried in a
  status report.

## Manual tests
- Never ask a human to verify what automation can.
- A test page gives **every step its own verdict** (works / doesn't / works-but-not-as-expected) and a
  note, stored where the agent can read it back; references embedded; exact taps and expected result.
  Gate: `skills/artifact-smoke` (`test-page-check.py` + the publish hook).

## Requests
- **Admit every ask to the tracker the moment it arrives**, even mid-task, and say so in the reply.
  Cold sessions pick work from the tracker, not from specs or chat — an un-admitted ask is never built.
- **The human's examples are seeds, not the scope.** They can't enumerate everything; the value is
  finding what they would miss. Brief agents for a researched, cited scope map (common → rare,
  including cross-cutting layers that run through every case) plus a gap list — never a restatement of
  the examples. "You took it too literally" is a defect class (see `skills/defect-class-loop`).
- When a direction is clearly meant to apply everywhere (every language, level, screen, data row),
  apply it everywhere by default; don't hand back a per-item menu.

## When the human is away: a stakeholder proxy
For non-trivial calls that would normally wait on the human, a read-only reviewer agent primed with
their documented standards and past decisions can return **GREENLIGHT / REDIRECT / BLOCK** with
concrete reasons. Bias it toward keeping work moving; reserve BLOCK for genuinely human-only calls
(irreversible legal, financial, brand or strategy moves). It never replaces a mandated sign-off.
