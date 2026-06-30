# addyosmani/agent-skills  ·  ⭐68155  ·  adopt
https://github.com/addyosmani/agent-skills · pushed 2026-06-28 · triaged 2026-06-30

**What it is:** Addy Osmani's "production-grade engineering skills for AI coding agents" — 8 slash commands (`/spec`, `/plan`, `/build`, `/test`, `/review`, `/webperf`, `/code-simplify`, `/ship`) that map the dev lifecycle and auto-activate the right skills per phase.
**Reusable for us:** The lifecycle command set + skill-packaging structure. Clean, reputable model for how to author phase-gated slash commands that pull in skills (each command = a stage with a "key principle"). Good reference when we add our own commands beyond `/triage-discoveries`.
**Token / effectiveness angle:** Encoding senior-engineer workflows as skills means the agent follows a consistent path instead of re-deriving process each session — fewer wasted exploratory turns. Phase gates keep work scoped.
**How to adopt:** Mine the command frontmatter/skill split for our `.claude/commands/`. Consider a slimmed `/spec`→`/plan`→`/ship` trio if we want lifecycle commands. Catalog under reusable Claude Code assets.
