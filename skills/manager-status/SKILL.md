---
name: manager-status
description: Build a management status update from repo/tracker truth and format it chat-ready for Teams/Slack (emoji section headers, outcome-first bullets, work-item IDs inline). Use whenever the user asks for a status, status update, summary of what was done/shipped recently, something to share with their manager/management/leadership, or a chat-ready recap — even without the word "status" (e.g. "what did we get done the past two weeks?", "recap for my 1:1").
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Evidence-based management status update in a chat-paste emoji-bullet format — gathered from git/PRs/tracker, never from chat memory
tags: [skill, status-report, reporting, teams, ado, management]
---

# Manager Status Update (chat-ready)

Produce a copy-paste status block for a chat message to the user's manager. Window default: **the last 2 weeks** (or what the user names). Everything reported must come from durable evidence gathered this session — never from stale chat memory alone.

**Workspace instance config:** the consuming workspace supplies the specifics — tracker org/project URLs, the canonical work-item ID map, active repo list, manager name(s), and org objectives to frame against. Look for them in the workspace `CLAUDE.md`, memory, or a local workspace copy of this skill that carries a "Live instance" section. A local copy at `.claude/skills/manager-status/` overrides this one — leave it in place.

## 1. Gather facts (evidence over assertion)

Pull from these sources, newest first, scoped to the window:

1. **Project control-plane docs** — the repo's own status dashboard / worklogs where they exist (e.g. `STATUS.md`, `specs/*-worklog.md` top entries). Team truth beats reconstruction.
2. **Git, per active repo** — `git fetch origin --quiet` then `git log origin/<default-branch> --since=<window-start> --oneline`. Merge commits name the PRs that landed.
3. **Open PRs** — e.g. `az repos pr list --status active` (Azure DevOps) or `gh pr list` (GitHub). Built-but-in-review items go in their own section, never presented as shipped.
4. **Work tracker, items changed in window** — e.g. ADO: `az boards query --wiql "SELECT [System.Id],[System.Title],[System.State] FROM WorkItems WHERE [System.ChangedDate] >= '<window-start>' AND [System.AssignedTo] = @Me"`.
5. Session memory fills narrative gaps (the *why* of decisions) — but every delivery claim needs a source from 1–4.

Verify any work-item ID not in the workspace's canonical map before citing it (`az boards work-item show` / `gh issue view`).

## 2. Format

Output ONE fenced ```text block (survives chat paste cleanly). Structure — include only sections that have content, in this certainty order:

```text
🏭 <Initiative/area name> (<feature/epic id>) — <window, e.g. Sep 22–Oct 5>

✅ Shipped — merged to main / in production
• <Outcome first> (<tracker id>) — <one line: what + why it matters; date or count where it adds punch>

✅ Built — PR in review
• ...

🔄 In progress — delegated
• <item> (<tracker id>, <owner>) — <state + next milestone>

🧹 Hygiene / process (board cleanup, docs, iterations)
• ...

📋 Next / needs
• <ask> (<tracker id>) — <who acts + why it matters now>
```

Other recurring section flavors when applicable: `🎫 <ops area> (prod)` for ticket/ops throughput (counts + ticket IDs), `🔄 In final validation` for validated-but-not-merged.

## 3. Writing rules

- **Outcome first, mechanism second.** "Closed requests no longer accrue time forever (ID 27245454); 89 records corrected" — not "fixed a bug in the SLA timer logic".
- **One line per bullet — roughly 25 words after the ID.** Two facts max (outcome + one proof point); a third clause means it's two items or detail the manager doesn't need. Test-run counts ("15/15 fixtures green") are usually that third clause — cut them.
- **Numbers and dates are the punch**: PR counts, records fixed, run dates, "zero manual steps".
- **Tracker IDs inline** on every work item so the manager can click through; **never commit SHAs, branch names, or internal shorthand** (spell the deliverable out, not the story codename).
- **In-review ≠ shipped.** Keep the certainty ladder honest — it's what makes the format trustworthy.
- **Asks name the actor** and what unblocks ("doc ready, <name> fronts it to governance").
- Blocked items: state the single blocking dependency plainly, no hedging.

## 4. Audience calibration

- **Direct manager (default):** full sections, named asks, delegation visibility.
- **Skip-level / leadership:** trim to headline deliveries + ONE ask; drop hygiene and per-person detail; frame against the org's stated objectives where the workspace records them.
- Asked for a shareable document instead of chat text: build the same content as a document (sections ≈ the emoji categories), then also offer the chat block.

After the block, add at most one short line of caveats (e.g. an ID that needs a spot-check) — nothing else.
