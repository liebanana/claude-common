---
name: artifact-smoke
description: Use before publishing any interactive HTML page for a human to look at or test (a claude.ai Artifact, a review page, a phone-test checklist). Loads the page headless at phone width and fails on script errors or an empty main control; checks that a test page gives every step its own verdict and note, stored where the agent can read them back. Ships a PreToolUse hook that blocks a broken publish.
kind: skill
status: ready
group: Verification & quality gates
intent: Headless-smoke every interactive HTML page before a human sees it, and require per-step verdict + note on test pages — with a PreToolUse hook that blocks broken Artifact publishes
tags: [skill, artifacts, playwright, smoke, hooks, human-testing]
---

# Smoke the page before a human opens it

A page that renders blank on the reviewer's phone wastes a full round-trip and costs trust — and the
reviewer usually cannot debug it. The classic cause is invisible in the source: a global function named
`top`, `name`, `status`, `open`, `close` or `parent` collides with a `window` property and the whole
script throws. A second failure is softer: a test page written as a plain numbered list gets one long
free-text reply, with steps silently skipped and nothing the agent can parse.

## Before every publish

```bash
S=.claude/skills/artifact-smoke
node $S/smoke.cjs page.html --expect '<selector of the main control>' [--shot /tmp/page.png]
python3 $S/test-page-check.py page.html --capabilities '{"db":{}}'
```

- `--expect` matters: a page can load without errors and still render nothing useful. Name the control
  the reader must see (the first option, the chart, the step list). Look at the `--shot` yourself.
- Playwright resolves from `$PLAYWRIGHT_MODULE`, then normal Node resolution. Missing = exit 2: a smoke
  that cannot look never passes.

## Test pages for humans: one verdict per step

Any page that asks a person to try something follows this contract (`test-page-check.py` enforces it):

- steps inside `[data-human-test]`, one `[data-step="<id>"]` each;
- every step has `data-verdict="ok"` / `"fail"` / `"partial"` controls (works / doesn't / works but not
  as expected) and a `[data-note]` field;
- verdicts are saved in shared, agent-readable storage (the Artifact `db` capability), not only in the
  viewer's browser — read them back instead of asking for a summary.
- Every step names exact taps and the expected result; the reference (design, before/after) is embedded
  on the page itself, never "go find it elsewhere"; never ask a human to check what automation can.

The "asks for a test" detector defaults to English phrases; pass `--asks '<regex>'` (or set
`ARTIFACT_TEST_ASKS` for the hook) for other languages.

## Enforce it with the hook (opt-in per repo)

`.claude/settings.json`:

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Artifact", "hooks": [
  { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/skills/artifact-smoke/hook.sh\"" } ] } ] } }
```

It acts only on a page publish of a local `.html` file (not reads, not asset uploads), runs the cheap
page-shape check first, then the headless load, and exits 2 with the reason so the agent fixes the page.
The hook cannot know which control must render — keep using `--expect` by hand.
