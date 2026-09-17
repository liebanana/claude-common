# ChromeDevTools/chrome-devtools-mcp  ·  ⭐46032  ·  adopt  ·  stable
https://github.com/ChromeDevTools/chrome-devtools-mcp · pushed 2026-07-06 · triaged 2026-07-06 · seen on github,github-trending · 1375↑

**What it is:** Google's official MCP server giving a coding agent live control of a real Chrome instance — screenshots, console/network inspection, and performance-trace analysis — built on Puppeteer.
**Reusable for us:** Directly useful for our `run`/`verify` skills, which say to actually drive the app in a browser before claiming a frontend change works. This MCP server is the concrete way to do that from inside a session instead of hand-waving.
**Token / effectiveness angle:** Saves the back-and-forth of asking the user to screenshot/paste console output — the agent inspects the live page itself.
**How to adopt:** Stubbed as [`mcp/chrome-devtools-mcp.md`](../mcp/chrome-devtools-mcp.md) with the `.mcp.json` fragment. Untested in this repo — try it on the next frontend task and record field notes.
