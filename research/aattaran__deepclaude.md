# aattaran/deepclaude  ·  ⭐2204  ·  watch  ·  emerging
https://github.com/aattaran/deepclaude · pushed 2026-05-16 · triaged 2026-07-13 · seen on hackernews

**What it is:** Points the Claude Code CLI's tool loop (file editing, bash, git, subagents — unchanged) at DeepSeek V4 Pro or any Anthropic-compatible backend instead of Anthropic's API, claiming ~17x lower cost per token than the $200/mo Claude Code plan.
**Reusable for us:** Directly on-mission for token/cost thrift, but swapping the underlying model changes reasoning quality and safety behavior in ways a README can't certify — real evaluation needed before trusting it for anything beyond low-stakes tasks.
**Token / effectiveness angle:** The core pitch (same agent loop, far cheaper backend) is exactly our "lowest-cost capable model" directive taken to an extreme (non-Anthropic backend) — worth knowing about even if we don't act on it.
**How to adopt:** Watch only. Do not route real work through it without first trialing on throwaway tasks and comparing output quality/safety vs. native Claude models.
