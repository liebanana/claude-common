---
name: decisions-page
description: Use when you need the user's decision, preference or feedback on something and the answer is not needed this second — publish questions to a claude.ai artifact with the db capability (tappable options, one recommended, free note) and read the answers with ArtifactData, instead of asking in chat. Also covers like/dislike feedback pages and capability triage pages.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Collect user decisions and feedback asynchronously through a claude.ai artifact backed by the db capability (questions/answers collections), with a round-closing protocol that keeps the page to pending items only
tags: [skill, decisions, artifact, async, communication, db]
---

# Decisions page (ask asynchronously, not in chat)

Chat is a bad place for questions: they scroll away, get answered out of order, and force long messages.
Put them on one persistent artifact page; in chat give **the link and one line**.

Needs the Artifact tool (publish) + `artifact-capabilities` skill (declare the `db` capability) + `ArtifactData` (read/write rows).

## Templates (`~/repos/claude-common/templates/decisions-page/`)

| File | Use | Collections |
|---|---|---|
| `decisions.html` | Question cards with tappable options (one `recommended`), free note, save; answered cards collapse into a history | `questions` (you write) / `answers` (user writes, doc id = question id) |
| `reactions.html` | Listen/look page: media + thumbs up/down + note per item | `reactions` |
| `triage.html` | Capability triage: now / later / no + note per row, for scoping a big thing | `triage` |
| `questions.example.json` | Shape of one question doc | |

Publish a template as-is (copy to scratchpad, then Artifact with `capabilities: {db: ...}` per `artifact-capabilities`; load that skill and `artifact-design` first). Then write questions with `ArtifactData` (`batch` for several):

```json
{"id":"q-slug","order":1,"group":"Area","open":true,"title":"One-line question","context":"<=2 sentences","options":[{"id":"a","label":"…","desc":"trade-off","recommended":true},{"id":"b","label":"…"}]}
```

Answers arrive as `answers/<question id>` = `{option, note, at}`. Read with `ArtifactData` `list`.

## Writing good questions

- **One recommended option per question**, with the reason in `desc`. Never ask a bare open question when you can propose.
- Context in two sentences; link a prototype artifact by pasting its `https://claude.ai/artifact/…` URL into `context` (the template renders it as a link).
- Batch questions; do not drip. Keep working on what is not blocked while they wait.
- Everything is debatable both ways: if the user's answer looks wrong, say so with evidence and a counter-proposal in a follow-up question; record the final decision either way.

## Round-closing protocol (when the user has answered)

1. **Export** every collection (`questions`, `answers`, `reactions`, `triage`) with `ArtifactData` into the repo, e.g. `docs/feedback/<date>/*.json`.
2. **Summarize** the decisions in a decisions log (`docs/decisions.md`): date, question, chosen option, note, consequence. The log is the source of truth, not the page.
3. **Close answered questions**: `ArtifactData` `update` each with `{"open": false}` (the template hides them from Pending; they stay under the history).
4. **Keep only pending items on the page** — new round = new questions only; never re-list decided ones.
5. Act on the decisions; in chat, give the link to the log and one line.

## Chat etiquette that goes with it

Short chat; details in files or pages; at most a few lines: what to look at, what to do, what to decide.
