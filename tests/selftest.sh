#!/usr/bin/env bash
# End-to-end self-test for the harness. Uses throwaway repos and a sandbox HOME; never touches real config.
# Usage: bash ~/agent-harness/tests/selftest.sh
set -uo pipefail

HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export GIT_AUTHOR_NAME=harness GIT_AUTHOR_EMAIL=harness@test GIT_COMMITTER_NAME=harness GIT_COMMITTER_EMAIL=harness@test
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1   # isolate from user git config (autocrlf, hooks, templates)
unset HARNESS_ALLOW_TEST_CHANGES HARNESS_ALLOW_SUPPRESSIONS HARNESS_BASE VERIFY_SKIP HARNESS_SKIP_GATE
PASSED=0 FAILED=0

ok()   { PASSED=$((PASSED + 1)); echo "  ok   $1"; }
bad()  { FAILED=$((FAILED + 1)); echo "  FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | tail -n 25 | sed 's/^/       | /'; }
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

# expect_verify NAME EXPECTED_EXIT [GREP_PATTERN] — run the gate in the cwd.
expect_verify() {
  local out rc
  out="$(bash scripts/verify.sh 2>&1)"; rc=$?
  if [ "$rc" -ne "$2" ]; then bad "$1 (exit $rc, want $2)" "$out"; return; fi
  if [ -n "${3:-}" ] && ! grep -qE -- "$3" <<<"$out"; then bad "$1 (output lacks /$3/)" "$out"; return; fi
  ok "$1"
}
new_repo() { rm -rf "$1"; mkdir -p "$1"; cd "$1" && git init -q && git checkout -q -b main 2>/dev/null; }
commit_all() { git add -A && git commit -qm "${1:-wip}"; }

echo "== verify.sh: node fixture"
new_repo "$TMP/node"
cat >package.json <<'EOF'
{ "name": "fixture", "version": "1.0.0", "scripts": { "test": "node test/math.test.js" } }
EOF
mkdir -p test src
echo 'module.exports.add = (a, b) => a + b;' >src/math.js
cat >test/math.test.js <<'EOF'
const assert = require("assert");
const { add } = require("../src/math");
assert.strictEqual(add(2, 3), 5);
assert.strictEqual(add(-1, 1), 0);
EOF
bash "$HARNESS/bin/harness-init.sh" >/dev/null && ok "harness-init installs gate" || bad "harness-init installs gate"
out="$(bash "$HARNESS/bin/harness-init.sh")"
grep -q "up to date" <<<"$out" && ok "harness-init is idempotent" || bad "harness-init is idempotent" "$out"
commit_all init
expect_verify "clean repo passes" 0 'RESULT: PASS'
[ "$(cat .git/harness/verify-stamp)" = "$(bash scripts/verify.sh --tree-hash)" ] && ok "pass writes tree stamp" || bad "pass writes tree stamp"

echo 'module.exports.add = (a, b) => a - b;' >src/math.js
expect_verify "failing test fails gate" 1 'FAIL +node:test'
git checkout -q -- src/math.js

sed -i 's/^assert.strictEqual(add(-1, 1), 0);$//' test/math.test.js
expect_verify "net assertion removal is caught" 1 'net assertions removed'
git checkout -q -- test/math.test.js

echo '// it.skip("later", () => {});  (guard must catch markers even where the runner still passes)' >>test/math.test.js
expect_verify "added skip marker is caught" 1 'skip/focus marker added'
HARNESS_ALLOW_TEST_CHANGES=1 bash scripts/verify.sh >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ok "human override waives (exit 0)" || bad "human override waives (exit $rc)"
out="$(HARNESS_ALLOW_TEST_CHANGES=1 bash scripts/verify.sh 2>&1)"
grep -q 'PASS WITH EXCEPTIONS' <<<"$out" && ok "waiver is reported as exception" || bad "waiver is reported as exception" "$out"
git checkout -q -- test/math.test.js

echo '// docs: it.skip(name) skips a test' >src/a-test-helpers
expect_verify "non-test path is not treated as a test file (literal dot in pattern)" 0 'RESULT: PASS'
rm src/a-test-helpers

git rm -q test/math.test.js
expect_verify "deleted test file is caught" 1 'deleted test file'
git reset -q --hard

printf '// eslint-disable-next-line no-eval\nmodule.exports.e = (s) => eval(s);\n' >src/evil.js
expect_verify "unexplained suppression is caught" 1 'unexplained suppression'
printf '// eslint-disable-next-line no-eval -- reason: sandboxed REPL\nmodule.exports.e = (s) => eval(s);\n' >src/evil.js
expect_verify "justified suppression passes" 0 'RESULT: PASS'
rm src/evil.js

FAKE_KEY="AKIA$(printf 'Q%.0s' {1..16})"
printf 'const k = "%s";\n' "$FAKE_KEY" >src/config.js
out="$(bash scripts/verify.sh 2>&1)"; rc=$?
[ $rc -eq 1 ] && grep -q 'possible aws-access-key: src/config.js' <<<"$out" && ok "secret in untracked file is caught" || bad "secret in untracked file is caught" "$out"
grep -qF "$FAKE_KEY" <<<"$out" && bad "secret value leaked into output" || ok "secret value is not echoed"
rm src/config.js

echo 'module.exports.slug = "risk-assessment-for-the-quarterly-report-2026";' >src/slug.js
expect_verify "kebab-case text is not a secret (no false positive)" 0 'RESULT: PASS'
rm src/slug.js

echo 'DB_URL=postgres://x' >.env
expect_verify ".env file is caught" 1 'secret-bearing file not ignored: .env'
mv .env .env.example
expect_verify ".env.example is allowed" 0 'RESULT: PASS'
rm .env.example

out="$(VERIFY_SKIP=node:test bash scripts/verify.sh 2>&1)"
grep -q 'PASS WITH EXCEPTIONS' <<<"$out" && ok "VERIFY_SKIP never yields clean PASS" || bad "VERIFY_SKIP never yields clean PASS"

echo "== verify.sh: unmanaged gate is never overwritten"
new_repo "$TMP/custom"
mkdir -p scripts; echo 'echo mine' >scripts/verify.sh
bash "$HARNESS/bin/harness-init.sh" >/dev/null 2>&1 && bad "refuses to clobber custom verify.sh" || ok "refuses to clobber custom verify.sh"
grep -q 'echo mine' scripts/verify.sh && ok "custom verify.sh preserved" || bad "custom verify.sh preserved"

echo "== verify.sh: no stack"
new_repo "$TMP/empty"
echo "# docs" >README.md; bash "$HARNESS/bin/harness-init.sh" >/dev/null; commit_all
expect_verify "no checks is not a pass (exit 2)" 2 'NO-CHECKS'
printf 'test -f README.md\n' >scripts/verify.d/10-readme.sh
expect_verify "verify.d custom check runs" 0 'PASS +custom:10-readme'

echo "== verify.sh: python fixture"
new_repo "$TMP/py"
printf '[project]\nname = "fx"\nversion = "0"\n\n[tool.pytest.ini_options]\ntestpaths = ["tests"]\n' >pyproject.toml
mkdir tests; printf 'def test_ok():\n    assert 1 + 1 == 2\n' >tests/test_ok.py
bash "$HARNESS/bin/harness-init.sh" >/dev/null; commit_all
PY=""; for c in python3 python; do "$c" -c 'import sys' >/dev/null 2>&1 && { PY=$c; break; }; done
if [ -n "$PY" ] && "$PY" -c 'import pytest' >/dev/null 2>&1; then
  expect_verify "pytest runs and passes" 0 'PASS +py:pytest'
else
  expect_verify "configured-but-missing pytest fails (not skipped)" 1 'FAIL +py:pytest'
fi

echo "== verify-gate.mjs (Claude Code Stop hook)"
cd "$TMP/node"; git reset -q --hard; git clean -qfdx -e .git
TR="$TMP/transcript.jsonl"
ROOTN="$(native "$TMP/node")"
gate() { node "$HARNESS/hooks/verify-gate.mjs" <<<"$1" >/dev/null 2>&1; echo $?; }
payload() { printf '{"cwd":"%s","transcript_path":"%s","stop_hook_active":%s}' "$ROOTN" "$(native "$TR")" "${1:-false}"; }
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"%s/src/math.js"}}]}}\n' "$ROOTN" >"$TR"
echo '// edit' >>src/math.js
[ "$(gate "$(payload)")" = 0 ] && ok "gate ignores sessions with no edits" || bad "gate ignores sessions with no edits"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"%s/src/math.js"}}]}}\n' "$ROOTN" >"$TR"
rm -f .git/harness/verify-stamp
[ "$(gate "$(payload)")" = 2 ] && ok "gate blocks unverified edits" || bad "gate blocks unverified edits"
[ "$(gate "$(payload true)")" = 0 ] && ok "gate never loops (stop_hook_active)" || bad "gate never loops (stop_hook_active)"
bash scripts/verify.sh >/dev/null 2>&1
[ "$(gate "$(payload)")" = 0 ] && ok "gate passes after verify passes" || bad "gate passes after verify passes"
echo '// another' >>src/math.js
[ "$(gate "$(payload)")" = 2 ] && ok "gate re-blocks after a later edit" || bad "gate re-blocks after a later edit"
git checkout -q -- src/math.js
[ "$(gate "$(payload)")" = 0 ] && ok "gate passes when tree equals HEAD" || bad "gate passes when tree equals HEAD"
new_repo "$TMP/nogate"; echo x >a.txt; commit_all; echo y >>a.txt
ROOTN="$(native "$TMP/nogate")"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"%s/a.txt"}}]}}\n' "$ROOTN" >"$TR"
[ "$(gate "$(payload)")" = 2 ] && ok "gate demands harness-init where gate is missing" || bad "gate demands harness-init where gate is missing"

