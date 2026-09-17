---
description: Emit this repo's machine-readable status for the oracle board (.oracle/status.json) — goal, next step, owner, blocked-on-human
argument-hint: "[--blocked \"reason\" | --unblocked]"
kind: command
status: ready
group: Reusable Claude Code assets
intent: Structured, agent-emitted project status that a cross-project board can trust — never inferred from prose
tags: [status, handover, oracle, coordination]
---

# /oracle-status

Write `<repo root>/.oracle/status.json` (create the dir) with exactly these keys, then commit it
(`chore(oracle): status YYYY-MM-DD`). Run it at session end, inside `/session-handover pause`, and
whenever a blocker appears or clears.

```json
{
  "schema": 1,
  "goal": "one line: purpose + current milestone",
  "next_step": "the single next concrete action",
  "owner": "agent | luis",
  "blocked_on_luis": {"flag": false, "reason": null, "since": null},
  "as_of": "<date -u +%Y-%m-%dT%H:%M:%SZ>",
  "session_id": "<your session id if known, else null>",
  "by": "claude-interactive | claude-headless | codex | luis"
}
```

Rules: `blocked_on_luis.flag` is true ONLY for a true human-only blocker (auth/2FA, physical action,
irreversible submission, a decision only he can make) — give the reason and the date it started;
set it false the moment it clears. Keep it to one line per field; no secrets, no prose. If `$ARGUMENTS`
contains `--blocked "reason"` set the flag with that reason and today's date; `--unblocked` clears it.
