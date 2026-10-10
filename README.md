# agent-harness

One agentic engineering workflow for every project and every agent CLI.
Built from: the global memory harness (`CLAUDE_GLOBAL_MEMORY_HARNESS.md`), the Brutal Product Building Execution Engine, and the 7-phase verified workflow (inspect → plan → implement → verify → debug → review → finalize).

**New here? Read [GUIDE.md](GUIDE.md)** — step-by-step for new and existing projects.

## Layout

| Path | Role |
|---|---|
| `AGENTS.md` | **Part I — the engineering contract** every agent loads (workflow, verification, engineering rules, profile). |
| `REGULATIONS.md` | **Part II — strict agent regulations** (R1–R12) distilled from the Claude Opus 5.5 / Fable 5 system prompts: trust boundary, hard limits, truth & evidence, files, tools, asking vs. acting, reporting, git, memory & privacy. Takes precedence over Part I. |
| `skills/ship/SKILL.md` | The workflow as an executable checklist (`/ship <task>`). |
| `skills/hostile-review/SKILL.md` | Adversarial read-only diff review. |
| `bin/verify.sh` | Universal verification engine (copied into each project as `scripts/verify.sh`). |
| `bin/harness-init.sh` | Put a project on the harness: installs `scripts/verify.sh`, LF rules. |
| `bin/sync.sh` | Distribute the harness to every CLI's global config (`--check` = drift report). |
| `hooks/verify-gate.mjs` | Claude Code Stop hook: blocks "done" while edited files are unverified. |
| `tests/selftest.sh`, `tests/safety.sh` | End-to-end tests (sandboxed; never touch real config). |
| `bin/repo-map.sh` | Deterministic repo discovery (stacks, commands, gate, CI, risk flags). |
| `bin/checkpoint.sh` | Checkpoint / rollback / worktree / retry budget. |
| `hooks/guard-bash.mjs` | Claude Code PreToolUse hook: asks a human before destructive commands. |
| `tests/eval/make-fixture.sh`, `EVAL.md` | Fixture repos for agent evals and the measured results. |

## Skills

| Skill | Use it for |
|---|---|
| `ship` | the whole workflow end to end (entry point) |
| `repo-intel` | learn an unfamiliar repo (`bin/repo-map.sh`) |
| `plan` | requirements lock + verifiable steps |
| `test-first` | tests that fail when behavior breaks (mutation check) |
| `debug` | root-cause loop with a mechanical retry budget |
| `refactor` | behavior-preserving change with a safety net |
| `perf` | measure, change one thing, re-measure |
| `security-audit` | boundary walk with exploit scenarios |
| `research` | sourced, current facts before relying on them |
| `release` | prepare a release; a human confirms publishing |
| `hostile-review` | adversarial diff review (read-only, fresh context) |
| `project-memory` | `.agent/` context, decisions, state, lessons (`harness-init.sh --memory`) |
| `safe-autonomy` | checkpoints, worktrees, retry budget, approval gates (`bin/checkpoint.sh`) |
| `frontend-craft`, `chart-craft`, `llm-apps` | domain craft, loaded before writing UI, charts, or model-API code |

Universal principles live in the skill text; tool-specific behavior lives only in `bin/sync.sh` (adapters) and `hooks/` (Claude Code enforcement).

## Safety controls

| Control | Mechanism | Enforced by |
|---|---|---|
| Unverified "done" | Stop hook runs the gate state check | Claude Code hook (hard) |
| Destructive/outward commands (force-push, `reset --hard`, `rm -rf` of root/home/`.`, `--no-verify`, `HARNESS_ALLOW_*`, publish, destructive SQL, pipe-to-shell) | `hooks/guard-bash.mjs` returns `ask` | Claude Code hook (hard); other CLIs: `safe-autonomy` rule |
| Weakened tests, suppressions, secrets | `scripts/verify.sh` guards | any CLI that runs the gate |
| Undo | `bin/checkpoint.sh save/rollback` (refs under `refs/harness/ckpt/`, never touches branch/index/stash) | any CLI |
| Parallel work | `bin/checkpoint.sh worktree <name>` | any CLI |
| Thrashing | `bin/checkpoint.sh budget <key> [max]`, exit 3 when spent | any CLI |

