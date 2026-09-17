# Imbad0202/academic-research-skills  ·  ⭐46760  ·  watch  ·  trending
https://github.com/Imbad0202/academic-research-skills · pushed 2026-09-06 · triaged 2026-09-07 · seen on github, github-trending

**What it is:** A Claude Code plugin-marketplace skill suite covering the full academic paper pipeline (research → write → review → revise → finalize), including a Socratic `/ars-plan` planning flow, citation/reference verification, and a "style calibration" pass that learns the author's voice. CC BY-NC 4.0.
**Reusable for us:** Off our core mission (we're not writing papers), but the *packaging* pattern is worth noting: installs as a one-command plugin-marketplace add (`/plugin marketplace add ...`), and structures the pipeline as discrete phase-gated skills (plan → draft → verify → polish) — similar shape to our own analyze→brainstorm→spec→plan→implement directive.
**Token / effectiveness angle:** Human-in-the-loop by design (explicitly rejects full autonomy) to avoid hallucinated citations/results — a philosophy alignment with "verify before claiming," not a token-cost technique per se.
**How to adopt:** Watch only. Noncommercial license blocks reuse of any actual code; nothing to vendor. Revisit if we ever want a plugin-marketplace-distributed command bundle as a reference implementation.
