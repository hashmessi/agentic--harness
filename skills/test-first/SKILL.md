---
name: test-first
description: Write the test that proves behavior before or alongside the change, and judge whether existing tests actually protect it. Use when adding features, fixing bugs, raising coverage, reviewing weak tests, or when asked to "add tests" or "make sure it works".
---

# Test First

A test earns its place only if it fails when the behavior breaks.

1. Find the repo's existing test style (runner, location, naming, fixtures) and copy it. Do not introduce a new framework.
2. **Bug fix**: write the failing test, run it, see it fail for the right reason, then fix. A test that never failed proves nothing.
3. **Feature**: test the behavior contract (inputs, outputs, errors, boundaries: empty, null, max, unicode, concurrent), not the implementation.
4. Prefer real dependencies over mocks at the seam you own. Mock only network, clock, randomness, and paid or irreversible services. Keep tests deterministic and independent.
5. **Mutation check** for important logic: break the code on purpose (flip a condition), confirm a test fails, restore. This is the cheap proof that assertions bite.
6. Run the narrowest test, then `bash scripts/verify.sh`. The gate refuses deleted tests, new skip/focus markers and net assertion removal; never work around it.
7. Bugs that cross layers get one integration test for the path; do not duplicate every unit test at that level.
8. Report what is covered and what is not. "Tests pass" with no test for the changed behavior is UNVERIFIED, not VALIDATED.
