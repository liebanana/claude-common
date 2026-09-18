# Changelog

All notable changes to claude-common. Format: Keep a Changelog. Versions are git tags `vX.Y.Z`;
consumers pin to a tag via `scripts/sync-consumers.sh`.

## [Unreleased]

### Added
- `/oracle-status` command + directive rule: agents emit `.oracle/status.json` for the oracle board (#15); `oracle` added as a consumer.
- Consumer sync: `sync/consumers.json`, `scripts/sync-consumers.sh`, `scripts/release.sh`,
  `hooks/version-check.sh`, baseline settings + CLAUDE.md block templates.
- `CHANGELOG.md`.

### Changed
- `AGENT-DIRECTIVE.md` is now mastered here (was `~/repos/AGENT-DIRECTIVE.md` + `sync-directive.sh`).
