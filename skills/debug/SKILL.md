---
name: debug
description: Root-cause debugging loop for failing tests, build errors, runtime exceptions, flaky behavior and "it doesn't work" reports. Use whenever something fails or behaves unexpectedly, before changing any code to fix it, and when a previous fix attempt did not work.
---

# Debug

Evidence first. A fix you cannot explain is a coincidence.

1. **Classify**: syntax, type, dependency, config, runtime, data, integration, environment, architecture, requirement mismatch.
2. **Observe**: read the whole error and the first stack frame in your code. Check `git diff` and `git log -5` for what changed. Read logs from files, not memory.
3. **Reproduce** with the narrowest command; turn it into a failing test when it is a code bug. If you cannot reproduce, say so; do not guess-fix.
4. **Budget**: `bash ~/agent-harness/bin/checkpoint.sh budget <issue-slug> 3` before each distinct hypothesis. Exit 3 means stop and report BLOCKED with the evidence gathered. This is what prevents thrashing.
5. **Isolate**: bisect by input, by commit (`git bisect`), or by disabling a layer. Change one variable at a time.
6. **Hypothesize, then test the hypothesis** with a print, assertion or probe before editing. Prove the cause.
7. **Fix the smallest correct layer**, not the symptom. Rerun the failing check, then the full gate.
8. **Never**: rewrite everything on first failure, add retries to hide deterministic failures, loosen or delete assertions, skip tests, silence the log you need, or set `HARNESS_ALLOW_*`.
9. If the root cause was a repeatable trap, add one line to `.agent/LESSONS.md` (see `project-memory`).
