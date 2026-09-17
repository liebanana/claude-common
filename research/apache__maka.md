# apache/maka  ·  ⭐4294  ·  watch  ·  experimental
https://github.com/apache/maka · pushed 2026-08-31 · triaged 2026-08-31 · seen on github-trending

**What it is:** A local-first agent workspace (Electron desktop app, TUI/CLI, and eval harness sharing one Runtime Host) that records every model message, tool call, tool result, and permission decision as an append-only log — the UI and next prompt are just views over that record, not the only copy.
**Reusable for us:** The core idea — trimming old tool output from the next prompt without deleting the saved record — is exactly our own token-hygiene practice (`state/` logs, targeted reads) but formalized as a first-class architecture. No direct code to lift; it's a design pattern to keep in mind.
**Token / effectiveness angle:** Directly token-thrift relevant: 'shorter context is not deleted history' is the same principle behind not re-reading files we just wrote.
**How to adopt:** watch — still under active development per its own README (data formats/CLI may change); re-check once it stabilizes.
