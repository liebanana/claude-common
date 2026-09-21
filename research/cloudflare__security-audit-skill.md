# cloudflare/security-audit-skill  ·  ⭐18707  ·  adopt  ·  trending
https://github.com/cloudflare/security-audit-skill · pushed 2026-09-14 · triaged 2026-09-21 · seen on github-trending

**What it is:** A coding-agent skill that turns an agent into a security auditor via six phases: reconnaissance (architecture map + deterministic coverage ledger), coverage-led hunting by isolated "hunter" subagents, candidate validation by a fresh adversarial verifier, schema-validated structured findings (`confirmed`/`needs_validation`/`rejected`), independent re-verification of source claims, and target-neutral reporting. It's the single-repo seed of Cloudflare's fleet-wide vulnerability-discovery harness (see their blog post "Build your own vulnerability harness").

**Reusable for us:** The verification architecture, not the security domain — every finding goes through a fresh, isolated verifier that tries to disprove it before being marked `confirmed`, and re-runs are additive against a persistent coverage ledger instead of re-scanning from scratch. That's directly applicable to our own `code-review` skill and to `verify-fix-claims`: adversarial re-verification by a separate agent, and a ledger that tracks what's already been checked so repeat runs target gaps instead of redoing work.

**Token / effectiveness angle:** The coverage ledger is the token-saving mechanism — it lets multiple runs be additive (only revalidate changed source, carry forward stale-free evidence) instead of re-deriving full coverage every time.

**How to adopt:** Read the skill's phase breakdown next time `code-review`/`verify-fix-claims` gets revised, and consider borrowing the "coverage ledger + independent verifier + schema-validated findings" pattern for high-stakes review work.
