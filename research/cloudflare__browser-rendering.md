# cloudflare/browser-rendering  ·  (hosted product)  ·  watch
https://www.cloudflare.com/products/browser-rendering/ · triaged 2026-06-30

**What it is:** A Cloudflare service that spins up a headless browser in the cloud on demand (Playwright/Puppeteer) for screenshots and data extraction — for interacting with sites that have no API. Not open-source; no MCP integration mentioned.
**Reusable for us:** A hosted alternative to self-hosting a browser agent (cf. `auto-browser`) — no infra to run. Reference for the "give an agent a browser" need; would need a thin MCP/tool wrapper to be agent-native.
**Token / effectiveness angle:** Indirect — offloads browser work to a managed service; saves setup/maintenance, not tokens directly.
**How to adopt:** Watch. If a project needs scalable headless browsing, evaluate this (managed) vs `auto-browser` (self-hosted, MCP-native). Doc the trade-off if it comes up.
