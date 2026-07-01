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
- `research/_candidates.jsonl` — produced by `scripts/discover.sh` (multi-source). One
  JSON object per line: `{source, sources:[...], key:"owner/repo", repo, title, url,
  signals:{stars?, points?, score?, comments?, repo_age_days?, seen_age_days?,
  stars_period?}}`. If missing/empty, run `bash scripts/discover.sh` first; if still
  empty, report "nothing new" and stop.
- `sources` tells you where it was seen (github/github-trending/hackernews/lobsters/
  reddit). Multi-source = corroborated. Note the two ages: `repo_age_days` = how old the
  repo is; `seen_age_days` = how old the forum post is (an old repo can be buzzing today).

## Procedure
The file is **already ranked best-first** (corroboration > trending > buzz > stars).
Work from the top; process **at most 15 candidates** this run (the rest resurface next
run — they only enter `research/ledger.jsonl` once triaged). You may still skip past a
top item that is plainly off-mission, but don't cherry-pick deep into the tail.

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

   A verdict from README-reading is a *recommendation*, never a certification: always
   set `"status":"recommended"` in the ledger line. The status only advances
   (`trialed` → `in-use`, or `rejected`) when someone actually installs/exercises the
   tool and records **Field notes** in the prose note — do NOT do that here.
3. Write `research/<owner>__<repo>.md` using the template below (prose detail for humans).
4. Append **one JSON line** to `research/ledger.jsonl` (the structured source of truth —
   this is what dedupes future runs and feeds the index; see format below).
5. If a genuinely portable asset exists, you may also stub it into `.claude/commands/`,
   `hooks/`, `scripts/`, or `mcp/` **with proper metadata** (see `scripts/build-index.py`
   header) — but keep stubs honest (note "imported from <url>, untested").

After the loop:
- Delete `research/_candidates.jsonl` (consumed).
- Run `python3 scripts/build-index.py` — this regenerates `index.json`, `CATALOG.md`,
  and `research/INDEX.md` from the ledger + asset metadata. **Never hand-edit those
  three; they are generated.**
- Print a 3-5 line summary (counts by verdict, notable finds, anything multi-source).

## research/<owner>__<repo>.md template (prose note)
```
# <full_name>  ·  ⭐<stars>  ·  <verdict>  ·  <maturity>
<url> · pushed <pushed_at> · triaged <today> · seen on <sources>

**What it is:** <1-2 sentences>
**Reusable for us:** <the specific transferable asset/technique, or "none">
**Token / effectiveness angle:** <how it helps do more with fewer tokens, or n/a>
**How to adopt:** <concrete next step, or "watch" / "skip">
```
(When a tool later gets actually used, whoever used it appends a `**Field notes
(YYYY-MM-DD):**` section — install gotchas, real behavior vs README claims — and flips
the ledger `status`. Triage itself never writes field notes.)

## research/ledger.jsonl line (structured; append one per repo)
```json
{"repo":"<owner>/<name>","verdict":"adopt|watch|skip","status":"recommended","stars":<int>,"url":"<html_url>","pushed":"<YYYY-MM-DD>","triaged":"<today>","intent":"<one-line>","tags":["..."],"source":"<first source>","sources":["..."],"signals":{"stars":<int>,"points":<int?>,"score":<int?>,"comments":<int?>,"repo_age_days":<int?>,"seen_age_days":<int?>},"maturity":"stable|trending|emerging|experimental"}
```
Carry `source`/`sources`/`signals` straight from the candidate. Set **maturity** from the
evidence so we can later separate the stable from the new/hyped:
- **stable** — established & widely used: high stars, older, actively maintained.
- **trending** — surging now: young or recently spiking, strong forum score, multi-source.
- **emerging** — new/small but credible; worth watching.
- **experimental** — very new/unproven, thin signal.

Keep every note short. The value is the distilled verdict, not a copy of their README.
