"""Tests for scripts/redact.py — plain asserts, runnable without pytest: python3 tests/test_redact.py"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))
from redact import redact, redact_obj  # noqa: E402


def test_redacts_known_token_shapes():
    for s in ["sk-abcdefghijklmnop", "ghp_" + "a" * 24, "github_pat_" + "b" * 24, "xoxb-1234567890-abc",
              "AKIAABCDEFGHIJKLMNOP", "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abcdefghijklmnop", "a" * 40]:
        assert "[redacted]" in redact("token " + s + " end")


def test_leaves_normal_text_and_short_hex():
    assert redact("fix: commit deadbeef1234 touches sk-lite") == "fix: commit deadbeef1234 touches sk-lite"


def test_sk_prefix_needs_a_left_boundary():
    # I5: "sk-" embedded in an ordinary word (preceded by an alnum) must never be mistaken for a secret,
    # even though the tail after "sk-" happens to look token-shaped (>=8 word chars).
    assert redact("service tradingdesk-ibkr-gateway is up") == "service tradingdesk-ibkr-gateway is up"
    assert redact("mount desk-abcdefghij ready") == "mount desk-abcdefghij ready"
    assert "[redacted]" in redact("token sk-abcdefghijklmnop end")


def test_redact_obj_recurses():
    obj = {"subject": "leak ghp_" + "c" * 24, "n": 3, "list": ["AKIAABCDEFGHIJKLMNOP", 1]}
    out = redact_obj(obj)
    assert out["subject"].endswith("[redacted]") and out["n"] == 3 and out["list"][0] == "[redacted]"


def test_v3_token_shapes_are_redacted_whole():
    for s in ["123456789:" + "A" * 35, "gho_" + "b" * 30, "ghs_" + "a" * 24, "ghu_" + "c" * 22, "ghr_" + "d" * 20,
              "xoxe-1-" + "E" * 20, "xoxe.xoxp-1-" + "F" * 20, "AIza" + "G" * 35]:
        out = redact("bot " + s + " end")
        assert out == "bot [redacted] end", (s, out)


def test_key_value_secrets_keep_the_key():
    assert redact("Authorization: Bearer abc.def-ghi") == "Authorization: Bearer [redacted]"
    assert redact("API_KEY=abc123") == "API_KEY=[redacted]"
    assert redact("MY_API_KEY=abc") == "MY_API_KEY=[redacted]"
    assert redact("token=abc123 rest") == "token=[redacted] rest"
    assert redact("passwd=x") == "passwd=[redacted]" and redact("password: hunter2") == "password: [redacted]"
    assert redact("Secret:yy") == "Secret:[redacted]" and redact("api-key xyz") == "api-key [redacted]"
    assert redact("--token ghp_" + "A" * 24 + " --dry-run") == "--token [redacted] --dry-run"


def test_key_value_rule_leaves_look_alike_words():
    for s in ["tokens are fine", "tokenizer: x", "IBKR API key checkbox", "secretary"]:
        assert redact(s) == s


if __name__ == "__main__":
    fns = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for fn in fns:
        fn()
    print(f"PASS: test_redact ({len(fns)} tests)")
