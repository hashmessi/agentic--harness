# How to use the agentic workflow — simple steps

The workflow is already **on everywhere**. Claude Code, OpenCode and Antigravity load the rules globally in every folder.
Per project you only add one thing: the **verification gate** (`scripts/verify.sh`), so the agent can prove its work.

---

## A. Starting a NEW project

1. **Make the folder and turn on git** (the gate needs git):
   ```powershell
   mkdir C:\Users\Hashvanth\my-app
   cd C:\Users\Hashvanth\my-app
   git init
   ```
2. **Open your agent in that folder** (pick one):
   - Claude Code: `claude`
   - OpenCode: `opencode` (or open the folder in the OpenCode app)
   - Antigravity: File → Open Folder → `my-app`
3. **Tell it what to build.** First message, for example:
   > Set up the harness here, then build: a React + Vite app with a login page.

   The agent installs the gate itself, scaffolds the project, and verifies it.
4. **Commit when it reports `RESULT: PASS`:** say "commit this" (agents never commit unless you ask).

## B. Working on an EXISTING project

1. **Open your agent in the project folder:**
   ```powershell
   cd "C:\Users\Hashvanth\fitbridge V2\fitbridge"
   claude
   ```
2. **First time only — add the gate.** Say:
   > Set up the harness here and run a baseline check.

   It installs `scripts/verify.sh` and tells you what already passes or fails *before* any change.
   (Not a git repo yet? It will ask, or run `git init` yourself first.)
3. **Give tasks normally.** For anything non-trivial, use the full workflow:
   - Claude Code / OpenCode: `/ship add password reset to the login page`
   - Antigravity: `Follow the ship workflow in ~/.gemini/skills/ship/SKILL.md to: add password reset`
4. **Commit the gate once** so it travels with the project: "commit scripts/verify.sh".

From then on, every session in that folder just works — no setup.

---

## Everyday commands

| You want to… | Say / type |
|---|---|
| Do a feature or fix the full verified way | `/ship <task>` |
| Get a tough review of the changes | "review this with the hostile reviewer" (Claude Code) · `/hostile-review` skill |
| Run the checks yourself | `bash scripts/verify.sh` (Git Bash) — see note below for PowerShell |
| Keep code minimal (Claude Code only) | `/ponytail` · `/ponytail ultra` · `/ponytail off` |
| Review current diff the Ponytail way | `/ponytail-review` |
| Add a project-specific check (e2e, migrations…) | "add a verify.d check that runs our e2e tests" |

## Doing the setup by hand (optional)

The agent normally does this for you. If you want to run it yourself from the project folder:

- **Git Bash:**
  ```bash
  bash ~/agent-harness/bin/harness-init.sh
  bash scripts/verify.sh
  ```
- **PowerShell** — plain `bash` here starts WSL, not Git Bash, so call Git's bash directly:
  ```powershell
  & "C:\Program Files\Git\bin\bash.exe" "$HOME/agent-harness/bin/harness-init.sh"
  & "C:\Program Files\Git\bin\bash.exe" scripts/verify.sh
  ```

## Reading the result

- `RESULT: PASS` — every check passed. Safe to commit.
- `RESULT: FAIL` — the agent must fix it (it won't claim success). The failing check's last lines are printed.
- `RESULT: NO-CHECKS` — nothing to verify yet (e.g. empty folder). Add code or a `scripts/verify.d` check.
- `PASS WITH EXCEPTIONS` — something was skipped or waived. Treat as *not fully verified*.

## Changing the rules later

1. Edit `~/agent-harness/AGENTS.md` (engineering rules) or `REGULATIONS.md` (strict rules).
2. In Git Bash: `cd ~/agent-harness && bash scripts/verify.sh && bash bin/sync.sh`
3. New sessions in all three tools pick it up.
