#!/usr/bin/env bash
# Tiny assert helpers for tests/*.sh. Source me. Each failure prints and exits 1.
FAILS=0
_fail() { echo "  FAIL: $*" >&2; FAILS=$((FAILS+1)); }
assert_eq()       { [ "$1" = "$2" ] || _fail "$3: expected '$2' got '$1'"; }
assert_file()     { [ -f "$1" ] || _fail "missing file $1"; }
assert_not_file() { [ ! -e "$1" ] || _fail "should not exist: $1"; }
assert_exec()     { [ -x "$1" ] || _fail "not executable: $1"; }
assert_grep()     { grep -qE -- "$1" "$2" || _fail "'$1' not found in $2"; }
assert_no_grep()  { ! grep -qE -- "$1" "$2" || _fail "'$1' unexpectedly found in $2"; }
assert_count()    { local n; n=$(grep -cE -- "$1" "$2" || true); [ "$n" = "$3" ] || _fail "'$1' in $2: expected $3 matches, got $n"; }
finish()          { if [ "$FAILS" = 0 ]; then echo "PASS: $1"; exit 0; else echo "FAILED: $1 ($FAILS)"; exit 1; fi; }