echo "== sync.sh (sandbox HOME)"
SB="$TMP/home"; mkdir -p "$SB/.gemini" "$SB/.claude"
echo "old gemini rules" >"$SB/.gemini/GEMINI.md"
echo '{ "theme": "dark", "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "echo other" } ] } ] } }' >"$SB/.claude/settings.json"
out="$(HARNESS_TARGET_HOME="$SB" bash "$HARNESS/bin/sync.sh" 2>&1)" && ok "sync runs" || bad "sync runs" "$out"
grep -q 'old gemini rules' "$SB/.gemini/GEMINI.md.pre-harness.bak" && ok "unowned file backed up before overwrite" || bad "unowned file backed up before overwrite"
{ cat "$HARNESS/AGENTS.md"; printf '\n'; cat "$HARNESS/REGULATIONS.md"; } >"$TMP/expected-doc.md"
for f in .claude/CLAUDE.md .config/opencode/AGENTS.md .gemini/GEMINI.md; do
  tail -n +3 "$SB/$f" | cmp -s - "$TMP/expected-doc.md" && ok "$f = contract + regulations" || bad "$f = contract + regulations"
done
grep -q '^## R2\. Hard Limits' "$SB/.gemini/GEMINI.md" && grep -q '^## 1\. The Workflow' "$SB/.gemini/GEMINI.md" \
  && ok "both parts present in distributed rules" || bad "both parts present in distributed rules"
