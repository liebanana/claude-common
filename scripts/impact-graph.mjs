#!/usr/bin/env node
// meta: id=impact-graph kind=script group="Reusable Claude Code assets" status=ready tags=dependency-graph,impact-analysis,testing,ratchet intent="Typed dependency graph of a project's features/rules/UI/tests/docs: `check` validates it (ratcheting test-debt baseline), `<id> --why` lists everything to revisit when a node changes"
// impact-graph — validate a feature dependency graph and compute the impact of changing a node. Zero dependencies (node >= 18).
//   node scripts/impact-graph.mjs check             validate graph + generated/*.json; exit 1 on errors
//   node scripts/impact-graph.mjs <id> [<id>...]    everything affected (transitive), grouped by kind
//   node scripts/impact-graph.mjs <id> --why        also print the edge path that reaches each node
// Location (relative to IMPACT_ROOT, default cwd): graph file IMPACT_GRAPH (default docs/graph/graph.json); optional sibling
//   generated/*.json (emitted by your build, merged in) and test-debt.json ({"rules": {"<rule id>": "reason"}}).
// Graph format: { "kinds"?: [extra kinds], "nodes": [ {id, kind, title, where:[path#anchor], rules:[text], symmetric?:id} ],
//                 "edges": [ {from, to, type, note?} ] }
// Node ids: dotted lowercase, e.g. `rule.combat.crit`. Kinds: see KINDS (extend per project via "kinds").
// Edge types: uses (from depends on to) · constrains (from imposes rules on to) · mirrors (same rule must hold on both sides)
//   · renders (UI/art shows from) · tests (from verifies to) · documents (from describes to).
// Impact of X = nodes reachable via "who must be revisited if X changes": incoming uses/renders/tests/documents,
//   outgoing constrains, and mirrors both ways.
// Test-debt ratchet: a `rule` with no incoming `tests` edge is an ERROR unless listed in test-debt.json; a listed rule that
//   now HAS a test is also an ERROR (remove it). The baseline can only shrink.
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, relative } from 'node:path';

const ROOT = resolve(process.env.IMPACT_ROOT || process.cwd());
const FILE = resolve(ROOT, process.env.IMPACT_GRAPH || 'docs/graph/graph.json');
const GEN_DIR = resolve(dirname(FILE), 'generated');
const DEBT_FILE = resolve(dirname(FILE), 'test-debt.json');
const rel = (p) => relative(ROOT, p);
const BASE_KINDS = ['system', 'rule', 'data', 'entity', 'ui', 'art', 'audio', 'code', 'test', 'doc', 'telemetry', 'content', 'event', 'state'];
const TYPES = ['uses', 'constrains', 'mirrors', 'renders', 'tests', 'documents'];

if (!existsSync(FILE)) { console.error(`graph not found: ${rel(FILE)} (set IMPACT_ROOT / IMPACT_GRAPH)`); process.exit(2); }
const g = { nodes: [], edges: [] };
const extraKinds = [];
const sources = [[rel(FILE), FILE]];
if (existsSync(GEN_DIR)) for (const f of readdirSync(GEN_DIR).filter(x => x.endsWith('.json')).sort()) sources.push([rel(resolve(GEN_DIR, f)), resolve(GEN_DIR, f)]);
for (const [r, abs] of sources) {
  const part = JSON.parse(readFileSync(abs, 'utf8'));
  extraKinds.push(...(part.kinds || []));
  for (const n of part.nodes || []) g.nodes.push(Object.defineProperty(n, 'src', { value: r, enumerable: false }));
  for (const e of part.edges || []) g.edges.push(Object.defineProperty(e, 'src', { value: r, enumerable: false }));
}
const KINDS = [...BASE_KINDS, ...extraKinds];
const BASE = rel(FILE);
const byId = new Map(g.nodes.map(n => [n.id, n]));
const at = (n) => (n && n.src !== BASE && n.where?.[0] ? ` [${n.where[0]}]` : '');
const edgeSrc = (e) => (e.src !== BASE ? ` (${e.src})` : '');

