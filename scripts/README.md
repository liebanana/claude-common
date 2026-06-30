# scripts/ — deterministic helpers (any language)

Scripts that replace repeated agent command sequences. The rule of this repo: if an
agent would otherwise re-run the same steps and re-reason each time, encode it here
once.

**Contract for every script**
- Self-documents at the top (what, inputs, env knobs, output).
- Takes args / env for config; sane defaults.
- Idempotent where possible; safe to re-run.
- Exits non-zero on failure (so callers — including cron — can branch).
- No secrets in the file; read them from env / `.env`.
- Bash by default; reach for Python/other when it fits better.

**Current scripts**
- `discover.sh` — search GitHub for new agent/plugin/MCP repos, dedupe, emit candidates.
- `cron-discover.sh` — unattended discover → `/triage-discoveries` → commit loop.

Add new scripts here and list them in [`../CATALOG.md`](../CATALOG.md).
