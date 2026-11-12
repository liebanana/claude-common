---
kind: doc
status: ready
group: Design & UI fidelity
intent: Prove an implemented UI actually matches its design.md with Playwright — token/anatomy/a11y assertions as the hard gate, the Stitch screenshot diff as advisory — instead of claiming fidelity by eye
tags: [playwright, design-system, stitch, ui, verification, a11y]
---

# UI fidelity with Playwright — the measured half of §7

Directive §7 says a user-visible surface is designed before it is coded and **measured**
after. This is the measuring half: how to turn a `design.md` into assertions that fail the
build, and how to use the Stitch mockup as a review aid without letting pixels fail it.

**The two tiers, and why they differ**

| Tier | What it checks | On mismatch |
|---|---|---|
| **Hard gate** | computed tokens actually rendered, component anatomy + states, hierarchy, breakpoints, a11y | **fails the build** |
| **Advisory** | pixel diff vs the Stitch screenshot | reported in the PR, never red |

Fonts fall back, antialiasing differs per machine, and Stitch fills screens with invented
copy of a different length than real data — so pixel equality is a false goal. The tokens
are not: they are literal values in `design.md`, and the browser will tell you exactly which
ones the page used.

## The hard gate

Assert **membership in the token set**, not per-element equality. "Every color this surface
paints is one of the design-system colors" catches an off-palette `#3b82f6` that a
screenshot diff would wave through, and it doesn't break when a button legitimately moves.

```js
// tests/fidelity/tokens.spec.ts — runs in the repo's own @playwright/test harness
import { test, expect } from "@playwright/test"
import { readFileSync } from "node:fs"
import { parse } from "yaml"

const design = parse(readFileSync("design.md", "utf8").split("---")[1])
const hex = (s) => s.toLowerCase().replace(/\s/g, "")
const PALETTE = new Set(Object.values(design.colors).flatMap(v =>
  typeof v === "string" ? [hex(v)] : Object.values(v).map(hex)))
const SPACING = new Set(Object.values(design.spacing).map(Number))   // e.g. 4,8,12,16,24,32
const RADII   = new Set(Object.values(design.rounded).map(Number))
const FONTS   = new Set(Object.values(design.typography.families ?? {}))

test("every painted value is a design token", async ({ page }) => {
  await page.goto("/the-surface")
  const used = await page.evaluate(() => {
    const out = { colors: new Set(), space: new Set(), radius: new Set(), fonts: new Set() }
    for (const el of document.querySelectorAll("body *")) {
      const cs = getComputedStyle(el)
      const r = el.getBoundingClientRect()
      if (r.width === 0 || r.height === 0) continue              // invisible: not painted
      out.colors.add(cs.color)
      if (cs.backgroundColor !== "rgba(0, 0, 0, 0)") out.colors.add(cs.backgroundColor)
      if (cs.borderTopWidth !== "0px") out.colors.add(cs.borderTopColor)
      for (const p of ["paddingTop","paddingLeft","marginTop","gap"])
        if (cs[p] && cs[p] !== "0px" && cs[p] !== "normal") out.space.add(cs[p])
      if (cs.borderTopLeftRadius !== "0px") out.radius.add(cs.borderTopLeftRadius)
      out.fonts.add(cs.fontFamily.split(",")[0].replace(/['"]/g, ""))
    }
    return Object.fromEntries(Object.entries(out).map(([k, v]) => [k, [...v]]))
  })
  // rgb() -> hex before comparing; report the offenders, never just a count
  expect(offPalette(used.colors, PALETTE)).toEqual([])
  expect(used.space.map(px).filter(v => !SPACING.has(v))).toEqual([])
  expect(used.radius.map(px).filter(v => !RADII.has(v))).toEqual([])
  expect(used.fonts.filter(f => !FONTS.has(f))).toEqual([])
})
```

Then, in the same file or beside it:

- **Type scale** — every rendered `fontSize`/`lineHeight`/`fontWeight` triple is one of the
  `design.md` steps. This is where "looks about right" dies: a 15px heading is invisible to
  the eye and obvious to the assertion.
- **Component anatomy and states** — for each component the doc defines, assert the parts
  exist and the *states* render per spec: `page.hover()`, `page.keyboard.press("Tab")` +
  `:focus-visible`, `[disabled]`, loading, empty, error. A design system is mostly its
  states; mockups usually show one.
- **Hierarchy** — the primary action is the only element using the CTA token on that screen;
  heading levels descend without skipping.
- **Breakpoints** — re-run the whole set at each width `design.md` names
  (`test.use({ viewport })` in a loop), not just the one the mockup was generated at.
- **Accessibility** — roles and accessible names (`getByRole`), focus order matches reading
  order, contrast computed from the tokens (WCAG formula, or `axe-core` if the repo already
  has it). An a11y fix that deviates from the mockup wins; note it in the PR (§7.4).

**Freeze the nondeterminism** or the gate flakes: fixed clock/seed for dates and random
content, `prefers-reduced-motion`-forced CSS to kill animation, and the real fixture data
the surface ships with — never Stitch's invented copy.

## The advisory diff

```bash
curl -sL "<screenshot.downloadUrl from the Stitch response>" -o baseline/<screen-id>.png
```

Screenshot the implementation at the same device profile Stitch generated for
(`MOBILE` ≈ 390×844, `DESKTOP` ≈ 1440×1024), diff with whatever the repo already has
(`pixelmatch`, `odiff`, `expect(...).toHaveScreenshot` with its own baseline), and publish
the number plus the side-by-side as a CI artifact. Keep it in a **separate job that cannot
fail the build** (`continue-on-error: true`). Baselines live in the repo next to the tests,
named by Stitch screen id so a later session can trace a mockup back to its generation.

When a diff shows real drift, the fix is a **new hard assertion** describing what was wrong
(a token, a gap, a weight) — not a tightened pixel threshold. Thresholds encode "we looked
once"; assertions encode what the design actually says.

## Harnesses

- **The gate lives in the repo**, in its own `@playwright/test` suite, versioned and run by
  the normal test command. It is a contract, so it must survive this session.
- **`mcp__playwright__*` is for exploration** — poking a live page, reading console errors,
  checking a hypothesis before writing the assertion. Don't let a gate exist only as MCP
  calls in a transcript. (Config note: point the MCP server at a *pinned, preinstalled*
  `mcp-server-playwright` binary; `npx @playwright/mcp@latest` cold-starts slowly enough to
  blow the 30 s MCP connect timeout on a loaded host.)
- **No dev server, no install, no auth?** Render the real components to static HTML with the
  repo's own render harness, inline the compiled CSS, and drive the cached browser directly
  with `playwright-core` — full recipe in `docs/layout-measure-repro.md`.

## Gotchas

- **Font substitution poisons the diff, not the gate.** Stitch picks from ~65 Google Fonts;
  if the app ships a different family the pixels differ everywhere while the tokens stay
  correct. Load the same family locally, or state the substitution and read the diff loosely.
- **Scrollbars and device-pixel-ratio** shift layout between machines — pin `deviceScaleFactor`
  and hide scrollbars in the screenshot CSS, or the advisory number is noise.
- **Dark mode is a separate design system in Stitch** (two assets, §7.2) — so it is a separate
  baseline and a separate token run (`colorScheme: "dark"`), never an afterthought.
- **An element with zero box is not painted.** Walking every node without filtering
  `getBoundingClientRect()` pulls in hidden templates and off-palette values nobody sees.
