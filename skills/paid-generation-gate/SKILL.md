---
name: paid-generation-gate
description: Use before any paid generation API call (images, music, voice, video) — write the requests to a pending file, have a stronger model review the prompts, run free dry-run cost checks, log every spend in a ledger and stop at a budget cap.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Stop wasted spend on paid generative APIs — prompts reviewed by a stronger model before the call, free cost checks, a cost ledger, a budget cap with stop rules, and the proxy-injected API key pattern for cloud sessions
tags: [skill, cost, generation, budget, review, api-keys]
---

# Paid generation gate

Generative calls (image, music, voice) cost real money and bad prompts are not refundable. Gate every paid call.

## Flow (never skip a step)

1. **Write requests, don't send them.** Append each planned call to a pending file (`gen/prompts-pending.md`): purpose, exact prompt, model/params, count, expected output use.
2. **Dry-run the cost for free.** Most providers have a cost-check/estimate endpoint or a dry-run flag — use it and record the figure next to each request. No dry-run available → estimate from the price sheet and mark it "estimated".
3. **Stronger-model review.** Spawn a reviewer on a stronger model than the writer (explicit `model:`; see the directive's role tiers) to critique the prompts against the brief: ambiguity, style drift, wasted variants, cheaper settings, batching. It returns edits, not prose.
4. **Generate only the approved requests**, smallest batch first (1-2 samples), look at the result, then scale.
5. **Ledger every call** in `gen/costs.md`: date, request id, tool, params, cost, outcome (kept/rejected), running total.
6. **Budget cap + stop rules.** Set a cap in the ledger header before the first call. Stop and ask when: running total reaches ~80% of the cap; two consecutive batches are mostly rejected (the prompt is wrong — back to step 3); a cost-check disagrees with the billed cost.

Human approval of the outputs (pick/reject) belongs in the loop too — see `decisions-page` for a thumbs up/down page.

## API keys in cloud sessions (proxy-injected header)

Cloud sessions go through a proxy that can inject the real credential for a host. Do **not** paste or ask for the secret. Request the credential for the host (the environment's secret form), then send the request with a **placeholder** value in the header the API expects (e.g. `Authorization: Bearer placeholder` or `X-Api-Key: placeholder`); the proxy replaces it with the real key. If it still returns 401/403 right after saving, wait about a minute and retry once. Never commit keys; the ledger records costs, not credentials.
