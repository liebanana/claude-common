# kenryu42/claude-code-safety-net  ·  ⭐1452  ·  adopt  ·  trending
https://github.com/kenryu42/claude-code-safety-net · pushed 2026-06-30 · triaged 2026-07-20 · seen on hackernews

**What it is:** A `PreToolUse` hook that semantically parses shell commands (not just string-matches) to intercept and block destructive git/filesystem operations — `rm -rf ~`, `git checkout --`, force-pushes, etc. — before Claude Code, Codex, Copilot CLI, Gemini CLI, Kimi Code, OpenCode, or Pi execute them. Built after a real incident (an agent wiping a home directory).
**Reusable for us:** Directly on-mission — this is exactly the destructive-action guardrail our own `AGENT-DIRECTIVE.md` asks agents to reason about manually ("§ Executing actions with care"). A hard technical constraint is a stronger backstop than a soft instruction.
**Token / effectiveness angle:** n/a (safety, not tokens) but prevents costly recovery work after a destructive mistake.
**How to adopt:** Install/trial as a `PreToolUse` hook in a repo's `.claude/settings.json` (see `hooks/` dir here for our own pattern); if it holds up in practice, consider vendoring the hook config into `hooks/` with field notes on false-positive rate.
