---
name: feature-impact-graph
description: Use before changing a feature in a project that has (or should have) a typed dependency graph — run the impact query to see every code/data/UI/art/test/doc node to update in the same change, and add every new thing to the graph. Includes a ratcheting test-debt gate.
kind: skill
status: ready
group: Reusable Claude Code assets
intent: Keep multi-file features consistent with a small JSON dependency graph and `scripts/impact-graph.mjs` (check + impact --why + a ratcheting test-debt baseline)
tags: [skill, dependency-graph, impact-analysis, testing, consistency]
---

# Feature impact graph

A feature is never one file: change a rule and its two sides, its UI, tests and docs change too. Agents forget the
neighbours. A small graph makes the neighbours queryable. Tool: `scripts/impact-graph.mjs` (zero deps, node >= 18) — copy it into the
project (e.g. `tools/impact.mjs`) or call it from `~/repos/claude-common/scripts/`.

## Setup (once per project)

Create `docs/graph/graph.json` (override with `IMPACT_GRAPH`, root with `IMPACT_ROOT`):

```json
{"nodes":[{"id":"rule.damage.crit","kind":"rule","title":"Crits double damage","where":["src/combat.ts#crit"],"rules":["x2, never stacks"]}],
 "edges":[{"from":"rule.damage.crit","to":"system.combat","type":"constrains"}]}
```

- Ids are dotted lowercase (`kind.area.name`). Kinds: `system rule data entity ui art audio code test doc telemetry content event state` (add more with `"kinds":[…]`).
- Edge types: **uses** (from depends on to) · **constrains** (from imposes a rule on to) · **mirrors** (same rule must hold on both sides, e.g. player/enemy, client/server; pair with `"symmetric"`) · **renders** (UI/art shows from) · **tests** (from verifies to) · **documents** (from describes to).
- Optional: `docs/graph/generated/*.json` merged in (emit them from your content build so data-defined nodes need no hand edits).

## The workflow

1. **Before touching a feature:** `node impact-graph.mjs <node> --why`. Everything listed (code, data, UI, art, tests, docs, telemetry) is updated **in the same change**, or the report says what was left and why.
2. **Every new thing enters the graph in the same change:** node(s) + edges. No node = invisible to the next agent.
3. **Gate:** `node impact-graph.mjs check` → 0 errors (wire it into CI / `verify`).
4. In subagent briefs: name the starting node and require the report to say which impacted nodes were touched.

## Ratcheting test-debt baseline

A `rule` node needs an incoming `tests` edge. If it has none, `check` **errors** unless the rule is listed in `docs/graph/test-debt.json` (`{"rules":{"rule.id":"reason deferred"}}`). The reverse also **errors**: a listed rule that now has a test must be removed from the file. So the debt list can only shrink; new untested rules are never silently added.
