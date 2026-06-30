# agents/ — shareable subagents

Subagent definitions (Markdown with frontmatter: `name`, `description`, `tools`).
`install.sh` symlinks every `*.md` here into `~/.claude/agents/` and, optionally, a
target repo's `.claude/agents/`.

Empty for now — populate as `/triage-discoveries` finds reusable subagents worth
adopting, or as you extract your own. List each in [`../CATALOG.md`](../CATALOG.md).
