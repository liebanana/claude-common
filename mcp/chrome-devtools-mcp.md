---
description: MCP server giving coding agents live Chrome control (screenshots, console, network, perf traces) via Puppeteer + Chrome DevTools
kind: mcp
status: recommended
group: Reusable Claude Code assets
intent: Let an agent drive and inspect a real Chrome browser for frontend verification and debugging
tags: [mcp, browser, frontend, debugging]
---

Imported from https://github.com/ChromeDevTools/chrome-devtools-mcp, untested here.
Official Google project (46k+ stars). Useful anywhere the `run`/`verify` skills need to
drive a real browser (screenshots, console errors, network requests, perf traces) instead
of guessing at frontend behavior.

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--no-usage-statistics"]
    }
  }
}
```

Requires Node.js LTS + a current Chrome. Exposes full browser contents to the MCP
client — avoid on sessions touching sensitive/private data. See
[research/ChromeDevTools__chrome-devtools-mcp.md](../research/ChromeDevTools__chrome-devtools-mcp.md).
