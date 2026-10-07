# Session handover — 2026-10-06 (claude-common orchestration lane)

**Lane:** fleet-wide claude-common adoption (consumer sync, shared skills, contributions). **Writer:** interactive Claude Code session "common" (Fable 5.1). **Mode at pause:** DRAINING_FOR_CLEAR → clear requested by Luis. **Resume with:** the `rehydrate` skill (or `/session-handover resume`).

## State (exact)
| Repo | Branch | HEAD | Remote | Dirty | Note |
|---|---|---|---|---|---|
| claude-common | main | 91bb40bd05994d611e3c16049db534a4dd7c9e0a | origin/main = same before this commit | none | v1.5.0 released + synced; this handover commit is the only unpushed change |
| langtutor | main | 320aa52 | origin/main is 1 behind | none | commit `chore: suffix Zonti-specific agent/skills (-zonti)` — UNPUSHED, Luis pushes |
| claude-tradingdesk | chore/ponytail-rename (worktree `claude-common/state/contrib-wt/td-ponytail`, off origin/main) | 668672b | not on remote | none | rename ponytail → ponytail-trading — UNPUSHED; Luis's own local main is diverged (24 ahead / 4 behind), untouched |
| 12 other consumers | default | — | — | — | all `current` at v1.5.0 (`scripts/sync-consumers.sh --status`) |

Children/subagents: none alive. Worktrees of merged branches removed; remote branches deleted. Open claude-common PRs: none. Consumer PRs: none open from the sync.

## Completed this lane (durable)
- Consumer sync mechanism (spec `docs/superpowers/specs/2026-09-14-consumer-sync-design.md`), releases v1.0.0 → v1.5.0 (v1.2.0/v1.3.0 are pin-only, see CHANGELOG), 14 consumers + oracle in `sync/consumers.json`, weekly cron Mon 09:00 discover / 09:30 sync.
- Directive §6 (ultracode provisioning); baseline `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (also in `~/.claude/settings.json`).
- Shared skills: rehydrate, prepare-clear, verify-fix-claims, manager-status; agent ponytail; scripts redact.py, notify.sh/notify-hook.sh; 170-repo research ledger (agency-agents = adopt as reference catalog).

## next_exact_action
1. Luis runs the hand-off block (pushes langtutor main, pushes + merges tradingdesk `chore/ponytail-rename`, pushes this handover, then `AUTO_PUSH=1 scripts/sync-consumers.sh --repo langtutor --repo claude-tradingdesk`).
2. Next session: verify the two consumer PRs that run opens contain only managed paths (allow-list: 4 commands, agents/ponytail.md, skills/{rehydrate,prepare-clear,verify-fix-claims,manager-status}, common.lock, hooks/common/version-check.sh, settings.json, AGENT-DIRECTIVE.md, CLAUDE.md), merge them with `gh pr merge --merge --delete-branch`, run `--status` → expect 14 current.
3. Then remove the tradingdesk worktree: `git -C ~/repos/claude-tradingdesk worktree remove state/contrib-wt/td-ponytail` (path is under claude-common/state) and `git -C ~/repos/claude-tradingdesk branch -d chore/ponytail-rename` once merged.

## Blockers
- Human-only: pushes (claude-common's `.claude/settings.json` denies `git push` to agents). Nothing else.

## Parked follow-ups (not blocking)
- mix-hunters: delete its duplicate `.claude/skills/session-handover/` (same content as the shared `/session-handover` command).
- langtutor `CLAUDE.md` should point at `BUG-CLASS-REGISTRY.md` explicitly (the shared ponytail reads "the registry your CLAUDE.md names").
- Per-asset opt-out for the sync (so a repo can decline a shared asset); `/triage-discoveries` is shipped to repos where it cannot run.
- GitHub Actions on Luis's private repos fail instantly (billing) — not code.
- Cloudflare security-audit-skill: trial on claude-notify-bot, then language-tutor; flip ledger status to `trialed`.

## Cold-resume read order
1. this file · 2. `.oracle/status.json` · 3. `scripts/sync-consumers.sh --status` · 4. `gh pr list` in claude-common, langtutor, claude-tradingdesk · 5. `CHANGELOG.md` [Unreleased].

## Addendum (same session, after the hand-off block ran)
All pushes done by Luis. tradingdesk rename merged (PR #7), consumer PRs claude-tradingdesk #8 and langtutor #20 verified (9 managed files each) and merged; tradingdesk worktree + branch removed. `scripts/sync-consumers.sh --status` → **14 current, 1 self**. Steps 1–3 of next_exact_action are complete; nothing is pending. Blocked-on-Luis cleared.
