# NeoLabHQ/context-engineering-kit  ·  ⭐1716  ·  adopt  ·  emerging
https://github.com/NeoLabHQ/context-engineering-kit · pushed 2026-08-26 · triaged 2026-09-21 · seen on hackernews

**What it is:** A hand-crafted marketplace of Claude Code (also OpenCode/Cursor/Antigravity/Gemini CLI-compatible) skills and plugins focused on context engineering: minimal token footprint, command-oriented skills with sub-agents preferred over general-info skills, each plugin scoped tight enough to avoid overlap/redundant loading. Includes a CodeRabbit-style open-source review plugin.

**Reusable for us:** The design principles map almost one-to-one onto `docs/token-thrift.md`: prefer narrow command-oriented skills over broad "read this doc" skills, load only what a task needs, avoid redundant skill overlap. Worth a direct read for concrete plugin examples we could imitate or link to.

**Token / effectiveness angle:** Its whole premise is "improve agent result quality without growing context" — the explicit goal of this repo. Good source of validated micro-patterns.

**How to adopt:** Read a few of its plugins next time we add a new skill to claude-common, to check our skill scoping against theirs. Consider linking it from `docs/token-thrift.md` as a case study.
