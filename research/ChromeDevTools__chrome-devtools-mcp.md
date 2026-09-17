# ChromeDevTools/chrome-devtools-mcp  ·  ⭐51916  ·  adopt  ·  stable
https://github.com/ChromeDevTools/chrome-devtools-mcp · pushed 2026-09-14 · triaged 2026-09-14 · seen on github, github-trending

**What it is:** Google's official MCP server exposing live Chrome control to coding agents — performance trace recording/insights, network/console inspection with source-mapped stack traces, and Puppeteer-driven automation. Officially supports Chrome / Chrome for Testing.
**Reusable for us:** A one-line MCP config any repo can drop in for browser debugging/automation tasks. Stubbed a template at [`mcp/chrome-devtools-mcp.md`](../mcp/chrome-devtools-mcp.md).
**Token / effectiveness angle:** Not a token-savings tool itself, but a credible, officially-maintained alternative to ad-hoc browser scripting — reduces agent trial-and-error when debugging frontend issues. Also directly relevant: this session's local `playwright` MCP failed to connect (`npx` not found), so this is a concrete fallback/alternative worth knowing about.
**How to adopt:** Copy the config from `mcp/chrome-devtools-mcp.md` into a project's `.mcp.json`; `--slim --headless` for lightweight basic-browser-task use.
