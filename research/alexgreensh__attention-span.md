# alexgreensh/attention-span  ·  ⭐1123  ·  adopt  ·  emerging
https://github.com/alexgreensh/attention-span · pushed 2026-09-06 · triaged 2026-09-21 · seen on github

**What it is:** A small set of Claude Code [output styles](https://code.claude.com/docs/en/output-styles) — single markdown files you drop in and switch on — that change how Claude *talks*, not how it codes: answer-first, plain English, easy to skim. Three so far: Attention-kind (ADHD-friendly flagship), Spartan (terse, zero warmth), Rundown (TL;DR briefings).

**Reusable for us:** Directly — output styles are a first-class Claude Code mechanism we don't currently have an asset for in claude-common. These are small, single-file, MIT-compatible-looking, and immediately installable with no dependencies.

**Token / effectiveness angle:** The author is explicit that trimming output tokens is "a welcome side effect, not the point" of the concise-by-default design — but it's still a real token reduction with zero setup cost.

**How to adopt:** Try one (Spartan or Attention-kind) as a personal output style; if it holds up, stub a reference/pointer to it under `.claude/` assets or link it from `docs/token-thrift.md` as a ready-made output-style option.
