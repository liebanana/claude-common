#!/usr/bin/env python3
"""test-page-check.py — a page that asks a human to test something must give EVERY step its own verdict.

Part of the artifact-smoke skill. When feedback comes back as one long free-text message, steps get
skipped and nothing is machine-readable. A human test page therefore follows this shape:
  - the steps live in a container with `data-human-test`; one element per step with `data-step="<id>"`;
  - each step holds the three verdict controls `data-verdict="ok"` / `"fail"` / `"partial"`
    (works / does not work / works but not as expected) and a note field with `data-note`;
  - when the publish declares capabilities, it must include `db`, so verdicts are stored where the
    agent can read them back (not only in the viewer's browser).
A page "asks for a test" when it has `data-human-test`, or its text matches --asks (a regex; default
English phrases — pass your own for other languages).

Usage: test-page-check.py <page.html> [--capabilities '<json>|null'] [--asks REGEX]
       test-page-check.py --selftest
Exit 0 = fine or not a test page · 1 = violations (printed to stderr) · 2 = usage. Stdlib only.
"""
import json
import re
import sys
from html.parser import HTMLParser

DEFAULT_ASKS = r"what to test|steps to test|please test|test on your (phone|device)|how to test"
VERDICTS = ("ok", "fail", "partial")
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}


class Steps(HTMLParser):
    def __init__(self):
        super().__init__()
        self.container, self.depth = False, 0
        self.stack, self.step_depths, self.steps = [], [], {}

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "data-human-test" in a:
            self.container = True
        if "data-step" in a:
            sid = a["data-step"] or f"step-{len(self.steps) + 1}"
            self.steps.setdefault(sid, {"verdicts": set(), "note": False})
            self.stack.append(sid)
            self.step_depths.append(self.depth)
        if self.stack:
            cur = self.steps[self.stack[-1]]
            if a.get("data-verdict") in VERDICTS:
                cur["verdicts"].add(a["data-verdict"])
            if "data-note" in a:
                cur["note"] = True
        if tag not in VOID:
            self.depth += 1
        elif self.step_depths and self.depth == self.step_depths[-1]:
            self.step_depths.pop()  # a void element that is itself a step closes immediately
            self.stack.pop()

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        self.depth -= 1
        if self.step_depths and self.depth == self.step_depths[-1]:
            self.step_depths.pop()
            self.stack.pop()


def check(html, capabilities=None, asks=DEFAULT_ASKS):
    text = re.sub(r"<script.*?</script>|<style.*?</style>|<[^>]+>", " ", html, flags=re.S | re.I)
    if "data-human-test" not in html and not re.search(asks, text, re.I):
        return []
    p = Steps()
    p.feed(html)
    errs = []
    if not p.container:
        errs.append("page asks for a test but has no [data-human-test] steps container")
    if not p.steps:
        errs.append("no [data-step] elements: every step needs its own verdict")
    for sid, s in p.steps.items():
        missing = [v for v in VERDICTS if v not in s["verdicts"]]
        if missing:
            errs.append(f"step {sid}: missing verdict controls {missing}")
        if not s["note"]:
            errs.append(f"step {sid}: missing [data-note] field")
    if capabilities is not None and "db" not in capabilities:
        errs.append("publish does not declare the db capability: verdicts would never reach the agent")
    return errs


def selftest():
    good = ('<h2>What to test</h2><ol data-human-test><li data-step="a">Tap Start'
            '<button data-verdict="ok">Works</button><button data-verdict="fail">Broken</button>'
            '<button data-verdict="partial">Not as expected</button><textarea data-note></textarea></li></ol>')
    assert check(good, {"db": {}}) == [], check(good, {"db": {}})
    assert check("<p>Release notes, nothing to try</p>") == []                        # not a test page
    assert any("container" in e for e in check("<h2>What to test</h2><ol><li>Tap</li></ol>"))   # plain list -> RED
    no_note = good.replace("<textarea data-note></textarea>", "")
    assert any("data-note" in e for e in check(no_note))                              # step without a note -> RED
    assert any("missing verdict" in e for e in check(good.replace('data-verdict="partial"', "")))
    assert any("db capability" in e for e in check(good, {}))                         # verdicts not persisted -> RED
    assert check("<h2>Qué probar</h2><ol><li>x</li></ol>", asks="qu[ée] probar")      # custom --asks
    print("test-page-check selftest: PASS (5 RED cases)")


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest() or 0
    if not a or a[0].startswith("--"):
        print(__doc__, file=sys.stderr)
        return 2
    opt = lambda k: a[a.index(k) + 1] if k in a and a.index(k) + 1 < len(a) else None
    raw = opt("--capabilities")
    caps = json.loads(raw) if raw and raw != "null" else None
    with open(a[0], encoding="utf-8") as fh:
        errs = check(fh.read(), caps, opt("--asks") or DEFAULT_ASKS)
    if errs:
        print("HUMAN-TEST-PAGE-WITHOUT-VERDICTS:\n  " + "\n  ".join(errs), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
