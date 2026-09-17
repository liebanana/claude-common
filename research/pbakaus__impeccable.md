# pbakaus/impeccable  ·  ⭐46225  ·  watch  ·  trending
https://github.com/pbakaus/impeccable · pushed 2026-07-10 · triaged 2026-07-13 · seen on github, github-trending

**What it is:** A design-guidance package for AI coding agents — 1 skill, 23 commands (`polish`, `audit`, `critique`, `distill`, `animate`...), live-browser iteration, and 46 deterministic detector rules that catch generic AI-generated-frontend tells (Inter font, purple gradients, cards-in-cards). Explicitly built as a successor to Anthropic's own `frontend-design` skill.
**Reusable for us:** We already ship `frontend-design` (from Anthropic) as an invokable skill. Impeccable is a plausible upgrade/alternative — worth a side-by-side trial before recommending a swap, since it claims measurable detector rules rather than just prose guidance.
**Token / effectiveness angle:** Deterministic detector rules could catch templated-design tells cheaper than an LLM self-critique pass.
**How to adopt:** Watch. If a future frontend-heavy task wants stronger anti-generic-design guidance, trial `npx impeccable install` + `/impeccable init` against our existing `frontend-design` skill and compare before deciding to add/replace.
