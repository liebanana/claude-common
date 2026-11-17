#!/usr/bin/env node
// smoke.cjs — load a local HTML page headless at phone width BEFORE publishing it; fail on any script
// error, and (with --expect <selector>) when the selector renders nothing. Part of the artifact-smoke skill.
// Usage: node smoke.cjs <page.html> [--expect '.main-control'] [--shot out.png] [--width 390]
//        node smoke.cjs --selftest        (proves RED on a page whose script throws)
// Playwright: $PLAYWRIGHT_MODULE (path to a playwright package dir), else normal resolution
// (NODE_PATH / a node_modules above cwd), else playwright-core. Missing = exit 2 (a smoke that cannot
// look never passes). Exit 0 GREEN, 1 RED, 2 cannot run.
const path = require('path'), fs = require('fs'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_MODULE, 'playwright', path.join(process.cwd(), 'node_modules', 'playwright'), 'playwright-core'];
  for (const t of tries) { if (!t) continue; try { return require(t) } catch (_) {} }
  console.error('artifact-smoke: playwright not found (npm i -D playwright, or set PLAYWRIGHT_MODULE=/path/to/node_modules/playwright)');
  process.exit(2);
}
async function smoke(file, expect, shot, width) {
  const { chromium } = loadPlaywright();
  const b = await chromium.launch();
  try {
    const p = await b.newPage({ viewport: { width, height: 900 } });
    const errs = [];
    p.on('pageerror', e => errs.push('pageerror: ' + e.message));
    // Font CDNs are often blocked in sandboxes; their failures are not page defects.
    p.on('console', m => { if (m.type() === 'error' && !/fonts\.(googleapis|gstatic)\.com/.test(m.text())) errs.push('console: ' + m.text()) });
    await p.goto('file://' + path.resolve(file));
    await p.waitForTimeout(1200);
    if (expect && (await p.locator(expect).count()) === 0) errs.push(`expected selector ${expect} rendered 0 elements`);
    if (shot) await p.screenshot({ path: shot, fullPage: true });
    return errs;
  } finally { await b.close() }
}
(async () => {
  const a = process.argv.slice(2);
  if (a[0] === '--selftest') {
    // `function top(){}` shadows window.top and throws in a browser: a real way pages ship blank.
    const f = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'smoke-')), 'bad.html');
    fs.writeFileSync(f, '<div id="x"></div><script>function top(){return 1}document.getElementById("x").innerHTML="<b class=y>ok</b>"</script>');
    const e = await smoke(f, '.y', null, 390);
    if (!e.length) { console.log('artifact-smoke selftest: FAIL (bad page passed)'); process.exit(1) }
    console.log('artifact-smoke selftest: PASS (RED on: ' + e[0] + ')'); return;
  }
  if (!a[0] || !fs.existsSync(a[0])) { console.error('usage: smoke.cjs <page.html> [--expect sel] [--shot out.png] [--width px]'); process.exit(2) }
  const opt = k => { const i = a.indexOf(k); return i > -1 ? a[i + 1] : null };
  const errs = await smoke(a[0], opt('--expect'), opt('--shot'), Number(opt('--width') || 390));
  if (errs.length) { console.log('ARTIFACT-SMOKE: RED\n  ' + errs.join('\n  ')); process.exit(1) }
  console.log('ARTIFACT-SMOKE: GREEN ' + a[0]);
})().catch(e => { console.error('artifact-smoke: ' + e.message); process.exit(2) });
