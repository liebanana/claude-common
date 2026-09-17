# kenryu42/claude-code-safety-net  ·  ⭐1440  ·  adopt  ·  emerging
https://github.com/kenryu42/claude-code-safety-net · pushed 2026-06-30 · triaged 2026-07-13 · seen on hackernews

**What it is:** A PreToolUse hook that intercepts and blocks destructive git/filesystem commands (e.g. `rm -rf ~`, `git checkout --`) before an AI coding agent's Bash tool runs them — parses command *semantics* so flag reordering/shell wrappers/interpreter one-liners can't bypass it. Built after a real incident (an agent wiping a user's home directory). Supports seven agent CLIs including Claude Code, Codex, Gemini CLI.
**Reusable for us:** A direct fit for this repo's `hooks/` directory — exactly the kind of hard technical guardrail our own `AGENT-DIRECTIVE.md` calls for ("measure twice, cut once" around destructive git ops) but enforced mechanically instead of relying on the agent reading instructions.
**Token / effectiveness angle:** n/a — safety tool, not a token optimizer. But it prevents catastrophic, expensive-to-recover-from mistakes.
**How to adopt:** Worth trialing as a PreToolUse hook (Node.js 18+ required) and, if it holds up, documenting install steps in `hooks/` here as a recommended shared hook.
