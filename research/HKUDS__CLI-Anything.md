# HKUDS/CLI-Anything  ·  ⭐50849  ·  watch  ·  trending
https://github.com/HKUDS/CLI-Anything · pushed 2026-09-22 · triaged 2026-09-28 · seen on github-trending

**What it is:** A framework (plus community registry "CLI-Hub") that wraps arbitrary desktop/web software into agent-native CLI harnesses, each packaged with a Claude-Code/Cursor/OpenClaw-compatible `SKILL.md` under a canonical `skills/` directory, installable via `npx skills add`.
**Reusable for us:** None directly adoptable (it's a large multi-language harness generator with its own CI/registry), but the `skills/` + `npx skills add <repo> --skill <name>` packaging convention is a distribution pattern worth watching — it's a cleaner way to let other repos install a single skill than claude-common's current symlink-based `install.sh`.
**Token / effectiveness angle:** n/a directly; its value is turning non-agent software into tool-callable CLIs, not token thrift per se.
**How to adopt:** watch — revisit the `npx skills add` convention if we ever want claude-common assets to be installable outside the symlink model.
