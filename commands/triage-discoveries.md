---
description: Analyze new GitHub agent/plugin candidates and file them into the catalog + research notes
---

# /triage-discoveries

Turn raw discovery candidates into durable, reusable knowledge. Agent-first output:
terse, scannable, but a human must be able to follow it.

## Inputs
- `research/_candidates.tsv` — produced by `scripts/discover.sh`. Columns:
  `full_name \t stars \t pushed_at \t url \t description`. If missing or empty, run
  `bash scripts/discover.sh` first; if still empty, report "nothing new" and stop.

## Procedure
Process **at most 8 candidates** this run (token budget; the rest resurface next run,
they are not lost — they only enter `seen.tsv` once triaged). Prefer higher-star,
recently-pushed ones.

For each candidate:
1. Fetch its README (raw): try
   `curl -fsSL https://raw.githubusercontent.com/<full_name>/HEAD/README.md`
   (fall back to the repo's GitHub API contents if HEAD/README.md 404s). Don't clone.
2. Judge it against **our** purpose — making Claude Code / agents more effective and
   token-cheap. Decide a verdict:
   - **adopt** — concrete reusable asset (a command, hook, subagent, script, MCP, or
     a technique we can encode). Extract the reusable bit.
   - **watch** — promising but not yet actionable; worth re-checking.
   - **skip** — off-topic, abandoned, or no transferable value.
3. Write `research/<owner>__<repo>.md` using the template below.
4. If verdict is **adopt**, add/refresh a one-line entry in `CATALOG.md` under the
   matching intent (mark it 🔬). If a genuinely portable asset exists, you may also
   stub it into `commands/`, `hooks/`, `scripts/`, or `mcp/` — but keep stubs honest
   (note "imported from <url>, untested" rather than pretending it's verified).
5. Append the repo to `research/seen.tsv` (so it's never re-triaged) and add one line
   to `research/INDEX.md`.

After the loop: delete `research/_candidates.tsv` (consumed), and print a 3-5 line
summary (counts by verdict, notable finds).

## research/<owner>__<repo>.md template
```
# <full_name>  ·  ⭐<stars>  ·  <verdict>
<url> · pushed <pushed_at> · triaged <today>

**What it is:** <1-2 sentences>
**Reusable for us:** <the specific transferable asset/technique, or "none">
**Token / effectiveness angle:** <how it helps do more with fewer tokens, or n/a>
**How to adopt:** <concrete next step, or "watch" / "skip">
```

## seen.tsv / INDEX.md formats
- `research/seen.tsv` row: `full_name \t verdict \t YYYY-MM-DD`
- `research/INDEX.md` row: `- [<full_name>](research/<owner>__<repo>.md) — <verdict> — <one-line>`

Keep every note short. The value is the distilled verdict, not a copy of their README.
