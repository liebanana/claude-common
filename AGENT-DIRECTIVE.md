# Agent operating directive (portable)

This directive applies to **every** agent (main or subagent) working in this repository.
It ships **committed in each repo** as `AGENT-DIRECTIVE.md` so it travels with the code to any host.
Each repo's own `CLAUDE.md` imports it via `@AGENT-DIRECTIVE.md` and adds repo-specific rules on top — repo rules **never override** this.
Master copy: `~/repos/AGENT-DIRECTIVE.md`; propagate edits with `~/repos/sync-directive.sh`.

Goal: **don't burn tokens on work the user can do faster himself, but never stall autonomous runs waiting on a human who isn't there.**

---

## 1. Decide your mode FIRST, before planning a task

Check, in order:

1. **Scheduled / non-interactive run?** If invoked by cron, `claude -p`, `/loop`, a scheduled routine, or any headless context → **AUTONOMOUS, always.** Ignore the flag file. No human is there to hand work to; handing off = stalling. Follow §3.
2. **Otherwise read `~/.claude/.online`:**
   - File **exists AND mtime < 4h old** → **ONLINE** (the user is at the keyboard). Follow §2.
   - File **absent, or mtime ≥ 4h old (stale)** → **AUTONOMOUS.** Follow §3.

The flag lives under `~/.claude/` (not in any repo) so it works on **any host** and one toggle covers every repo there. The 4-hour staleness guard means a forgotten flag self-expires — when uncertain, you default to autonomous and the task still completes.

The user toggles it: `touch ~/.claude/.online` on sitting down, `rm ~/.claude/.online` on leaving. **Don't create, delete, or `touch` this file yourself.**

---

## 2. ONLINE — hand human-runnable work to the user (save tokens)

When online, **hand off** these rather than spending tokens doing them yourself:

- **Interactive auth / logins / 2FA** — `gcloud auth login`, IBKR/broker login, browser sessions, anything prompting for a password or device.
- **Credentialed / secret / physical-device actions** you can't perform headless.
- **GUI / browser / desktop actions** with no clean CLI path (clicking, screenshots of live UI, app windows).
- **Long-running watches / live monitors** — tailing logs, `pm2 monit`, live dashboards. Ask the user to watch and report.
- **High-output commands** where a human eyeball + one-line verdict is far cheaper than you ingesting thousands of lines (full test suites, verbose builds, large `git log`/`diff` dumps).
- Anything genuinely **faster for the user to run and paste back** than for you to drive.

**Do NOT hand off** (just do it — round-tripping a human costs more than running it):
- Cheap, fast, already-permitted commands (status checks, single-file reads, small greps, targeted edits).
- Anything needing several quick iterations — keep that in-loop rather than ping-ponging through the user.

**Hand-off format** — make it zero-friction:
- **Batch** everything you need into ONE block, not a drip of single commands.
- Tell the user to run via the session prefix `! <command>` so output lands directly in the conversation.
- State **exactly what to paste back** — "just pass/fail", "last 20 lines", "the final URL" — not the whole dump.
- Then **wait** for the result before continuing the affected step.

---

## 3. AUTONOMOUS — do it yourself, nonstop

- Run the human-runnable tasks **yourself**. Don't hand off; there's no one to receive it.
- Keep working through the task list. Decide routine/basic things and proceed — don't stop for confirmation on reversible, low-stakes choices.
- **Only stop for true hard blockers** that are genuinely human-only and can't be deferred: interactive logins/2FA you can't satisfy, irreversible broker/KYC/tax/funding submissions, or anything requiring the user's physical action or a decision only they can make.
- When you hit such a blocker: **queue it clearly** (note what's blocked + exactly what you need from the user) and **keep going on everything not blocked by it.** Never silently skip it; never fake-complete it.
- **Honor this repo's review gates.** If this repo's `CLAUDE.md` defines sign-off requirements (e.g. SME review on risk/sizing/stop/gate/strategy changes in the trading desk), autonomy does **not** bypass them.

---

## 4. Token / model / subagent thrift — ALWAYS, both modes

**Model selection**
- Spin up the **lowest-cost model that can do the job.** Never default to Opus.
- Push routine/mechanical/bulk work to **Sonnet or Haiku**; reserve Opus for genuinely hard reasoning.

**Subagents**
- Each spawn starts **cold** and re-derives context — it's the expensive path. **Don't spawn unless the task truly needs fan-out** (broad multi-location search) or the user asks.
- A task with "multiple parts" or "be thorough" is **not** a reason to spawn — handle it inline with your own tools.
- For broad read-only searches, use **Explore** (cheap, returns conclusions) rather than spawning a full general-purpose agent.
- Continue an existing agent via its ID instead of starting a fresh one when context carries over.

**Token hygiene**
- **Don't re-read** files you just wrote/edited — the harness already tracks them.
- **Targeted reads** — read the lines/section you need, not whole large files.
- **Don't dump** huge command output into context; filter (`head`, `grep`, `--quiet`, count lines) or, when online, hand the noisy command to the user (§2).
- Don't re-derive facts already established earlier in the conversation. Act once you have enough to act; skip narrating options you won't pursue.
