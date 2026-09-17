# ogulcancelik/herdr  ·  ⭐12622  ·  adopt  ·  trending
https://github.com/ogulcancelik/herdr · pushed 2026-07-06 · triaged 2026-07-06 · seen on github-trending · 3937↑

**What it is:** A single ~10MB Rust binary — "tmux, rebuilt for agents" — that runs each coding agent in its own real terminal (not a GUI imitation), tracks per-agent state (blocked/working/done/idle) at a glance, supports panes/tabs/workspaces, and survives detach/reattach (including over SSH from a phone). No GUI, no Electron, no account, no telemetry.
**Reusable for us:** Directly relevant to running multiple concurrent agent sessions (matches the multi-agent orchestration angle this repo already touches — subagent dispatch, `/loop`, scheduled agents). It's a standalone tool, not something to vendor into the repo, but worth recommending to the user for managing an agent fleet.
**Token / effectiveness angle:** Not about token cost directly, but about not losing agent output/state across disconnects and seeing which of several running agents needs attention — reduces wasted round-trips checking on idle/stuck agents.
**How to adopt:** Recommend installing (`curl -fsSL https://herdr.dev/install.sh | sh`) and trying it for managing parallel Claude Code sessions. No repo asset to stub — it's an external terminal tool, not a Claude Code plugin/MCP.