## Capability-based adapters

`sync.sh` is the adapter layer: it writes only what each CLI supports. Agents must degrade by capability, never assume a feature exists.

| Capability | Claude Code | OpenCode | Gemini CLI / Antigravity | If absent (fallback) |
|---|---|---|---|---|
| Global rules file | yes | yes | yes | read `~/agent-harness/AGENTS.md` + `REGULATIONS.md` directly |
| Skills | yes | yes | yes | read `~/agent-harness/skills/<name>/SKILL.md` directly |
| Subagents | yes (scout, implementer, hostile-reviewer) | reviewer only | no | do the role yourself in sequence; `hostile-review` skill as a fresh read of the diff |
| Hard hooks (Stop gate, command guard) | yes | no | no | run `bash scripts/verify.sh` before reporting; follow `safe-autonomy` rule 4 |
| Model routing (section 14) | per-subagent `model:` | manual | manual | use the strongest available model for plan/review/security |

## Where each CLI picks it up (written by `sync.sh`)

| CLI | Global rules | Skills | Reviewer subagent | Enforcement |
|---|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` | `~/.claude/agents/hostile-reviewer.md` | Stop hook in `~/.claude/settings.json` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/skills/` | `~/.config/opencode/agents/hostile-reviewer.md` + `/ship` command | instructions only |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` | `~/.gemini/skills/` | — (use `hostile-review` skill) | instructions only |

A new CLI that reads `AGENTS.md` needs one more `place` line in `bin/sync.sh`.

## Daily use

```bash
# in any repo, once (agents also do this themselves when a repo has no gate)
bash ~/agent-harness/bin/harness-init.sh
# the one verification command
bash scripts/verify.sh
# project-specific checks: scripts/verify.d/NN-name.sh (e2e, migrations, latency budgets...)
```

Then in any CLI: `/ship <task>` (Claude Code skill, OpenCode command) or ask the agent to use the `ship` skill.

## Changing the harness

1. Edit `AGENTS.md` / `REGULATIONS.md` / `skills/` / `bin/` / `hooks/`. (`sync.sh` distributes Part I + Part II as one file to each CLI.)
2. `bash scripts/verify.sh` — the harness runs its own gate (`scripts/verify.d/10-selftest.sh`).
3. `bash bin/sync.sh` — push to every CLI. `bash bin/sync.sh --check` shows drift.
4. Projects pick up a new `verify.sh` engine when you rerun `harness-init.sh` in them.

Every byte of `AGENTS.md` + `REGULATIONS.md` is loaded into every session in every CLI — keep the rules lean. (Codex is no longer a sync target; `~/.codex` is left as it was.)

## What the gate enforces

- Typecheck, lint, format check, tests, build — only what the repo configures; configured-but-missing tools **fail**.
- Test integrity: deleted test files, new skip/focus markers, net assertion removal.
- No unexplained lint/type suppressions (justify on the same line with `reason:` or ESLint's ` -- `).
- No secrets / `.env` / key files in the diff or untracked files (values are never echoed). Mark a test fixture line with `harness:allow-secret`.
- `NO-CHECKS` (exit 2) when nothing is verifiable — never a silent pass.
- Human-only overrides: `HARNESS_ALLOW_TEST_CHANGES=1`, `HARNESS_ALLOW_SUPPRESSIONS=1`, `VERIFY_SKIP=a,b`. Skips/waivers report `PASS WITH EXCEPTIONS` and do not satisfy the Stop gate.

## Known limits

- Hard enforcement (Stop hook) exists only in Claude Code; other CLIs follow the same rules as instructions.
- The Stop gate detects edits made with Edit/Write tools, not files changed via shell commands.
- Guards inspect the diff against the merge-base with `origin/HEAD|main|master`; work committed directly on `main` is only checked while uncommitted.
- Monorepo detection goes one directory deep; deeper packages need a `scripts/verify.d` check.
- Rust clippy runs at the repo's configured lint levels (warnings don't fail unless the repo denies them).
