#!/usr/bin/env python3
"""gate-check.py — every defect class in a registry must name the automated gate that stops it.

Part of the `defect-class-loop` skill. A guardrail that exists only as prose is not done: each class
section in the registry carries one line naming the test(s) that fail on that class, or the tracked
work item that is building the gate.

Registry format (Markdown):
    ## CLASS-NAME — one-line summary (YYYY-MM-DD)
    - **What happened:** ...
    - **Why the gates missed it:** ...
    - **Guardrail:** ...
    - **Gate:** self:tests/foo.test.ts, app:web/lib/bar.test.ts (RED proof: ...)
    - **Gate:** PENDING TICKET-123        <- an OPEN work item that builds the gate
Sections whose heading has no " — " / " - " separator (e.g. "## Working rules") are not classes.

Usage:
    gate-check.py --registry REG.md [--baseline FILE] [--repo NAME=PATH ...] [--open-ids FILE|-]
    gate-check.py --selftest
  --repo        map a repo name used in Gate refs to a checkout path (repeatable). Default: self=<git
                root of the registry, else its directory>. Only refs whose name is mapped are checked.
  --baseline    classes (one name per line, '#' comments) that predate the rule: reported as debt, not
                failed. The baseline only shrinks — a listed class that now has a Gate is an error.
  --open-ids    file (or '-' for stdin) with one OPEN work-item id per line (first token). PENDING ids
                must be in it. Without it, PENDING ids are accepted and reported as unverified.
Exit: 0 GREEN · 1 RED (violations, or zero classes found — a check that examined nothing is not a pass)
      · 2 usage / unreadable input (fails closed). Stdlib only.
"""
import argparse
import os
import re
import subprocess
import sys

HEAD_SEP = re.compile(r" [—-] ")
GATE_LINE = re.compile(r"^- \*\*Gate:\*\*(.*)$", re.M)
PENDING = re.compile(r"PENDING\s+([A-Za-z0-9][A-Za-z0-9_.-]*)")


def classes(text):
    out = []
    for sec in re.split(r"\n(?=## )", text):
        head = sec.splitlines()[0] if sec else ""
        if not head.startswith("## ") or not HEAD_SEP.search(head):
            continue
        name = HEAD_SEP.split(head[3:], 1)[0].strip()
        m = GATE_LINE.search(sec)
        out.append((name, m.group(1).strip() if m else None))
    return out


def check(text, baseline, open_ids, repos, exists):
    """Returns (errors, debt, notes). open_ids=None means 'not verifiable'."""
    errs, debt, notes = [], [], []
    found = classes(text)
    if not found:
        return ["no classes found (expected '## NAME — summary' headings): wrong file or format"], [], []
    names = "|".join(re.escape(r) for r in sorted(repos, key=len, reverse=True))
    ref_re = re.compile(r"(?<![\w/])(" + names + r"):([\w./()\[\]@+-]+)") if names else None
    for name, gate in found:
        if gate is None:
            (debt if name in baseline else errs).append(f'{name}: no "- **Gate:**" line')
            continue
        if name in baseline:
            errs.append(f"{name}: has a Gate now -> remove it from the baseline (the baseline only shrinks)")
        m = PENDING.match(gate)
        if m:
            if open_ids is None:
                notes.append(f"{name}: PENDING {m.group(1)} (unverified: no --open-ids)")
            elif m.group(1) not in open_ids:
                errs.append(f"{name}: PENDING {m.group(1)} is not an open work item")
            continue
        refs = ref_re.findall(gate) if ref_re else []
        if not refs:
            errs.append(f'{name}: Gate must name <repo>:<path> test(s) or PENDING <ID> (got "{gate[:60]}")')
        for repo, path in refs:
            path = path.rstrip(".,;)")
            if not exists(repo, path):
                errs.append(f"{name}: {repo}:{path} does not exist")
    return errs, debt, notes


