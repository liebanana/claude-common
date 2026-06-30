---
description: Analyze new GitHub agent/plugin candidates and file them into the catalog + research notes
kind: command
status: ready
group: Discover & adopt external agent tooling
intent: Analyze new GitHub candidates into research notes + the research ledger
tags: [discovery, triage]
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
they are not lost — they only enter `research/ledger.jsonl` once triaged). Prefer higher-star,
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
3. Write `research/<owner>__<repo>.md` using the template below (prose detail for humans).
4. Append **one JSON line** to `research/ledger.jsonl` (the structured source of truth —
   this is what dedupes future runs and feeds the index; see format below).
5. If a genuinely portable asset exists, you may also stub it into `.claude/commands/`,
   `hooks/`, `scripts/`, or `mcp/` **with proper metadata** (see `scripts/build-index.py`
   header) — but keep stubs honest (note "imported from <url>, untested").

After the loop:
- Delete `research/_candidates.tsv` (consumed).
- Run `python3 scripts/build-index.py` — this regenerates `index.json`, `CATALOG.md`,
  and `research/INDEX.md` from the ledger + asset metadata. **Never hand-edit those
  three; they are generated.**
- Print a 3-5 line summary (counts by verdict, notable finds).

## research/<owner>__<repo>.md template (prose note)
```
# <full_name>  ·  ⭐<stars>  ·  <verdict>
<url> · pushed <pushed_at> · triaged <today>

**What it is:** <1-2 sentences>
**Reusable for us:** <the specific transferable asset/technique, or "none">
**Token / effectiveness angle:** <how it helps do more with fewer tokens, or n/a>
**How to adopt:** <concrete next step, or "watch" / "skip">
```

## research/ledger.jsonl line (structured; append one per repo)
```json
{"repo":"<owner>/<name>","verdict":"adopt|watch|skip","stars":<int>,"url":"<html_url>","pushed":"<YYYY-MM-DD>","triaged":"<today>","intent":"<one-line what-it-is/why>","tags":["..."]}
```

Keep every note short. The value is the distilled verdict, not a copy of their README.
