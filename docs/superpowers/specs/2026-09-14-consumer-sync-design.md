# Consumer sync: every project on the latest stable claude-common

**Status:** approved design (Luis, 2026-09-14). **Owner:** orchestrator session + Luis.
**Supersedes:** `~/repos/sync-directive.sh` and the master-copy-in-`~/repos` scheme.

## Problem

13 repos/worktrees under `~/repos` carry a byte-identical `AGENT-DIRECTIVE.md` and import it from
`CLAUDE.md`, but nothing else is shared: no repo has claude-common's commands/agents in its own
`.claude/`, none has a hooks baseline, none states "check claude-common first", and there is no
notion of a *version* — the master directive lives outside any repo and is pushed by an ad-hoc
`cp` loop. Three active repos (mix-hunters, Starlock, vault) are not standardized at all.

## Goal

Every consumer repo runs on the **same, pinned, tagged release** of claude-common, and moving a
repo to a newer release is an automated, reviewable PR — never a hand-run copy and never an
unreviewed push to a default branch.

## Decisions (locked)

| Decision | Choice |
|---|---|
| "Stable" means | annotated git tag `vX.Y.Z` on claude-common `main` |
| Delivery | local script on this host + weekly cron → **one PR per repo** |
| Scope of shared content | directive · commands · subagents · hooks + baseline `settings.json` · CLAUDE.md bootstrap block |
| Consumer set | 10 current carriers + tradingdesk, mix-hunters, Starlock, vault; worktrees skipped; exclude list for CPE/PepsiCo-related repos (none exist today) |
| Files in consumers | **copies**, committed (portable to any host); never symlinks |

## 1. Source of truth and releases

- `claude-common/AGENT-DIRECTIVE.md` **is** the master. `~/repos/AGENT-DIRECTIVE.md` becomes a
  symlink to it; `~/repos/sync-directive.sh` is deleted; `~/repos/CLAUDE.md` stub is updated to
  point at claude-common and the new script.
- `CHANGELOG.md` at claude-common root, Keep-a-Changelog style, with an `## [Unreleased]` section.
- `scripts/release.sh <major|minor|patch> [-m "note"]`:
  1. refuses if not on `main`, tree dirty, or `main` behind `origin/main`;
  2. computes next version from the latest `v*` tag (none → `v1.0.0`);
  3. moves `[Unreleased]` → `## [vX.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`, writes claude-common's own
     `.claude/common.lock` + CLAUDE.md block (the `self` consumer), runs `build-index.py`;
  4. commits `release: vX.Y.Z`, creates annotated tag `vX.Y.Z`, pushes commit + tag.
- Consumers only ever receive content checked out from a tag.

## 2. Consumer manifest — `sync/consumers.json` (committed, no secrets)

```json
{
  "root": "~/repos",
  "exclude": [],
  "consumers": [
    { "repo": "claude-ai-trends",        "mode": "pr" },
    { "repo": "claude-notify-bot",       "mode": "pr" },
    { "repo": "claude-stay-tripper",     "mode": "pr" },
    { "repo": "claude-tradingdesk",      "mode": "pr" },
    { "repo": "claude-language-content", "mode": "pr" },
    { "repo": "claude-language-medialab","mode": "pr" },
    { "repo": "claude-language-tutor",   "mode": "pr" },
    { "repo": "langtutor",               "mode": "pr" },
    { "repo": "langtutor-infra",         "mode": "pr" },
    { "repo": "topo-arch-ac",            "mode": "pr" },
    { "repo": "mix-hunters",             "mode": "pr" },
    { "repo": "Starlock",                "mode": "pr" },
    { "repo": "vault",                   "mode": "pr" },
    { "repo": "claude-common",           "mode": "self" }
  ]
}
```

- `mode`: `pr` (default behavior), `skip` (listed but ignored), `self` (claude-common itself:
  only the lock + CLAUDE.md block are written, directly on the release commit).
- `exclude`: names never synced and never reported by `--discover`.
- `--discover` prints git repos directly under `root` that are in neither list (e.g. a future
  `dreamscape` clone). Worktrees (`git rev-parse --git-common-dir` ≠ `.git`) and non-repos are
  skipped silently, so `wt/`, `*-dev`, `*-m05`, `gh-runner`, `actions-runner`,
  `_archive-pre-monorepo` never appear.

## 3. The contract — what a synced repo contains

| Path in consumer | Source in claude-common | Rule |
|---|---|---|
| `AGENT-DIRECTIVE.md` | `AGENT-DIRECTIVE.md` | verbatim copy |
| `.claude/commands/<n>.md` | `.claude/commands/<n>.md` | copy; frontmatter gains `managed-by: claude-common` |
| `.claude/agents/<n>.md` | `.claude/agents/<n>.md` | copy; same marker |
| `.claude/hooks/common/<n>.sh` | `hooks/<n>.sh` | copy, `chmod +x` |
| `.claude/settings.json` | `templates/settings.baseline.json` | jq deep-merge, **repo keys win**; hook entries deduped by `command`; arrays unioned |
| `CLAUDE.md` | `templates/claude-md-block.md` | upsert block between `<!-- claude-common:begin -->` / `<!-- claude-common:end -->`; delete stray `@AGENT-DIRECTIVE.md` lines outside it; missing file → scaffold `# <repo>` + block |
| `.claude/common.lock` | generated | `{"version","synced","managed":[…paths…]}` |

