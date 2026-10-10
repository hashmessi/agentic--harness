#!/usr/bin/env bash
# Safety tooling: destructive-command guard, checkpoints/rollback/budget/worktree, repo-map, skill lint.
node --check hooks/guard-bash.mjs
for f in bin/*.sh tests/*.sh; do bash -n "$f" || exit 1; done
bash tests/safety.sh
