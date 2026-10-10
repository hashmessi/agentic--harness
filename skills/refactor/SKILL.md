---
name: refactor
description: Behavior-preserving restructuring: rename, extract, move, deduplicate, simplify, or migrate code without changing what it does. Use when asked to clean up, split a large file, remove duplication, modernize, or reduce complexity, and before any change that risks regressions.
---

# Refactor

Behavior stays identical. If behavior must change, that is a separate commit and a separate step.

1. Establish the safety net first: run `bash scripts/verify.sh` for the baseline. If the area lacks tests, write characterization tests that pin current behavior (see `test-first`) before moving anything.
2. Save a rollback point: `bash ~/agent-harness/bin/checkpoint.sh save pre-refactor`.
3. Work in small mechanical steps, each leaving the gate green: rename, extract, move, inline. Prefer the language server or codemod over hand edits for renames across files.
4. Grep every caller and export before changing a signature; update them in the same step. Public API shape changes need an explicit decision.
5. Remove only code you proved dead (no references, including dynamic ones and config). Keep error handling and validation when moving code.
6. Do not mix in unrelated fixes, formatting churn, or dependency upgrades. Mention them instead.
7. Finish with `git diff --stat`: a refactor diff should look like moves and simplifications. Run the gate and the `hostile-review` skill on it. If a test had to change to pass, stop: that means behavior changed.
