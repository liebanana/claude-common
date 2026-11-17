---
name: defect-class-loop
description: Use whenever the user reports a bug, an inconsistency, or something you missed ("this is broken", "you forgot X", "you took my prompt too literally", a screenshot of something wrong), and at the end of a long session or release train as a retro. Turns each report or lesson into a same-day fix PLUS a named defect class, a guardrail where it was missed, and an automated gate, enforced by a registry checker. Not a status report.
kind: skill
status: ready
group: Verification & quality gates
intent: Turn every user-reported bug or correction into a same-day fix plus a named defect class, a guardrail where it was missed, and an automated gate — with a registry checker that fails any class lacking a gate
tags: [skill, qa, regression, bug-class, gates, retro, process]
---

# Defect-class loop: a correction is a process miss, not just a content fix

A bug that reached the user means a gate was missing or measured a proxy. Patching the instance
guarantees the class comes back — and a fixed bug that returns costs more trust than a new one. So
every report, and every lesson from a retro, ends in something a cold agent will **run**, not just read.

## Intake: one report → five things, the same day

1. **Locate it live.** Treat the report as a fact. Reproduce from the real build or real data before
   answering; root cause with `file:line` and the evidence. Never answer from a status view.
2. **Scope it as a seed, not the boundary.** Name the *concept* the complaint is about (not the screen it
   was seen on), then list every surface that shares it — by grep/query, never memory: sibling screens,
   other locales/variants, every consumer of the same value, data rows of the same shape. The fix covers
   all of them. When the user gave examples, they are seeds: produce a researched scope map (common →
   rare, cited) plus a gap list, never a restatement of their list.
3. **Fix it** through the normal workflow (worktree, ANALYZE → … → IMPLEMENT, test-first with a
   deliberate RED run). Track it in the backlog the moment it arrives — an un-admitted ask is invisible
   to the next session.
4. **Gate the class.** Add a deterministic test that fails on the *class* across the whole domain, wired
   where it runs on every change (CI, pre-push, release verify). It must exercise the real artifact,
   never a proxy (a route → load it; generated media → transcribe/inspect it; "a URL exists" proves
   nothing). Prove it: run it against the old case and see RED. Human review is never the gate.
5. **Record it.** A registry entry (format below) with a `- **Gate:**` line; one guardrail line in the
   agent/skill definition that missed it; a memory/notes entry linked to the class name. Then deploy and
   verify starting from the user's entry point, and report briefly.

A fix that lacks any of these is **FIXED — UNGATED**: an explicit, open state. Say so in the handback.
Full closure = reproduced · root-caused · domain swept · siblings fixed · gate added · gate shown RED ·
guardrail updated · before/after counts recorded · serving surface verified · reviewed at a stable SHA.

## Registry format

One file per project (e.g. `.claude/agents/BUG-CLASS-REGISTRY.md`), read by every code-touching agent
before it changes the area:

```markdown
## CLASS-NAME — one-line description of what the user saw (YYYY-MM-DD)
- **What happened:** the user's words, the root cause with file:line.
- **Why the gates missed it:** which check existed and what it actually measured.
- **Guardrail:** the rule, stated so it applies to the whole class.
- **Gate:** self:tests/class-name.test.ts (RED proof: the pre-fix fixture fails)
```

`- **Gate:**` names `<repo>:<path>` test(s) that exist, or `PENDING <ID>` — an **open** tracked item that
builds the gate. Prose is not a gate.

## Enforce it: `gate-check.py` (stdlib Python, self-tested)

```bash
G=.claude/skills/defect-class-loop/gate-check.py
python3 $G --selftest                                   # proves the 7 RED cases
python3 $G --registry .claude/agents/BUG-CLASS-REGISTRY.md \
  --repo app=../my-app --baseline scripts/gate-baseline.txt --open-ids <(my-tool list-open-ids)
```

Wire it into pre-push or CI so a new class without a gate cannot land. Adopting it on an existing
registry: list today's ungated classes in the baseline file — they are reported as debt, and the
baseline only shrinks (a listed class that gains a gate must be removed, or the check goes RED). Zero
classes found is RED: a check that examined nothing is not a pass.

## Retro mode: harvest a session into better defaults

At the end of a long session, a release train, or after a complaint, read `git log` for every repo
touched, today's registry entries, the handover, and the user's messages. List corrections (quoted),
your mistakes (wrong claims, broken loops, lost work), friction (denials, waits, round-trips), and wins.
Put each lesson where it will actually fire, choosing the cheapest guardrail that does:

| Lesson | Where it goes |
|---|---|
| Recurring defect in code/content | registry entry + deterministic gate with a RED fixture |
| A procedure done twice | a script or skill (generic → contribute it to claude-common) |
| A rule one agent keeps breaking | one line in that agent's definition |
| Process or tracking drift | a backlog item, or a fix to the generator/check that missed it |
| A tool/host fact or a user preference | a memory entry with the date and the reason |

Prefer gates over prose: "remember to X" is weaker than a check that fails without X. Verify each
guardrail landed (file present, gate RED on the old case, memory indexed), update instead of
duplicating, delete lessons that proved wrong, commit, and report: learned → where it lives → what
agents now do differently → what needs the user's decision.
