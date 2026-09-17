# outcomeops/context-engineering  ·  ⭐128  ·  watch  ·  emerging
https://github.com/outcomeops/context-engineering · pushed 2026-05-17 · triaged 2026-07-20 · seen on hackernews

**What it is:** A reference implementation of "context engineering" as a 5-component discipline (corpus, retrieval, injection, output, enforcement), demonstrated end-to-end against a Spring PetClinic corpus on Amazon Bedrock. Companion code to a blog post; includes comparisons against plain RAG/Copilot/agent frameworks.
**Reusable for us:** Conceptual reference, not a drop-in tool — the corpus/retrieval/injection/output/enforcement framing is a useful vocabulary for structuring future `docs/` guidance on how we retrieve and inject context (relates to the progressive-disclosure pattern already noted from `GoogleCloudPlatform/knowledge-catalog`).
**Token / effectiveness angle:** Indirect — it's about context quality/governance, not raw token reduction.
**How to adopt:** watch — reread if we ever formalize a retrieval/injection layer for this repo's own knowledge base.
