#!/usr/bin/env bash
# Install (or update) the harness verification gate into a project.
# Usage: bash ~/agent-harness/bin/harness-init.sh [--memory] [repo-dir]   (default: the git repo containing the cwd)
#   --memory  also scaffold .agent/{CONTEXT,DECISIONS,STATE,LESSONS}.md (see the project-memory skill); never overwrites.
# Idempotent. Never overwrites a scripts/verify.sh that the harness does not manage.
set -euo pipefail

HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEMORY=0; [ "${1:-}" = "--memory" ] && { MEMORY=1; shift; }
TARGET="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$TARGET"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || echo "warning: $TARGET is not a git repository; guards and the stop-gate need git (run 'git init')." >&2

mkdir -p scripts/verify.d
if [ -f scripts/verify.sh ] && ! grep -q 'harness:managed' scripts/verify.sh; then
  echo "scripts/verify.sh exists and is not harness-managed — left untouched." >&2
  echo "Move its project-specific checks into scripts/verify.d/*.sh, delete it, and rerun to adopt the harness gate." >&2
  exit 1
fi
if cmp -s "$HARNESS/bin/verify.sh" scripts/verify.sh 2>/dev/null; then
  echo "scripts/verify.sh: up to date"
else
  cp "$HARNESS/bin/verify.sh" scripts/verify.sh
  chmod +x scripts/verify.sh
  echo "scripts/verify.sh: installed"
fi

# Keep shell scripts LF on Windows checkouts, or bash fails on \r.
if ! grep -qxF 'scripts/*.sh text eol=lf' .gitattributes 2>/dev/null; then
  printf '%s\n' 'scripts/*.sh text eol=lf' 'scripts/verify.d/*.sh text eol=lf' >>.gitattributes
  echo ".gitattributes: LF rule added for scripts/*.sh"
fi

if [ "$MEMORY" = 1 ]; then
  mkdir -p .agent
  seed() { if [ -e ".agent/$1" ]; then echo ".agent/$1: kept"; else printf '%s\n' "$2" >".agent/$1"; echo ".agent/$1: created"; fi; }
  seed CONTEXT.md   $'# Context (cap 80 lines)\nArchitecture, boundaries, invariants, integrations: only what the code cannot show.'
  seed DECISIONS.md $'# Decisions (append-only, newest first)\n<!-- YYYY-MM-DD | decision | why | alternatives rejected -->'
  seed STATE.md     $'# State (cap 40 lines, overwritten each session)\nGoal:\nDone:\nNext:\nVerify with:\nOpen risks:'
  seed LESSONS.md   $'# Lessons (a mistake made twice -> the rule that prevents it; 1-3 lines each)'
fi

echo "Done. Add project-specific checks as scripts/verify.d/NN-name.sh, then run: bash scripts/verify.sh"