- **Managed vs local:** only files listed in the previous lock's `managed` array (or carrying the
  marker) are ever overwritten or deleted. Repo-local agents/commands/skills are never touched.
  A managed file dropped upstream is deleted downstream on the next sync.
- **Baseline v1** (`templates/settings.baseline.json`): `permissions.deny` for `Read(./.env)` and
  `Read(./.env.*)`; a `SessionStart` hook running `.claude/hooks/common/version-check.sh`.
- **Hook v1** (`hooks/version-check.sh`): reads `.claude/common.lock`, compares to the newest
  `v*` tag in `~/repos/claude-common` (local only, no network); prints one line
  `claude-common: repo pinned vA, latest vB — run scripts/sync-consumers.sh` when behind, nothing
  otherwise; exits 0 always; silent if claude-common is absent on the host.
- **CLAUDE.md block content:** the `@AGENT-DIRECTIVE.md` import, `claude-common: vX.Y.Z`, and the
  three-line "check `~/repos/claude-common` (`index.json` via jq / `CATALOG.md`) before building
  tooling; use it or surface it; `/contribute-to-common` for reusable learnings" rule. Everything
  outside the markers is the repo's own and is never rewritten.

## 4. The sync run — `scripts/sync-consumers.sh`

```
sync-consumers.sh [--status] [--dry-run] [--discover] [--repo NAME]... [--version vX.Y.Z] [--root DIR]
```

- Target version = `--version` or the newest `v*` tag (`git tag --sort=-v:refname | head -1`);
  refuses to run with no tag. Content is exported from the tag via `git archive` into a temp dir —
  never from the working tree.
- Per consumer (skip if lock version == target, unless `--repo` forces):
  1. resolve default branch (`origin/HEAD`, else `main`, else `master`); `git fetch` if a remote exists;
  2. `git worktree add <scratch>/<repo> -B common/vX.Y.Z <default>` (reuses the branch if it exists →
     re-runs update the same PR); the user's working tree and its dirty files are never touched;
  3. apply §3 in the worktree; if nothing changed → clean up, report `up-to-date`;
  4. commit `chore: sync claude-common vX.Y.Z` (+ standard trailer);
  5. remote present → `git push -u origin common/vX.Y.Z`, `gh pr create` (or `gh pr edit` if open)
     with a body listing changed paths and the CHANGELOG delta; no remote (langtutor-infra) →
     leave the local branch and say so;
  6. remove the scratch worktree (branch stays).
- `--status` prints a table: repo · pinned · latest · state (`current` / `behind` / `pr-open #N` /
  `unmanaged` / `no-remote`). `--dry-run` prints the per-repo diff summary without committing.
- Never writes to a default branch. Never pushes claude-common. Exit non-zero if any consumer failed;
  keeps going through the rest.
- Cron (weekly, after discovery): `30 9 * * 1 …/scripts/sync-consumers.sh >> state/sync.log 2>&1`.
  `AUTO_PUSH=1` gates push+PR exactly like `cron-discover.sh`.

## 5. Verification / definition of done

- `bash -n` + `shellcheck` (if installed) clean on `release.sh`, `sync-consumers.sh`, `hooks/*.sh`.
- `tests/sync-smoke.sh`: builds a temp root with (a) a bare-remote-backed repo with an existing
  CLAUDE.md, local agent, and `settings.json` containing `enabledPlugins`; (b) a repo with no
  CLAUDE.md; (c) a worktree; (d) a no-remote repo. Runs the sync against a local tag and asserts:
  block upserted once and import not duplicated; scaffold created; managed files copied with marker;
  local agent and `enabledPlugins` preserved; hook deduped on re-run; lock correct; worktree skipped;
  no-remote repo gets a branch; second run is a no-op. Exit 0 ⇒ pass.
- `--dry-run` against the real `~/repos` shows expected changes only.
- `release.sh patch` → `v1.0.0`; `sync-consumers.sh` opens 13 PRs (12 remote + 1 local branch);
  `--status` shows all `pr-open`; Luis merges; `--status` shows all `current`; a SessionStart in any
  repo prints nothing (up to date).

## Non-goals (follow-ups, tracked, not done here)

- Repo-local rule drift: `topo-arch-ac/CLAUDE.md` hardcodes an `Opus 4.8` commit trailer;
  `claude-tradingdesk/CLAUDE.md` restates autonomy rules the directive already owns;
  `langtutor` points at `claude-language-tutor/.claude/MODEL-POLICY.yaml` cross-repo.
- Packaging claude-common as a Claude Code plugin (possible later swap for commands/agents/hooks).
- GitHub-Actions-driven delivery; `dreamscape` (on GitHub, not cloned here).
- CI/tests standardization across repos (separate consolidation-plan tier).
