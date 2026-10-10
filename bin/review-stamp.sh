#!/usr/bin/env bash
# Record that the CURRENT working tree has been hostile-reviewed (read by hooks/verify-gate.mjs for large changes).
# Run it only after the review's confirmed findings are fixed and `bash scripts/verify.sh` passes. Any later edit voids it.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
[ -f scripts/verify.sh ] || { echo "review-stamp: no scripts/verify.sh (run harness-init.sh)" >&2; exit 2; }
GD="$(git rev-parse --absolute-git-dir)"; mkdir -p "$GD/harness"
bash scripts/verify.sh --tree-hash >"$GD/harness/review-stamp"
echo "review stamped: $(cat "$GD/harness/review-stamp")"
