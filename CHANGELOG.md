# Changelog

All notable changes to claude-common. Format: Keep a Changelog. Versions are git tags `vX.Y.Z`;
consumers pin to a tag via `scripts/sync-consumers.sh`.

## [Unreleased]
### Changed
- Generic by design: the consumer registry moved out of the repo into a gitignored
  `sync/consumers.local.json` (template `sync/consumers.example.json`, override `CLAUDE_COMMON_MANIFEST`).
- Directive: dropped project- and person-specific examples and attributions; the toolkit path now
  honors `$CLAUDE_COMMON_DIR`. Same rules, generic wording.
- `/oracle-status` owner values use `human` instead of a name; the `blocked_on_luis` key is kept
  for status-board compatibility.

### Added
- Directive §4: bounded wait loops; locate a user-reported problem in the live runtime before answering (#25).

## [v1.5.1] - 2026-10-19

### Removed
- `skills/manager-status`: withdrawn (work-derived asset; stays in its originating workspace). The sync deletes it from consumers. History rewritten the same day to purge a leaked identifier from the original contribution commits.

## [v1.5.0] - 2026-10-06

- manager-status skill; build-index skill ids; agency-agents reference; triage 09-28 + 10-05

### Added
- `skills/manager-status`: evidence-based management status update in a chat-paste emoji-bullet format (sources: control-plane docs, git log, open PRs, tracker query; certainty-ladder sections; outcome-first writing rules; audience calibration). Generalized from an enterprise workspace instance — workspace specifics stay in a local `.claude/skills/manager-status/` copy, which overrides the synced one.

## [v1.4.0] - 2026-09-28

- skills asset kind; shared skills (rehydrate, prepare-clear, verify-fix-claims); redact.py; ponytail agent; notify scripts

### Added
- `skills/` asset kind: `skills/<name>/SKILL.md` (+ sibling files) now syncs into consumers' `.claude/skills/<name>/` with the managed-by marker, the refuse-to-overwrite guard, lock entries and upstream-removal cleanup; `build-index.py` indexes `skills/*/SKILL.md`.
- First three shared skills: `verify-fix-claims` (grep-verify claimed fixes before committing, copied as-is), `rehydrate` (crash / cold-start recovery) and `prepare-clear` (safe clear / compact), the last two generalized from langtutor; `/session-handover` cross-references them.
- `.claude/agents/ponytail.md`: canonical anti-over-engineering agent (reconciled from the tradingdesk / Starlock / langtutor copies; project guardrails now come from the host repo's CLAUDE.md).
- `scripts/notify.sh` + `scripts/notify-hook.sh` + `scripts/notify.env.example`: env-driven Telegram notifier and Stop-hook wrapper (from claude-notify-bot); `tests/notify-test.sh`.
- `scripts/redact.py`: dependency-free secret scrubber (library + CLI, `--check` for pre-push sweeps), from the oracle project; tests in `tests/test_redact.py` via `tests/redact-test.sh`.

### Fixed
- No more hardcoded `/home/<user>` paths in `CLAUDE.md` / `scripts/cron-discover.sh` (use `$HOME`).

## [v1.3.0] - 2026-09-28

- No consumer-visible changes: cut before PRs #17–#19 merged (same as v1.2.0). Their content ships in v1.4.0.

## [v1.2.0] - 2026-09-24

- No consumer-visible changes: this tag was cut before the contribution PRs (#17–#19) merged. Their content ships in the next release.

## [v1.1.0] - 2026-09-23

- directive §6 ultracode provisioning; subagent-model safety net

### Added
- Directive §6 "Ultracode & workflow provisioning": explicit `model:`/`effort:` per role on every workflow `agent()` and Agent spawn, role→tier floor, additive-only repo overrides, 3-round loop cap, tier-mix reporting. Settings baseline now sets `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` as the harness safety net.

### Fixed
- `sync-consumers.sh` pushes with `--no-verify`: consumer pre-push hooks (langtutor preflight, topo-arch-ac `pnpm verify`) ran inside the scratch worktree and rejected the push; the consumer PR is the review gate.
- `sync-consumers.sh`: remote-aware lease. The "unchanged" shortcut no longer skips the push when the remote branch isn't actually at the sha it's about to report (topo-arch-ac: remote branch deleted, local unchanged — now re-pushed instead of silently doing nothing); the lease is now selected from the remote's real state via `ls-remote` (must-not-exist when absent, pinned to `$prev` when present) instead of assuming `$prev`, so a moved remote branch (langtutor: reviewer pushed, or the branch was never pushed from this host) is refused with a clear message instead of failing the lease forever.

## [v1.0.0] - 2026-09-18

- first tagged release: consumer sync, oracle-status, 135-repo research ledger

### Added
- `/oracle-status` command + directive rule: agents emit `.oracle/status.json` for the oracle board (#15); `oracle` added as a consumer.
- Consumer sync: `sync/consumers.json`, `scripts/sync-consumers.sh`, `scripts/release.sh`,
  `hooks/version-check.sh`, baseline settings + CLAUDE.md block templates.
- `CHANGELOG.md`.

### Changed
- `AGENT-DIRECTIVE.md` is now mastered here (was `~/repos/AGENT-DIRECTIVE.md` + `sync-directive.sh`).
