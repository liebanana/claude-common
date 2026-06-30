# hooks/ — shareable Claude Code hooks

Reusable hook scripts (PostToolUse formatters, guards, etc.) plus a snippet showing the
`settings.json` block to wire each one in. Hooks run from `settings.json`, so this dir
holds the **scripts**; you reference them from a repo's `.claude/settings.json`.

Empty for now — add hooks as you find/standardize them. List each in
[`../CATALOG.md`](../CATALOG.md), and keep a copy-pasteable settings snippet beside the
script so adoption is one step.
