# aattaran/deepclaude  ·  ⭐2259  ·  watch  ·  emerging
https://github.com/aattaran/deepclaude · pushed 2026-07-23 · triaged 2026-09-07 · seen on hackernews

**What it is:** A thin wrapper/config technique that points the Claude Code CLI's model backend at DeepSeek V4 Pro (or any Anthropic-compatible endpoint via OpenRouter) instead of Anthropic's API — same tool loop (file edit, bash, git, subagents), swapped "brain," claimed ~17x cheaper per the README.
**Reusable for us:** The underlying technique (env-var backend swap for Claude Code) is directly on-mission for token thrift, but this is a third-party wrapper around an *unverified* "Anthropic-compatible" claim — quality/compatibility of DeepSeek as a full Claude Code backend is untested here. Not something to vendor as-is; the technique (not the script) is the reusable part.
**Token / effectiveness angle:** Exactly our §4 "lowest-cost capable model" thrift goal, taken to the extreme (swap the whole harness's model, not just subagents). Worth flagging as a pattern in docs/token-thrift.md once trialed.
**How to adopt:** Watch — trial before recommending. If verified to work reliably, the technique (not this specific repo) belongs in docs/token-thrift.md as an advanced option; note the trade-off (quality/tool-call fidelity vs. cost) explicitly.
