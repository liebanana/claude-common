# commands/ — shareable slash commands

Markdown slash commands reusable across repos and hosts. `install.sh` symlinks every
`*.md` here (except this README) into `~/.claude/commands/` and, optionally, a target
repo's `.claude/commands/`.

Each file is a command: optional YAML frontmatter (`description`, `argument-hint`,
`allowed-tools`) then the instructions body. Invoke as `/<filename-without-.md>`.

- `triage-discoveries.md` — analyze new GitHub agent candidates into catalog + research.
