#!/usr/bin/env bash
# Verify claimed fixes are actually in the source.
# Args: +'label|path|marker'  (must be present)   -'label|path|marker'  (must be absent)
# '|' is the delimiter because labels and markers routinely contain ':'.
set -uo pipefail
fail=0
for arg in "$@"; do
  sign="${arg:0:1}"; rest="${arg:1}"
  IFS='|' read -r label path marker <<< "$rest"
  if [ -z "${marker:-}" ]; then printf '  BAD-ARG  %s (expected label|path|marker)\n' "$arg"; fail=1; continue; fi
  if grep -rqF -- "$marker" "$path" 2>/dev/null; then found=yes; else found=no; fi
  case "$sign$found" in
    "+yes") printf '  OK       %s\n' "$label" ;;
    "+no")  printf '  MISSING  %s   (marker: %s)\n' "$label" "$marker"; fail=1 ;;
    "-no")  printf '  OK       %s (absent)\n' "$label" ;;
    "-yes") printf '  PRESENT  %s   (marker: %s) — confirm code vs comment\n' "$label" "$marker"; fail=1 ;;
  esac
done
[ "$fail" -eq 0 ] && echo "all claims verified" || echo "SOME CLAIMS UNVERIFIED — fix the code or drop the claim"
exit "$fail"