for pair in scout:haiku implementer:sonnet hostile-reviewer:opus; do
  grep -qx "model: ${pair#*:}" "$SB/.claude/agents/${pair%%:*}.md" && ok "${pair%%:*} pinned to ${pair#*:}" || bad "${pair%%:*} pinned to ${pair#*:}"
done
for s in "$HARNESS"/skills/*/; do
  s="$(basename "$s")"
  grep -qx "name: $s" "$HARNESS/skills/$s/SKILL.md" || bad "skill $s: frontmatter name matches folder"
  for dir in .claude/skills .config/opencode/skills .gemini/skills; do
    [ -f "$SB/$dir/$s/SKILL.md" ] || bad "skill $s missing in $dir"
  done
  grep -q "\`$s\`" "$HARNESS/AGENTS.md" && ok "skill $s distributed to 3 CLIs and indexed in AGENTS.md" || bad "skill $s not indexed in AGENTS.md"
done
[ ! -e "$SB/.codex" ] && ok "sync no longer touches ~/.codex" || bad "sync no longer touches ~/.codex"
ids="$(grep -oE '^- R[0-9]+\.[0-9]+' "$HARNESS/REGULATIONS.md" | sort | uniq -d)"
[ -z "$ids" ] && ok "regulation IDs are unique" || bad "regulation IDs are unique" "$ids"
for f in .claude/skills/ship/SKILL.md .gemini/skills/hostile-review/SKILL.md .claude/agents/hostile-reviewer.md .claude/agents/scout.md .claude/agents/implementer.md .config/opencode/agents/hostile-reviewer.md .config/opencode/commands/ship.md; do
  [ -f "$SB/$f" ] && head -n 1 "$SB/$f" | grep -q '^---' && ok "$f present with frontmatter" || bad "$f present with frontmatter"
done
node -e '
  const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const cmds = s.hooks.Stop.flatMap((g) => g.hooks);
  if (s.theme !== "dark") throw new Error("lost theme");
  if (!cmds.some((h) => h.command === "echo other")) throw new Error("lost existing hook");
  if (cmds.filter((h) => (h.args || []).some((a) => a.endsWith("verify-gate.mjs"))).length !== 1) throw new Error("gate not exactly once");
' "$(native "$SB/.claude/settings.json")" && ok "settings merge keeps existing keys/hooks, adds gate once" || bad "settings merge keeps existing keys/hooks, adds gate once"
out="$(HARNESS_TARGET_HOME="$SB" bash "$HARNESS/bin/sync.sh" 2>&1)"
grep -qE '^(wrote|backup):' <<<"$out" && bad "second sync is a no-op" "$out" || ok "second sync is a no-op"
HARNESS_TARGET_HOME="$SB" bash "$HARNESS/bin/sync.sh" --check >/dev/null 2>&1 && ok "--check reports in sync" || bad "--check reports in sync"
echo "tamper" >>"$SB/.gemini/GEMINI.md"
HARNESS_TARGET_HOME="$SB" bash "$HARNESS/bin/sync.sh" --check >/dev/null 2>&1 && bad "--check detects drift" || ok "--check detects drift"

echo "== engine"
cmp -s "$HARNESS/bin/verify.sh" "$TMP/node/scripts/verify.sh" && ok "installed gate identical to engine" || bad "installed gate identical to engine"

echo
echo "selftest: $PASSED passed, $FAILED failed"
[ $FAILED -eq 0 ]
