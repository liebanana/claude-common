# millionco/react-doctor  ·  ⭐13279  ·  skip
https://github.com/millionco/react-doctor · pushed 2026-06-30 · triaged 2026-06-30

**What it is:** "Your agent writes bad React. This catches it." A code-review skill/agent that detects React anti-patterns the model tends to produce.
**Reusable for us:** React-specific, so not a general asset. But the *pattern* is exactly our token-thrift principle "give the agent a way to verify its work" — a focused, domain-specific lint/verify skill that closes the feedback loop and prevents wasted fix-cycles.
**Token / effectiveness angle:** The pattern (cheap deterministic verifier catching predictable agent mistakes) saves iteration tokens; the implementation doesn't transfer.
**How to adopt:** Skip the repo; the transferable idea is already captured under "give the agent a way to verify" in `docs/token-thrift.md`. Revisit only for React projects.
