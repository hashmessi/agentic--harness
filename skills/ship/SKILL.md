---
name: ship
description: Run the full harness workflow (inspect, plan, implement, verify, debug, hostile review, finalize) on a coding task and finish only with a passing verification gate. Use for any non-trivial feature, bug fix, refactor, or migration in a git repository.
---

# Ship — verified end-to-end delivery

Task: the text the user gave with this command. If none was given, ask for the task in one line and stop.
Contract: the global harness `AGENTS.md` (§ numbers below refer to it). This skill is the executable checklist.
Phase skills (load the one that matches the phase; they are small): `repo-intel` (INSPECT) · `plan` (PLAN) · `test-first` (IMPLEMENT) · `debug` (DEBUG) · `hostile-review` / `security-audit` (REVIEW) · `refactor`, `perf`, `research`, `release` for those task types · `project-memory` (read/write `.agent/`) · `safe-autonomy` (checkpoints, worktrees, retry budget, approval gates).

## 1. INSPECT
- `git status` and current branch. Note uncommitted user work — you must not overwrite it.
- If `scripts/verify.sh` is missing and the task changes code: `bash ~/agent-harness/bin/harness-init.sh`, then tell the user it was added.
- Read the repo's own `AGENTS.md` / `CLAUDE.md` / README for commands and conventions. If `.agent/` exists, read `CONTEXT.md` and `STATE.md`. Unfamiliar repo: `bash ~/agent-harness/bin/repo-map.sh`.
- Risky or multi-file change: `bash ~/agent-harness/bin/checkpoint.sh save pre-<task>` first (rollback point; touches nothing).
- Locate the smallest relevant set of files; read enough surrounding code to understand contracts, callers, and tests.
- Baseline: `bash scripts/verify.sh`. Record which checks already fail. Pre-existing failures are reported, not silently fixed out of scope.

## 2. PLAN (no code yet)
- Requirements lock (§3): goal, scope, preserve, success criteria, unknowns, risk; MUST/SHOULD/NICE/OUT.
- Pressure-test (§5) only what materially matters. If the approach is weak, say so and pick the stronger one.
- Split into small steps, each with its own check (a test that would fail without it, a command, an observable behavior).
- If a decision materially affects architecture, security, data integrity, or product scope: ask one focused question and wait. Otherwise state assumptions in one line and continue.
- For multi-step work, track steps in the tool's todo list.

## 3. IMPLEMENT — one step at a time
- Smallest coherent change; reuse existing patterns; only relevant files.
- Bug fix: write/identify the failing test first and watch it fail.
- After each step, run the narrowest relevant check (single test file, typecheck of the touched package).

## 4. VERIFY
- `bash scripts/verify.sh`. Read the summary and the failure tails it prints.

## 5. DEBUG (loop until green or genuinely blocked)
- Classify → reproduce → isolate → prove root cause → fix smallest layer → rerun the failing check → rerun the gate (§7).
- Never delete/skip/weaken tests, add unexplained suppressions, or set `HARNESS_ALLOW_*` yourself. If a guard blocks a legitimate change, stop and ask.
- Enforce the retry budget mechanically: `bash ~/agent-harness/bin/checkpoint.sh budget <slug> 3`. Exit 3 = stop and report BLOCKED with evidence instead of thrashing.

## 6. HOSTILE REVIEW
- Prefer a fresh-context reviewer: the `hostile-reviewer` subagent (Claude Code / OpenCode) or the `hostile-review` skill. Give it the task and the base ref; it reviews `git diff` read-only.
- Otherwise switch to Reviewer role yourself and run the §8 checklist against the full diff.
- Fix every confirmed finding; note rejected ones with a one-line reason.

## 7. FINALIZE
- Rerun `bash scripts/verify.sh` — must exit 0 (or report exactly what fails and why it's out of scope/pre-existing).
- `git diff --stat` and read the full diff: only intended files, no debug leftovers, no stray formatting churn.
- Update docs that the change made stale.
- Commit only if the user asked (one logical change, descriptive message) — R9.
- Run the Part II self-check (R12) and fix any "no".
- Report using the §12 format: STATUS / CHANGED / VALIDATED (exact commands + outcomes) / RESULT / REMAINING.