function check() {
  const errs = [], warns = [];
  const debt = existsSync(DEBT_FILE) ? (JSON.parse(readFileSync(DEBT_FILE, 'utf8')).rules || {}) : {};
  const seen = new Set();
  for (const n of g.nodes) {
    if (!n.id || !/^[a-z0-9]+(\.[a-z0-9_-]+)+$/.test(n.id)) errs.push(`bad id: ${n.id}`);
    if (seen.has(n.id)) errs.push(`duplicate id: ${n.id}`); seen.add(n.id);
    if (!KINDS.includes(n.kind)) errs.push(`${n.id}: unknown kind ${n.kind}${at(n)}`);
    if (!n.title) errs.push(`${n.id}: missing title${at(n)}`);
    for (const w of n.where || []) { const p = w.split('#')[0]; if (p && !existsSync(resolve(ROOT, p))) warns.push(`${n.id}: where not found: ${p}${at(n)}`); }
    if (n.symmetric && !byId.has(n.symmetric)) errs.push(`${n.id}: symmetric target missing ${n.symmetric}${at(n)}`);
  }
  for (const e of g.edges) {
    if (!byId.has(e.from)) errs.push(`edge from unknown ${e.from}${edgeSrc(e)}`);
    if (!byId.has(e.to)) errs.push(`edge to unknown ${e.to}${edgeSrc(e)}`);
    if (!TYPES.includes(e.type)) errs.push(`edge ${e.from}->${e.to}: unknown type ${e.type}${edgeSrc(e)}`);
  }
  for (const n of g.nodes.filter(n => n.kind === 'rule')) {
    if (!g.edges.some(e => e.from === n.id && e.type === 'constrains')) warns.push(`rule ${n.id} constrains nothing${at(n)}`);
    const tested = g.edges.some(e => e.to === n.id && e.type === 'tests');
    if (!tested && !debt[n.id]) errs.push(`rule ${n.id} has no test (add a tests edge, or list it with a reason in ${rel(DEBT_FILE)} only if truly deferred)${at(n)}`);
    if (tested && debt[n.id]) errs.push(`rule ${n.id} now has a test: remove it from ${rel(DEBT_FILE)}${at(n)}`);
  }
  for (const id of Object.keys(debt)) if (!byId.has(id) || byId.get(id).kind !== 'rule') errs.push(`test-debt lists ${id}, which is not a rule in the graph`);
  for (const n of g.nodes.filter(n => n.symmetric)) {
    const ok = g.edges.some(e => e.type === 'mirrors' && ((e.from === n.id && e.to === n.symmetric) || (e.to === n.id && e.from === n.symmetric)));
    if (!ok) errs.push(`${n.id} declares symmetric ${n.symmetric} but no mirrors edge${at(n)}`);
  }
  for (const n of g.nodes) if (!g.edges.some(e => e.from === n.id || e.to === n.id)) warns.push(`orphan node ${n.id}${at(n)}`);
  for (const w of warns) console.log('WARN ' + w);
  for (const e of errs) console.log('ERROR ' + e);
  console.log(`graph: ${g.nodes.length} nodes, ${g.edges.length} edges, ${errs.length} errors, ${warns.length} warnings, test debt ${Object.keys(debt).length} rule(s)`);
  process.exitCode = errs.length ? 1 : 0; // exitCode, not exit(): exiting after a big pipe write can truncate output
}

function neighbors(id) {
  const out = [];
  for (const e of g.edges) {
    if (e.type === 'mirrors' && (e.from === id || e.to === id)) out.push([e.from === id ? e.to : e.from, e]);
    else if (e.type === 'constrains' && e.from === id) out.push([e.to, e]);
    else if (['uses', 'renders', 'tests', 'documents'].includes(e.type) && e.to === id) out.push([e.from, e]);
  }
  return out;
}

function impact(ids, why) {
  for (const id of ids) if (!byId.has(id)) { console.error(`unknown node: ${id}`); process.exit(2); }
  const via = new Map(ids.map(i => [i, null]));
  const q = [...ids];
  while (q.length) { const cur = q.shift(); for (const [nx, e] of neighbors(cur)) if (!via.has(nx)) { via.set(nx, { from: cur, e }); q.push(nx); } }
  const groups = {};
  for (const [id] of via) { if (ids.includes(id)) continue; const n = byId.get(id); (groups[n.kind] ||= []).push(n); }
  console.log(`Impact of changing: ${ids.join(', ')}  (${via.size - ids.length} nodes to revisit)\n`);
  for (const k of KINDS) if (groups[k]) {
    console.log(`## ${k}`);
    for (const n of groups[k]) {
      console.log(`- ${n.id} — ${n.title}${n.where?.length ? '  [' + n.where.join(', ') + ']' : ''}`);
      if (why) { const path = []; let c = n.id; while (via.get(c)) { const v = via.get(c); path.unshift(`${v.from} -${v.e.type}-> ${c}`); c = v.from; } console.log('    via ' + path.join(' · ')); }
      for (const r of n.rules || []) console.log(`    rule: ${r}`);
    }
  }
}

const args = process.argv.slice(2);
if (!args.length || args[0] === 'check') check();
else impact(args.filter(a => !a.startsWith('--')), args.includes('--why'));
