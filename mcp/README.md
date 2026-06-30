# mcp/ — MCP & integration config templates

Reusable `.mcp.json` fragments and integration configs (Slack, BigQuery, Sentry, etc.)
that repos can copy and fill in.

**Public repo — never commit real tokens, endpoints, or org-specific secrets.** Use
placeholders (`${SLACK_BOT_TOKEN}`, `<your-project-id>`) and document which env vars to
set. List each template in [`../CATALOG.md`](../CATALOG.md).