def read_list(path):
    fh = sys.stdin if path == "-" else open(path, encoding="utf-8")
    with fh:
        return {l.split()[0] for l in fh if l.strip() and not l.lstrip().startswith("#")}


def default_root(registry):
    d = os.path.dirname(os.path.abspath(registry))
    try:
        return subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"], capture_output=True,
                              text=True, check=True).stdout.strip() or d
    except (OSError, subprocess.CalledProcessError):
        return d


def selftest():
    reg = ("## Working rules\nnot a class\n"
           "## A — x (2026-01-01)\n- **Gate:** self:exists.ts (RED proof: old case)\n"
           "## B — y\nno gate\n"
           "## C — z\n- **Gate:** PENDING ROW-1\n"
           "## D — w\n- **Gate:** PENDING GONE-1\n")
    repos = {"self": "/r"}
    ex = lambda r, p: p == "exists.ts"
    errs, _, _ = check(reg, set(), {"ROW-1"}, repos, ex)
    assert any(e.startswith("B:") for e in errs), errs            # new class without a gate -> RED
    assert any(e.startswith("D:") for e in errs), errs            # PENDING on a closed/unknown item -> RED
    assert not any(e.startswith(("A:", "C:", "Working")) for e in errs), errs
    errs, debt, _ = check(reg, {"B"}, {"ROW-1", "GONE-1"}, repos, ex)
    assert errs == [] and len(debt) == 1, (errs, debt)            # baseline debt is reported, not failed
    errs, _, _ = check(reg, {"A"}, {"ROW-1", "GONE-1"}, repos, ex)
    assert any("baseline only shrinks" in e for e in errs), errs  # ratchet
    errs, _, _ = check("## E — v\n- **Gate:** self:missing.ts\n", set(), set(), repos, ex)
    assert errs and "does not exist" in errs[0], errs             # gate names a file that is not there
    errs, _, _ = check("## F — v\n- **Gate:** see the wiki\n", set(), set(), repos, ex)
    assert errs and "must name" in errs[0], errs                  # prose is not a gate
    errs, _, _ = check("# nothing here\n", set(), set(), repos, ex)
    assert errs and "no classes found" in errs[0], errs           # examined nothing -> not a pass
    _, _, notes = check("## G — v\n- **Gate:** PENDING X-1\n", set(), None, repos, ex)
    assert notes and "unverified" in notes[0], notes
    print("gate-check selftest: PASS (7 RED cases)")


def main():
    ap = argparse.ArgumentParser(add_help=True, description="Defect-class registry gate check")
    ap.add_argument("--registry")
    ap.add_argument("--baseline")
    ap.add_argument("--repo", action="append", default=[])
    ap.add_argument("--open-ids")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not a.registry:
        ap.print_usage(sys.stderr)
        sys.exit(2)
    try:
        text = open(a.registry, encoding="utf-8").read()
        baseline = read_list(a.baseline) if a.baseline and os.path.exists(a.baseline) else set()
        open_ids = read_list(a.open_ids) if a.open_ids else None
    except OSError as e:
        print(f"GATE-CHECK: cannot read input ({e})", file=sys.stderr)
        sys.exit(2)
    repos = {}
    for spec in a.repo:
        if "=" not in spec:
            print(f"GATE-CHECK: --repo expects NAME=PATH (got {spec})", file=sys.stderr)
            sys.exit(2)
        k, v = spec.split("=", 1)
        repos[k] = os.path.expanduser(v)
    repos.setdefault("self", default_root(a.registry))
    exists = lambda r, p: os.path.exists(os.path.join(repos[r], p))
    errs, debt, notes = check(text, baseline, open_ids, repos, exists)
    total = len(classes(text))
    for n in notes:
        print("  note: " + n)
    if errs:
        print(f"GATE-CHECK: RED — {len(errs)} violation(s):")
        for e in errs:
            print("  " + e)
        sys.exit(1)
    print(f"GATE-CHECK: GREEN — {total} classes, {total - len(debt)} gated/pending, {len(debt)} baseline debt")


if __name__ == "__main__":
    main()
