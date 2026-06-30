---
description: From any repo/session, package a reusable, general learning and open a PR to claude-common
argument-hint: "[optional: what to contribute, e.g. 'the retry script' or 'the token-saving trick we found']"
kind: command
status: ready
group: Contribute back
intent: Scan the current session for a reusable, general learning and open a PR to claude-common
tags: [contribution, pr, session]
---

# /contribute-to-common

You are (probably) running inside **some other project**, not claude-common. Your job:
spot something from *this session* that would help agents on *any* project, and open a
**pull request** to the shared `claude-common` repo. This is repo-agnostic — only
contribute things that generalize. Never push to other people's `main`; always PR.

## 1. Decide what's worth contributing
Look back over this session for a **general, reusable** artifact or lesson:
- a script that replaced a repeated agent command sequence (deterministic, parametrized);
- a slash command / subagent / hook worth sharing;
- a token-saving or workflow technique, or a recurring-mistake correction (→ a `docs/`
  entry or an addition to `docs/token-thrift.md`);
- a genuinely useful external tool/repo you found (→ a `research/ledger.jsonl` line + note).

**Hard filters — skip if any apply:**
- It's specific to this repo (its paths, schema, business logic, deploy details).
- It contains secrets, tokens, internal URLs, customer/proprietary data, or anything the
  public repo shouldn't hold. **Sanitize to placeholders or don't contribute it.**
- It's already covered — check first: `jq -r '.assets[].intent, .research[].repo' <common>/index.json`.

If nothing clears the bar, say so plainly and stop. Quality over volume.
If `$ARGUMENTS` is set, focus on what the user named.

## 2. Locate claude-common
In order: `$CLAUDE_COMMON_DIR`, then `~/repos/claude-common`, else clone it:
`gh repo clone liebanana/claude-common /tmp/claude-common && cd /tmp/claude-common`.
Make sure it's clean and on the default branch, then `git pull`.

## 3. Make the change
- Put each asset in the right dir with **metadata** (frontmatter for `.md`, a `# meta:`
  line for scripts — see `scripts/build-index.py` header for the exact keys).
- For an external tool, append a line to `research/ledger.jsonl` and write the
  `research/<owner>__<repo>.md` note (same format as `/triage-discoveries`).
- Run `python3 scripts/build-index.py` so `index.json` / `CATALOG.md` / `research/INDEX.md`
  regenerate. **Don't hand-edit those.**
- `bash -n` any shell script; sanity-check JSON with `jq`.

## 4. Open the PR
```bash
git checkout -b contrib/<short-slug>
git add -A && git commit -m "<concise what+why>"
git push -u origin HEAD
gh pr create --fill --title "<title>" --body "<what, why it generalizes, provenance>"
```
In the PR body state: what it is, why it helps *any* project, and a sanitized note on
where it came from (e.g. "extracted while working on a data-pipeline repo"). Do **not**
name private repos or include their content.

## 5. Report
Print the PR URL and a one-line summary. Leave claude-common checked out on its default
branch (`git checkout main`) so the next run starts clean.
