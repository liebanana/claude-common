# max-sixty/worktrunk  ·  ⭐7621  ·  watch  ·  stable
https://github.com/max-sixty/worktrunk · pushed 2026-09-14 · triaged 2026-09-14 · seen on github-trending

**What it is:** A Rust CLI (`wt`) that makes git worktrees as easy as branches — `wt switch -c -x claude feat` replaces the three-command `git worktree add && cd && claude` dance — plus hooks (create/pre-merge/post-merge) and LLM-generated commit messages, built specifically for running 5-10+ AI agents in parallel.
**Reusable for us:** Directly complements [[superpowers:using-git-worktrees]] and this harness's built-in `EnterWorktree`/`ExitWorktree` tools — worth knowing about as an external CLI option for repos/users who want worktree ergonomics outside the harness itself (e.g. manual multi-agent tmux setups).
**Token / effectiveness angle:** Not a token-savings tool directly, but reduces the friction (and thus the shell-command overhead) of the worktree pattern this repo already recommends for parallel agent work.
**How to adopt:** watch — recommend trialing (`cargo install worktrunk` or see worktrunk.dev) for anyone running many parallel agent sessions by hand; not something to stub into this repo since it's an external binary, not embeddable config.
