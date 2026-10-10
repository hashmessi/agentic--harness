---
name: release
description: Prepare and verify a release or deploy: version, changelog, build artifacts, migrations, rollout and rollback plan. Use when asked to release, publish, tag, deploy, cut a version, ship to production, or write release notes. Publishing itself always needs human confirmation.
---

# Release

Preparing is agent work. Publishing is outward-facing and irreversible, so a human confirms it (R6.6, R9.4).

1. **Preconditions**: clean tree on the release branch, `bash scripts/verify.sh` exits 0, CI green on the same commit, no `HARNESS_ALLOW_*` waivers in play.
2. **Scope the release**: `git log <last-tag>..HEAD --oneline`; group into breaking / features / fixes. Breaking changes require a migration note.
3. **Version** per the project's scheme (semver unless the repo says otherwise); update every file that carries it (grep for the old string).
4. **Changelog and notes**: user-facing language, link PRs or commits, call out migrations and config changes. Do not copy commit messages blindly.
5. **Build from a clean checkout** (fresh clone or worktree) and run the produced artifact once: smoke test the thing users will actually get.
6. **Data**: migrations reviewed, reversible or backed up, ordered with the code deploy. Never run destructive migrations without explicit approval.
7. **Rollout and rollback plan** in writing: how to detect failure (metric, log, health check), how to revert (previous artifact, `git revert`, migration down), who decides.
8. Stop and present: version, notes, artifact, plan, and the exact publish command. Run it only after the human says so. Never force-push or move published tags.
