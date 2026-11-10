#!/usr/bin/env bash
# impact-graph.mjs: check passes on a clean graph, impact+--why works, and the test-debt ratchet bites both ways.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_REPO="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/assert.sh"
command -v node >/dev/null || { echo "SKIP: node missing"; exit 0; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT; mkdir -p "$T/docs/graph"
cat > "$T/docs/graph/graph.json" <<'J'
{"nodes":[
 {"id":"system.core","kind":"system","title":"Core"},
 {"id":"rule.a","kind":"rule","title":"Rule A"},
 {"id":"rule.b","kind":"rule","title":"Rule B"},
 {"id":"ui.hud","kind":"ui","title":"HUD"},
 {"id":"test.a","kind":"test","title":"Test A"}],
 "edges":[
 {"from":"rule.a","to":"system.core","type":"constrains"},
 {"from":"rule.b","to":"system.core","type":"constrains"},
 {"from":"ui.hud","to":"rule.a","type":"renders"},
 {"from":"test.a","to":"rule.a","type":"tests"}]}
J
run() { (cd "$T" && IMPACT_ROOT="$T" node "$ROOT_REPO/scripts/impact-graph.mjs" "$@" 2>&1); }
# rule.b untested and not in debt -> error
out="$(run check)"; rc=$?; assert_eq "$rc" 1 "untested rule fails"; echo "$out" | grep -q "rule rule.b has no test" || _fail "no-test message"
# list it in debt -> passes
echo '{"rules":{"rule.b":"deferred"}}' > "$T/docs/graph/test-debt.json"
out="$(run check)"; assert_eq "$?" 0 "debt baseline passes"
# add a test to rule.b while still listed -> ratchet error
python3 - "$T/docs/graph/graph.json" <<'P'
import json,sys;p=sys.argv[1];g=json.load(open(p));g['nodes'].append({"id":"test.b","kind":"test","title":"Test B"});g['edges'].append({"from":"test.b","to":"rule.b","type":"tests"});json.dump(g,open(p,'w'))
P
out="$(run check)"; assert_eq "$?" 1 "stale debt fails"; echo "$out" | grep -q "now has a test" || _fail "ratchet message"
# impact of rule.a reaches ui.hud via renders, and --why shows the path
out="$(run rule.a --why)"; echo "$out" | grep -q "ui.hud" || _fail "impact lists ui.hud"; echo "$out" | grep -q "ui.hud -renders-> rule.a\|rule.a -renders-> ui.hud" || _fail "why path"
finish impact-graph-test
