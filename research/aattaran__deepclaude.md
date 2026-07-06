# aattaran/deepclaude  ·  ⭐2186  ·  watch  ·  emerging
https://github.com/aattaran/deepclaude · pushed 2026-05-16 · triaged 2026-07-06 · seen on hackernews · 63d↑

**What it is:** A wrapper script that swaps the model behind the Claude Code CLI for DeepSeek V4 Pro (or any Anthropic-compatible backend via OpenRouter), keeping the CLI's tool loop/file editing/bash/subagent behavior intact while routing the "thinking" to a much cheaper model (~$0.87/M vs $15/M output tokens, claimed 17x cheaper).
**Reusable for us:** Directly on-theme for token thrift (cheaper backend), but it's an unofficial hack that repoints the Claude Code CLI at a non-Anthropic API — worth knowing about as a data point on how far people push cost-cutting, not something to fold into our own tooling given we build specifically around Claude models.
**Token / effectiveness angle:** The core claim (same UX, ~17x cheaper per-token) is exactly our token-thrift mission's concern, even though the mechanism (backend swap) is out of scope for a Claude-first toolkit.
**How to adopt:** Watch. Note as prior art on cost-cutting via backend substitution; don't vendor — it's orthogonal to (and in tension with) building Claude-specific tooling.
