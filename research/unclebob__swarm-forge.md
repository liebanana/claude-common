# unclebob/swarm-forge  ·  ⭐2095  ·  watch  ·  emerging
https://github.com/unclebob/swarm-forge · pushed 2026-08-09 · triaged 2026-08-10 · seen on github-trending

**What it is:** Robert C. Martin's ("Uncle Bob") tmux-based multi-agent orchestration platform: role-specific agents (coder/cleaner/architect/specifier/hardener/QA) work in separate git worktrees and pass messages, with three preset pipelines (`two-pack`/`four-pack`/`six-pack`) of increasing rigor (TDD → +Gherkin spec → +full QA/hardening gates).
**Reusable for us:** A concrete, well-specified role-pipeline pattern for multi-agent dev work (specifier → coder → refactorer/cleaner → architect → QA), conceptually close to `superpowers:subagent-driven-development` and worktree-isolated agent work, but the implementation is a whole local platform (zsh, tmux, Babashka, per-branch configs) rather than a drop-in script.
**Token / effectiveness angle:** The staged-rigor idea (skip Gherkin/QA gates for small tasks, add them for large ones) matches "match effort to task size" thrift thinking.
**How to adopt:** watch — worth a trial run (`two-pack` branch) next time a task needs disciplined multi-agent worktree coordination; note field results here if tried.
