# hooks/ — shareable Claude Code hooks

Reusable hook scripts (PostToolUse formatters, guards, etc.). Hooks shipped by the consumer
sync (`templates/settings.baseline.json` + `scripts/sync-consumers.sh`) are wired automatically —
no manual step. A hook meant to be hand-installed instead comes with a snippet here showing the
`settings.json` block to wire it in.

## Hooks

- `version-check.sh` — SessionStart: warns when `.claude/common.lock` is behind the newest claude-common tag (installed by `scripts/sync-consumers.sh`).
