# magnitudedev/magnitude  ·  ⭐3955  ·  watch  ·  trending
https://github.com/magnitudedev/magnitude · pushed 2026-09-07 · triaged 2026-09-07 · seen on github-trending

**What it is:** An open-source local-inference server that profiles your machine, recommends models that fit, then downloads/tunes/runs them — pluggable into Claude Code, Codex, Cline, OpenCode, and other agent CLIs as a swap-in backend.
**Reusable for us:** Not a drop-in asset (it's a standalone server + its own harness), but directly relevant to token thrift: local-model routing is the purest form of "free" inference for routine/mechanical work, aligned with our §4 model-selection guidance in AGENT-DIRECTIVE.md.
**Token / effectiveness angle:** Local models eliminate API token cost entirely for tasks that don't need frontier reasoning — the auto-profiling/model-fit step is the interesting bit (removes the guesswork of "which local model fits my hardware").
**How to adopt:** Watch. Worth a hands-on trial before recommending — note in docs/token-thrift.md as an option for offloading bulk/mechanical work to a local model, but verify real-world quality/speed first (README claims untested).
