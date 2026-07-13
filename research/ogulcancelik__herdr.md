# ogulcancelik/herdr  ·  ⭐16020  ·  watch  ·  trending
https://github.com/ogulcancelik/herdr · pushed 2026-07-13 · triaged 2026-07-13 · seen on github-trending

**What it is:** A terminal agent-multiplexer (tmux-like) purpose-built for running multiple coding-agent sessions: real terminal views per agent (blocked/working/done at a glance), detach/reattach (including over ssh, survives restarts), and a socket API so agents can spawn panes and wait on each other. Single Rust binary, no Electron.
**Reusable for us:** Directly relevant to running/monitoring multiple Claude Code sessions or subagents in parallel outside this harness's own session model — the socket API in particular (agents spawning/coordinating other agent panes) parallels our subagent-dispatch patterns.
**Token / effectiveness angle:** n/a directly (it's a terminal/process manager, not a token optimizer) — but reduces human overhead of babysitting multiple concurrent agent runs.
**How to adopt:** Watch. Worth trialing (`curl -fsSL https://herdr.dev/install.sh | sh`) next time multiple long-running Claude Code sessions need to be supervised from one terminal.
