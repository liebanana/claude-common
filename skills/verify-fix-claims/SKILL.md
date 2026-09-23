---
name: verify-fix-claims
description: Use before committing or reporting any batch of code fixes — verifies that each fix you are about to CLAIM is actually present in the source, catching edits that silently no-op'd. Invoke whenever a commit message, PR comment, or status report will assert that specific fixes landed.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Grep-verify every fix you are about to claim landed (present) or was removed (absent) before it goes in a commit message, PR comment, or status report
tags: [skill, verification, code-review, commit-hygiene]
---

# Verify what you are about to claim

An edit that silently fails to apply produces a commit message describing work that is not in the
code — and CI passes, because nothing changed. This has happened twice on one project in a single
session, both times in a batch where a later step in the same edit script raised and aborted the
write. Both were caught only by an independent reviewer reading the source, not the prose.

**The rule: never claim a fix you have not grepped for after writing it.**

## Do this before every commit that claims fixes

1. List each fix as a **marker** — a distinctive string that exists in the source *if and only if*
   the fix landed. A new function name, a new constant, a changed predicate. Not a comment.
2. For deletions, list the marker that must now be **absent**.
3. Run the check. Anything MISSING or STILL-PRESENT means the claim is false — fix the code or drop
   the claim before committing.

```bash
bash ~/.claude/skills/verify-fix-claims/check.sh \
  +'per-member merge|packages/server/src/x.ts|ownStreamViaPerMemberMerge' \
  -'global cursor removed|packages/server/src/x.ts|ownStreamViaGlobalCursor'
```

`+` = must be present, `-` = must be absent. Format: `<label>|<file-or-dir>|<marker>`. The delimiter
is `|`, not `:`, because labels and markers routinely contain colons — the first version of this
script used `:` and mis-parsed its own first self-test, reporting a present marker as MISSING.

## Two traps this exists for

- **A comment is not a marker.** Historical references ("…is gone", a rejected-approach list) will
  match a deletion check and read as failure. Grep the hits and confirm whether they are code or
  prose before acting.
- **A passing test is not proof the fix landed.** If the edit no-op'd, the test may be measuring
  something the old code already satisfied. Verify the marker *and* verify the regression fails
  against the pre-fix behaviour.

## Related discipline

Pair this with the edit rule itself: assert the target exists before replacing it, and never let one
script apply several edits where a later failure silently discards the earlier writes — write and
verify each, or write once at the end only after every anchor has matched.
