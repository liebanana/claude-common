# alibaba/open-code-review  ·  ⭐24858  ·  watch  ·  trending
https://github.com/alibaba/open-code-review · pushed 2026-09-14 · triaged 2026-09-14 · seen on github-trending

**What it is:** Alibaba's internal-turned-open-source AI code review CLI (`ocr`). Hybrid architecture: deterministic pipelines + an LLM agent with tool use, producing line-precise review comments. Claims (via a published 50-repo/200-PR/10-language benchmark, AACR-Bench on HuggingFace) ~1/9 the tokens of general-purpose agent review (e.g. Claude Code with Skills) at higher precision/F1, trading off some recall.
**Reusable for us:** Directly relevant to `/code-review`-style workflows: the core idea (deterministic pre-pass narrows the search space, LLM agent only reasons over what's flagged, instead of a pure natural-language skill re-deriving everything) is a concrete technique for cutting review token cost while reducing position drift/coverage gaps that plague skill-only reviewers.
**Token / effectiveness angle:** Its whole pitch is measured token/quality tradeoffs for code review — most on-mission candidate this batch after chrome-devtools-mcp.
**How to adopt:** watch — trial the `ocr` CLI on a real PR and compare token cost/precision against our own review skills before deciding whether to recommend it or just borrow the deterministic-pipeline technique.
