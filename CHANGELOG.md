# Changelog

All notable changes to claude-common. Format: Keep a Changelog. Versions are git tags `vX.Y.Z`;
consumers pin to a tag via `scripts/sync-consumers.sh`.

## [Unreleased]

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
