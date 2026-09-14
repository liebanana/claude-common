---
kind: mcp
status: experimental
group: Reusable Claude Code assets
intent: Give an agent live control of Chrome DevTools (traces, network/console inspection, Puppeteer automation) via MCP
tags: [mcp, browser, debugging]
---

# chrome-devtools-mcp

Imported from <https://github.com/ChromeDevTools/chrome-devtools-mcp> (official Google Chrome
DevTools org, MIT). Untested by this repo — verify before relying on it in a real project. See
[`research/ChromeDevTools__chrome-devtools-mcp.md`](../research/ChromeDevTools__chrome-devtools-mcp.md)
for the triage note.

Requires Node.js LTS, current stable Chrome, and npm. Add to a project's `.mcp.json`:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"]
    }
  }
}
```

For basic browser tasks only (lighter footprint), use slim + headless mode instead:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--slim", "--headless"]
    }
  }
}
```

Notes from the upstream README:
- Exposes full browser/DevTools content to the MCP client — don't use on sessions handling sensitive data.
- Sends usage statistics to Google by default; opt out with `--no-usage-statistics` or by setting `CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS` / `CI`.
- Officially supports Google Chrome / Chrome for Testing only.
