# hooks/ — shareable Claude Code hooks

Reusable hook scripts (PostToolUse formatters, guards, etc.) plus a snippet showing the
`settings.json` block to wire each one in. Hooks run from `settings.json`, so this dir
holds the **scripts**; you reference them from a repo's `.claude/settings.json`.

## Hooks

- `version-check.sh` — SessionStart: warns when `.claude/common.lock` is behind the newest claude-common tag (installed by `scripts/sync-consumers.sh`).
