# The harness verifies itself with its own gate: the installed copy must match the engine, and the e2e suite must pass.
cmp -s bin/verify.sh scripts/verify.sh || { echo "scripts/verify.sh is stale — run: bash bin/harness-init.sh ."; exit 1; }
node --check hooks/verify-gate.mjs
for f in bin/*.sh tests/*.sh; do bash -n "$f" || exit 1; done
bash tests/selftest.sh
