# Agent operating directive (portable)

This directive applies to **every** agent (main or subagent) working in this repository.
It ships **committed in each repo** as `AGENT-DIRECTIVE.md` so it travels with the code to any host.
Each repo's own `CLAUDE.md` imports it via `@AGENT-DIRECTIVE.md` and adds repo-specific rules on top — repo rules **never override** this.
Master copy: `claude-common/AGENT-DIRECTIVE.md`, released as tags (`claude-common/scripts/release.sh`) and delivered to every repo as a PR by `claude-common/scripts/sync-consumers.sh` (with `AUTO_PUSH=1`). Edit it there, never in a consumer.

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
- **Emit status.** When you hit or clear a human-only blocker, and at session end, run `/oracle-status` (writes `.oracle/status.json`) — the oracle board shows only what agents emit; it never guesses.

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

**Shared toolkit — check before building**
- Before building tooling/scripts/agents from scratch, check **`~/repos/claude-common`** (read `CATALOG.md`, or query `index.json` with `jq`): reusable scripts, slash commands, research notes, vetted plugins. Use what fits; if an asset needs setup you shouldn't do alone (install/auth), recommend it to the user instead of reinventing. Contribute general reusable learnings back via `/contribute-to-common`. (If `claude-common` doesn't exist on this host, skip.)

**Token hygiene**
- **Don't re-read** files you just wrote/edited — the harness already tracks them.
- **Targeted reads** — read the lines/section you need, not whole large files.
- **Don't dump** huge command output into context; filter (`head`, `grep`, `--quiet`, count lines) or, when online, hand the noisy command to the user (§2).
- Don't re-derive facts already established earlier in the conversation. Act once you have enough to act; skip narrating options you won't pursue.

---

## 5. Workflow discipline — ANALYZE → BRAINSTORM → SPEC → PLAN → IMPLEMENT, always (Luis, 2026-08-14)

Every piece of work follows these five phases **in order, every time** — no jumping straight
to code, no matter how obvious the fix looks:

1. **ANALYZE** — establish the facts first: read the actual data/code/logs, reproduce, quantify.
   Root cause before remedy; never argue from memory of the system when the system itself is
   readable.
2. **BRAINSTORM** — generate the real option space (including "do nothing") before committing to
   a direction; name the trade-offs. Use the brainstorming skill when available.
3. **SPEC** — write down WHAT will be built/changed and what "done" means: behavior, interfaces,
   constraints, non-goals, how it will be verified.
4. **PLAN** — order the work: steps, touch points, tests, deploy/rollback, consumer surfaces.
   Use the planning skill when available.
5. **IMPLEMENT** — only now write code, test-first, then verify against the spec.

**Phase depth scales with the change** — a one-line fix may compress phases 1–4 into a few
sentences — but every phase is *touched explicitly and visibly* (state your analysis, options,
spec, and plan before the diff, however brief). Skipping is not a form of scaling.

**Org gate composes with this, it doesn't replace it:** wherever a repo requires SME review
(e.g. the tradingdesk rule-9 gate on money-affecting logic), the org round happens between
BRAINSTORM/SPEC and PLAN — SMEs rule on the options and the spec, then only the agreed spec
gets planned and implemented. For work without a mandated gate, still run the relevant SME
lenses on non-trivial decisions (autonomy: decide and proceed, but decide *through the org*).

---

## 6. Ultracode & workflow provisioning (Luis, 2026-09-22)

Ultracode (the `ultracode` keyword, `/effort ultracode`, or `ultracode: true` in settings; a system
reminder confirms it) is a standing opt-in to author and run a **Workflow** for every substantive
task, typically with adversarial verification stages instead of a single pass. It raises the
**verification and orchestration bar** — it does **not** lift §4. The Workflow reference's "token
cost is not a constraint" is overridden by this directive: thrift applies per agent, inside every
workflow.

**Set `model:` explicitly, by role, on every workflow `agent()` call and every Agent spawn.**
Omitting it to "inherit the session model" is a bug in both directions: on an Opus/Fable session it
over-provisions mechanical stages; on a Haiku/Sonnet session it under-provisions the stages that need
judgment. Never rely on inheritance.

**Role → tier (the floor; a repo's MODEL-POLICY may raise a named class, never lower one):**
- Implementer whose task already contains the complete code → **haiku** if single-file/mechanical,
  **sonnet** otherwise (multi-file, integration).
- Implementer working from prose (no complete code in the task) → **sonnet**.
- Per-task reviewer, scoped re-review → **sonnet**.
- Fixer → **sonnet**; **opus** only on the last fix round of a stuck task.
- Design synthesis / judging, final whole-branch review, end-of-build audit, genuinely hard
  debugging → **opus / frontier**.
- Read-only sweeps → **Explore** (or **haiku** when Explore doesn't fit).
- Red-team / chaos attackers → **sonnet**.
- Anything not matching a row → **sonnet**; escalate only if it struggles. Never default an
  unmatched stage to opus.

Set `effort:` the same way: **low** for mechanical stages, **high** only for the hardest verify/judge
stages — never every stage on high just because ultracode is on.

**Repo overrides are additive only.** A repo's MODEL-POLICY may mark named classes mandatory-frontier
(security/RLS, new architecture, money-affecting logic, user-facing correctness claims) and force
those stages to opus. It may never drop a stage below this floor or skip a verification stage.

**Loop caps.** Adversarial ping-pong (implementer ↔ reviewer/fixer) is capped at **3 NOT-READY
rounds per item**. Then freeze, disclose what is unresolved, move on. Round count, not tier, is where
spend goes; never "fix" a stuck loop by upgrading tiers.

**Harness safety net, not a substitute.** The synced settings baseline sets
`CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (in `.claude/settings.json` → `env`), which is the fallback for
both Agent-tool spawns and workflow `agent()` calls that omit `model:` (resolution: call param →
agent frontmatter → this env var → session model). It stops a forgotten `model:` from inheriting
Opus; it cannot pick opus for a judge stage or haiku for a transcription stage. Explicit `model:` is
still required. Never set the `_FORCE` variant — it overrides deliberate choices.

**Report the tier mix.** At the end of a workflow run, log how many agents ran at each tier
(e.g. "6 haiku, 9 sonnet, 2 opus") so over- or under-provisioning is visible, not assumed away.

**When ultracode is off:** §4 applies unchanged; do not author or run a Workflow unless the user
opted in for that task.
