---
name: plan
description: Turn a request into a requirements lock and a sequence of small, independently verifiable steps before any code is written. Use for any feature, migration, refactor or ambiguous ask, whenever the user says "plan", "design", "how should we", or the change touches more than one file or layer.
---

# Plan

No code in this phase. A plan that cannot be checked step by step is a wish.

1. **Requirements lock** (AGENTS.md section 3): Goal, Scope, Preserve, Success (observable), Environment, Unknowns, Risk. Tag each requirement MUST / SHOULD / NICE / OUT. Never promote NICE to MUST silently.
2. **Pressure-test** only what changes the outcome: does it solve the real problem, is there a smaller mechanism, does it duplicate something existing (search first), what happens on empty/invalid data, retries and dependency failure?
3. **Decide ask vs proceed**: ask one question only if the answer changes architecture, security, data integrity or product scope. Otherwise state the assumption in one line and continue (R6.3, R6.5).
4. **Steps**: each step lists files touched, the behavior added, and its own check (a test that fails without it, a command, an observable result). Order so every step leaves the repo green. Put risky or foundational steps first.
5. **Checkpoint plan**: name the rollback point (`bash ~/agent-harness/bin/checkpoint.sh save <name>`) before the first risky step.
6. Track steps in the CLI's todo list; the last item is always "verify with `bash scripts/verify.sh` and review the diff".

Output: lock (5 to 8 lines) + numbered steps. Show it only when the change is architectural or high-blast-radius; otherwise proceed.
