---
kind: doc
status: ready
group: Design & UI fidelity
intent: Gate UI changes on how they feel, not just how they look — time real taps on a production build with injected server delay (≤100 ms feedback, ≤1 s next screen), ratchet taps-to-goal, start serving checks at the entry point, and keep shared chrome identical through primitives
tags: [ui, ux, playwright, performance, verification, gates]
---

# The interaction gate: screenshots can't see slowness

Screenshots, contrast rules and the structural fidelity gate (`docs/ui-fidelity-playwright.md`) all
passed on screens users called unacceptable: a choice took a second to show it was selected, a start
button froze the page for half a second, and the main action sat several taps deep. Users judge an app
by speed and directness on their own phone. Static checks measure neither.

## What to measure (every changed control on the touched screen)

| Metric | Budget |
|---|---|
| tap → visible pressed/selected/busy state | ≤ 100 ms |
| tap → next screen settled, **with ≥ 600 ms injected server delay** | ≤ 1 s, pending feedback shown at once |
| taps from the app's home to the screen's main action | recorded; a change may never raise it |

- **Measure on a production build** (`build && start`), one at a time on a shared host — dev servers
  lie about timing.
- **Inject server latency.** Against a local database every round-trip is ~1 ms, so a gate without
  injected delay passes code that makes 4–5 sequential calls (seconds in production).
- Code consequences: in-app navigation uses the framework's client link (a plain `<a>` reloads the
  page), with a pending state; prefetch an action's start while its setup screen is visible; keep
  sequential backend round-trips per action ≤ 3; serve cached data stale while revalidating.

```ts
// Playwright (@playwright/test) sketch — adapt selectors and the backend URL pattern.
test('start responds instantly under server delay', async ({ page }) => {
  await page.route('**/api/**', async r => { await new Promise(f => setTimeout(f, 600)); await r.continue(); });
  await page.goto('/practice/setup');
  const start = page.getByRole('button', { name: 'Start' });
  const t0 = Date.now();
  await start.click();
  await expect(start).toHaveAttribute('aria-busy', 'true', { timeout: 100 });   // feedback ≤ 100 ms
  await expect(page.getByTestId('session-screen')).toBeVisible({ timeout: 1000 });
  console.log('tap→screen ms', Date.now() - t0);                                // record it in the packet
});
```

## Serving checks start at the entry point
- After a release, the check begins where the user **enters** (the home card, the picker, the menu
  item), then the feature itself. A change that hides, dedupes or re-sources rows can zero a total that a
  readiness predicate depends on and make the whole entry card vanish while the feature works.
- **A change to what a total counts lists every consumer of that total** (ready/done/next/progress
  predicates) and tests each with the new shape.
- **A per-user preference that hides a feature names every surface that offers the feature**, and each
  reads it through the same function.

## Consistency through primitives, not discipline
- Shared chrome (exit, progress, counters, bottom bar) comes from one set of primitives used by every
  session/screen type, with a gate that fails when a screen renders its own. Put a new screen's
  screenshot side by side with an existing one in the review packet; a difference is a must-fix.
- Capabilities per variant (language, plan, platform) come from **one canonical list**, never from a
  scattered `if (variant === 'X')` per feature — variants drift apart for no reason.
- **Compose first:** a screen built only from already-approved patterns and primitives can be reviewed
  as a coded prototype from the real tokens; reserve a full mockup round for a new archetype, a new
  primitive, or a visual-direction change.

## Traps
- iOS plays Web Audio only if the audio context is created/resumed **inside** the tap handler; a sound
  fired after an `await` is silent.
- Never ship an interactive UI change on static green (typecheck/build/lint/code read): load the real
  route and confirm it hydrates and its controls respond.
- "ASAP" is not a reason to skip this gate.
