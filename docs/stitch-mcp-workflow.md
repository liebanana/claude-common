---
kind: doc
status: ready
group: Save tokens / work efficiently
intent: Drive Google Stitch programmatically via mcp__stitch__* tools (design system + screen generation) instead of the web UI, with the token-cost trap and error-handling gotchas that aren't obvious from the tool schemas
tags: [stitch, mcp, design-system, tokens]
---

# Stitch MCP workflow

How to drive Google Stitch programmatically via `mcp__stitch__*` tools — stand up a
project + design system(s) and generate screens — without a human ever opening the
Stitch web UI. Extracted from a session that built a full design system and ~30
first-pass screens this way, then reused the same steps verbatim on a second, unrelated
project.

## When to use this

- A redesign or new UI surface needs Stitch-generated mockups for review before any
  code changes.
- You want a reusable design system in Stitch (light + dark) that later screen
  generations can reference, rather than one-off prompts with no shared token base.

## Prerequisite: a real `design.md`

`create_design_system` takes a full `design.md` in the `google-labs-code/design.md`
format: YAML front-matter (`colors`/`typography`/`rounded`/`spacing`/`components`
tokens, `{token.path}` references) followed by a markdown body (Overview / Colors /
Typography / Layout / Elevation & Depth / Shapes / Components / Do's and Don'ts). If
the target project doesn't have one yet, write it collaboratively first: ask before
assuming palette/tone/audience (`AskUserQuestion` with concrete option previews, not
open-ended questions), get explicit section-by-section approval, and only treat it as
final after an explicit sign-off.

## Tool sequence

1. **`create_project(title)`** → returns `projects/{id}`. One project per product/app,
   not per feature.

2. **Two `create_design_system` calls — light and dark are separate assets.** Stitch
   has no single design system with a light+dark variant; each mode is its own object.
   Per call:
   - `designSystem.displayName`: e.g. `"{Product} — Light"` / `"{Product} — Dark"`.
   - `designSystem.theme.colorMode`: `LIGHT` or `DARK`.
   - `designSystem.theme.headlineFont` / `bodyFont`: **enum-constrained** (~65 Google
     Fonts — no arbitrary font stack, no literal `system-ui`). Pick the closest neutral
     match to the doc's intent (e.g. `PUBLIC_SANS` for a "no default UI/UX, not
     Inter/Space Grotesk" brief) and say so explicitly when reporting back — don't
     silently present the substitution as exact.
   - `designSystem.theme.roundness`: `ROUND_FOUR` / `ROUND_EIGHT` / `ROUND_TWELVE` /
     `ROUND_FULL` — map to the design.md's dominant corner radius.
   - `designSystem.theme.customColor`: that mode's brand/CTA hex.
   - `designSystem.theme.colorVariant`: `FIDELITY` keeps Stitch from reinterpreting
     exact hexes into a generated Material tonal palette — use it whenever the
     design.md is precise about token values (most are).
   - `designSystem.theme.designMd`: **the full `design.md` content as a plain string,
     not base64.** A separate `upload_design_md` + `create_design_system_from_design_md`
     two-step path exists that takes base64 — avoid it. Base64 tokenizes almost 1:1 (a
     ~21KB doc costs ~27K tokens as base64), while the same content as real markdown
     tokenizes far more efficiently (~5-7K tokens). Passing `designMd` as text directly
     into `create_design_system` is simpler *and* roughly 4-5x cheaper in context —
     this is the single biggest avoidable cost in the whole workflow.
   - Save both returned `assets/{id}` values — every screen generation call needs one.

3. **`generate_screen_from_text(projectId, prompt, designSystem: "assets/{id}",
   deviceType: MOBILE|DESKTOP)`** — one call per screen, each taking 1-3 minutes.
   - Write **real content** in the prompt: actual copy, numbers, names. Never lorem
     ipsum — the model renders exactly what's described.
   - If the product has a real data-source constraint (no photos, no user avatars,
     etc.), say so explicitly in every relevant prompt or Stitch will invent plausible
     but wrong content (stock-style photography, fake imagery) to fill the gap.
   - `"The operation timed out"`: do **not** retry blind. Per the tool's own
     instructions, poll `get_screen` every ~30s up to 10x instead. In practice a true
     timeout with no returned screen id can't be polled (nothing to poll); if
     `list_screens` / `get_project` also show no trace of it, it's safe to re-issue the
     same call once.
   - `"Request contains an invalid argument."` (not a timeout) is a different,
     immediate failure — just retry as-is once. This resolved on retry with zero prompt
     changes both times it was observed.
   - **Response verbosity is unavoidable**: every generation/edit response echoes the
     *entire* design system object — including the full `design.md` text — back in the
     JSON result. This is API behavior, not something a leaner prompt avoids. Budget
     context accordingly; batching several `generate_screen_from_text` calls into one
     parallel tool-call turn doesn't reduce this per-response cost, but it does avoid a
     fresh round-trip/prompt-cache-miss per screen.

4. **`edit_screens(projectId, selectedScreenIds: [id], prompt)`** to fix an existing
   screen (e.g. a broken layout) instead of regenerating from scratch — cheaper, and
   keeps the same screen id.

5. **Verify before showing the human.** Every generation/edit response includes
   `screenshot.downloadUrl` (an `lh3.googleusercontent.com` link). Download with
   `curl -sL <url> -o file.png`, then look at it yourself (e.g. with a vision-capable
   Read tool) before sending it on — Stitch occasionally produces a broken layout
   (observed once: a dropdown menu rendered stuck in the top-left corner over a blank
   gray void instead of anchored under its trigger). Catch and fix these before the
   human ever sees them.

## Known gotchas

- `list_screens` and `get_project` don't reliably enumerate every previously-generated
  screen on this API surface — track screen ids yourself from each generation response
  as you go.
- Font / roundness / colorVariant are enums, not free text — pick the closest match and
  disclose the substitution rather than presenting it as exact.
- One legitimate exception to "always use the brand primary button": a
  destructive/irreversible action should use the semantic error/danger color for its
  confirm button, called out explicitly in the generation prompt so Stitch doesn't
  default to the brand color on a "yes, delete everything" button.

## After generating

Report back with: the project title + id, both design-system asset ids, and a running
list of every screen id + one-line description, so a later session can resume without
re-deriving state. Downloaded screenshots go to a scratch dir and get sent to the human
in small batches — never dump raw image bytes into the conversation.
