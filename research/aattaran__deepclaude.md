# aattaran/deepclaude  ·  ⭐2253  ·  skip  ·  trending
https://github.com/aattaran/deepclaude · pushed 2026-07-23 · triaged 2026-08-24 · seen on hackernews

**What it is:** A shell/PowerShell wrapper that repoints Claude Code's `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN`/model env vars at DeepSeek V4 Pro, OpenRouter, or Fireworks, so the Claude Code CLI's tool loop runs on a non-Anthropic backend for a fraction of the API cost.
**Reusable for us:** Off-mission by design — this toolkit is about making *Claude* more effective and token-cheap, not routing Claude Code's UI onto a different vendor's model. Swapping the underlying model changes correctness/safety guarantees in ways this repo shouldn't recommend.
**Token / effectiveness angle:** It is a cost-reduction technique, but one this toolkit deliberately doesn't want to encode (see repo mission: Claude Code / Claude agents specifically).
**How to adopt:** Skip.
