# virgiliojr94/book-to-skill  ·  ⭐19833  ·  adopt  ·  trending
https://github.com/virgiliojr94/book-to-skill · pushed 2026-08-10 · triaged 2026-08-10 · seen on github-trending

**What it is:** A `/book-to-skill` command that turns a technical book/doc/PDF (or folder of sources) into a structured Agent Skill (`SKILL.md` + per-chapter files) so an agent loads only the relevant chapter on demand instead of the whole document. Works with any Agent-Skills-standard host: Claude Code, GitHub Copilot CLI, Amp.
**Reusable for us:** Directly relevant — the reusable bit is the *pattern*: distill a large reference doc into a skill with per-section files instead of dumping the whole thing into context, then load lazily via slash command. Worth trying against our own `docs/token-thrift.md`-style long references or third-party tool docs we consult often.
**Token / effectiveness angle:** README claims 24x-51x fewer tokens than dumping the book into context to answer one question — same "distill once, load lazily" strategy `docs/token-thrift.md` already recommends, just packaged as a generator.
**How to adopt:** Install per their docs (`docs/install.md`) and try it on one real reference doc we consult often; if it holds up, note field results here and flip status.
