# Changelog

All notable changes to claude-common. Format: Keep a Changelog. Versions are git tags `vX.Y.Z`;
consumers pin to a tag via `scripts/sync-consumers.sh`.

## [Unreleased]

### Added
- `skills/defect-class-loop`: every user-reported bug or correction becomes, the same day, a fix + an
  applicability sweep + a named class in a registry + a guardrail where it was missed + an automated gate;
  retro mode turns a session's lessons into the cheapest guardrail that will fire. Ships `gate-check.py`
  (stdlib, `--selftest`): fails any registry class without a `- **Gate:**` line naming an existing test or an
  open tracked item; baseline ratchet for adoption; zero classes found is RED.
- `skills/artifact-smoke`: headless smoke of an HTML page before a human sees it (`smoke.cjs`, fails on
  script errors / an empty main control), `test-page-check.py` (a human-test page gives every step
  ok/fail/partial + a note, stored agent-readably), and an opt-in PreToolUse hook for the Artifact tool.
- `skills/backlog-by-impact`: read-only, impact-scored backlog review the human picks from (ease never
  counts), then execution of only the picked items through the full workflow, one worktree each.
- `docs/evidence-and-claim-levels.md`: claim levels, non-vacuous gates (examined count + deliberate RED,
  fail closed, green-with-a-skipped-step is not green), the review packet, handback contracts.
- `docs/parallel-writers-and-shared-hosts.md`: one writer per checkout, frozen deploy checkouts, served build
  id == SHA, no deploy while self-hosted CI runs, the systemd-oomd PSI session-kill and a heavy-job cap,
  delegates commit per slice, subagent permission limits, one recurring control loop.
- `docs/human-handoffs.md`: short visual status replies, documents printed in chat, clickable decisions with
  the recommendation first, human steps as one paste-safe script, admit every ask the same day, examples are
  seeds.
- `docs/ui-interaction-gate.md`: time real taps on a production build with injected server delay, taps-to-goal
  ratchet, serving checks from the entry point, consistency through shared primitives.
- New catalog groups: Verification & quality gates · Parallel agents & shared hosts · Working with humans.
- Tests: `tests/defect-class-gate-test.sh`, `tests/artifact-smoke-test.sh` (browser cases SKIP without Playwright); both in CI.

### Changed
- `skills/verify-fix-claims`: a "Claim levels" section — the grep proves *code present* only.

## [v1.6.0] - 2026-11-12

- Directive §7: UI/UX — Stitch mockup gates PLAN, Playwright fidelity gates merge
### Added
- **Directive §7 — UI/UX work: design before code, measured fidelity after.** A user-visible
  surface is specified as a `design.md`, mocked up through the Stitch MCP (`mcp__stitch__*`,
  programmatically — never the web UI), signed off by the human *before* PLAN, then verified with
  Playwright: structural conformance (tokens actually rendered, component states, hierarchy,
  breakpoints, a11y) as a **hard gate**, and the pixel diff against the Stitch screenshot as
  **advisory only**. Weakening a fidelity assertion to go green is the same defect class as
  weakening a test.
- `docs/ui-fidelity-playwright.md` — the measuring half: assert *membership in the token set*
  rather than per-element equality, freeze nondeterminism, keep the gate in the repo's own
  `@playwright/test` suite (MCP is for exploration), plus the font/DPR/dark-mode traps.
- New catalog group **Design & UI fidelity**, holding the Stitch workflow doc and the fidelity doc
  as one pipeline.

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
