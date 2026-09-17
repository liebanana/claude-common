---
kind: doc
status: ready
group: Debugging techniques
intent: Prove/disprove phantom-scroll & layout-void bugs in Next.js/Tailwind apps without auth, dev servers, or browser installs
tags: [debugging, css, playwright, nextjs, layout]
---

# Layout-measure repro — phantom scroll voids without auth or a dev server

**When to use:** a user reports "I can scroll way past the content" / a dead void below the
page / a fixed nav "floating" mid-screen, the route needs auth you don't have, and static
CSS reading hasn't found a culprit. This gets you a *measured* verdict in minutes.

## The pattern

1. **Render the REAL component server-side.** Most mature Next.js repos have render-harness
   scripts (`renderToStaticMarkup` of production components with mock props). Reuse that
   machinery — including any `server-only`/`client-only` shim the repo's test runner injects
   (look for a `--require <preload>.cjs` in the runner; run your script with the same
   `NODE_OPTIONS`). Run the script from inside the app dir so module resolution works.

2. **Pair it with the REAL compiled CSS.** The live build already has it:
   `.next/static/chunks/*.css` (Turbopack) or `.next/static/css/*.css` (webpack). Reading it
   is harmless. Inline it into a standalone HTML file.

3. **Replicate the layout shell faithfully.** Copy the exact wrapper stack around `<main>`
   from the app's layout (the flex/min-h/padding classes are usually where scroll bugs live)
   plus stubs for sticky header / fixed nav at their real heights.

4. **Measure in playwright-core with zero installs.** `playwright-core` is very often already
   in `node_modules` (transitive). The cached browser may be there too:
   `~/.cache/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-linux64/...`.
   Launch it directly:

   ```js
   const { chromium } = require('playwright-core')
   const b = await chromium.launch({ executablePath: CACHED_HEADLESS_SHELL })
   const p = await b.newPage({ viewport: { width: 390, height: 844 } })  // phone
   await p.goto('file:///.../repro.html')
   const r = await p.evaluate(() => {
     let max = 0
     document.querySelectorAll('*').forEach(el => {
       const rc = el.getBoundingClientRect(); max = Math.max(max, rc.bottom + scrollY)
     })
     return { scrollH: document.documentElement.scrollHeight, maxContentBottom: Math.round(max) }
   })
   ```

   If host-dep validation complains: `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1`
   (chromium-headless-shell usually runs fine anyway; WebKit genuinely needs
   `sudo playwright install-deps` — hand that to the human).

## Reading the verdict

- **`scrollH > maxContentBottom`** → structural bug. Walk all elements for the ones whose
  `bottom` reaches `scrollH` — that's your culprit chain (usually an absolutely-positioned
  element below content, a stray `100dvh` box, or padding var gone wrong).
- **`scrollH === maxContentBottom` exactly** → the CSS/DOM is sound in a standards engine.
  The report is engine-specific (iOS Safari) or transient. Two known non-bugs to check
  before burning more time:
  - **Stale scroll range after content shrinks:** if a recent deploy made the page ~N px
    shorter (font-size/row-height changes at list scale), iOS Safari can keep the OLD
    scroll range until the tab fully reloads — the void is the ghost of the previous
    layout and self-resolves. Correlate deploy time vs report time.
  - Safe-area/`env()` accounting on notched devices (needs the app's chrome-sizing vars to
    fold in `safe-area-inset-*`; if they already do, it's not this).

## Provenance

Extracted from a language-app session (2026-07): an iOS over-scroll report with the nav
"floating mid-screen". Chromium measurement showed page height == content height to the
pixel across a 40-item list; the deploy 30 minutes earlier had shrunk ~100 list titles from
24px to 16px (~1000px shorter page) — stale-scroll-range artifact, self-resolved, zero code
changed. The measured verdict prevented a speculative "fix" of healthy CSS.
