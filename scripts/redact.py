#!/usr/bin/env python3
# meta: id=redact kind=script group="Reusable Claude Code assets" status=ready tags=security,secrets,redaction,public-repo intent="Dependency-free scrubber for secret-shaped strings (API keys, GitHub/Slack/Telegram tokens, JWTs, long hex, key=value secrets) — import redact()/redact_obj() or pipe text through it before publishing"
"""redact.py — scrub secret-looking substrings from text or JSON-like objects.

Library:   from redact import redact, redact_obj
CLI:       git diff main | python3 scripts/redact.py            # stdout has [redacted] where secrets were
           python3 scripts/redact.py --check < file             # exit 1 if anything WOULD be redacted (pre-push sweep)
Patterns: sk-…, GitHub ghp_/gho_/ghs_/ghr_/ghu_/github_pat_, Slack xox*, AWS AKIA…, Google AIza…, Telegram bot
tokens, JWTs, 32+ hex runs, and "bearer/token/secret/password/api_key = value" pairs (the key is kept).
No third-party dependencies. Origin: the oracle project's snapshot scrubber; tests in tests/test_redact.py.
"""
from __future__ import annotations

import re
import sys

_PATTERNS = [
    r"(?<![A-Za-z0-9])sk-[A-Za-z0-9_-]{8,}",
    r"gh[opsru]_[A-Za-z0-9]{20,}",                       # GitHub: ghp_ (was the only one in v1), gho_, ghs_, ghr_, ghu_
    r"github_pat_[A-Za-z0-9_]{20,}",
    r"xox[abpe][.-][A-Za-z0-9.-]{10,}",                 # Slack, incl. xoxe- / xoxe.xoxp- refresh tokens
    r"AKIA[0-9A-Z]{16}",
    r"AIza[0-9A-Za-z_-]{35}",                           # Google API key
    r"\d{8,10}:[A-Za-z0-9_-]{35}",                      # Telegram bot token
    r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",
    r"\b[0-9a-f]{32,}\b",
]
_RE = re.compile("|".join(f"(?:{p})" for p in _PATTERNS))
# v3 §4.7: the value is redacted and the key kept ("Bearer [redacted]", "API_KEY=[redacted]"). The separator is the
# spec's [=: ] widened to "optional spaces around = or :" so a YAML-style "password: x" is caught too.
_KEY_VALUE_RE = re.compile(r"(?i)(\bbearer\s+|(?:token|secret|passw(?:or)?d|api[_-]?key)(?:\s*[=:]\s*|\s+))\S+")


def redact(s: str) -> str:
    s = _RE.sub("[redacted]", s)
    return _KEY_VALUE_RE.sub(lambda m: m.group(1) + "[redacted]", s)


def redact_obj(obj):
    if isinstance(obj, str):
        return redact(obj)
    if isinstance(obj, list):
        return [redact_obj(x) for x in obj]
    if isinstance(obj, dict):
        return {k: redact_obj(v) for k, v in obj.items()}
    return obj


def _main(argv: list[str]) -> int:
    check = "--check" in argv
    text = sys.stdin.read()
    out = redact(text)
    if check:
        n = out.count("[redacted]") - text.count("[redacted]")
        print(f"redact: {n} secret-shaped span(s) found" if n else "redact: clean", file=sys.stderr)
        return 1 if n else 0
    sys.stdout.write(out)
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
