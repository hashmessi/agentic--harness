#!/usr/bin/env bash
# Safe-autonomy primitives. Never modifies your branch, index, or stash list.
#   checkpoint.sh save [name]          snapshot the whole working tree (incl. untracked) under refs/harness/ckpt/
#   checkpoint.sh list                 show checkpoints
#   checkpoint.sh rollback <name> --yes   restore tracked+checkpointed files; snapshots the current state first
#   checkpoint.sh worktree <name>      isolated worktree + branch agent/<name> at .worktrees/<name>
#   checkpoint.sh budget <key> [max]   count an attempt; exit 3 once the retry budget (default 3) is spent
#   checkpoint.sh budget-reset <key>
set -euo pipefail
cmd="${1:-}"; [ $# -gt 0 ] && shift
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "checkpoint: not a git repository" >&2; exit 2; }
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
GD="$(git rev-parse --absolute-git-dir)"
valid() { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "checkpoint: name must match [A-Za-z0-9._-]+" >&2; exit 2; }; }

snapshot() { # prints the commit id of the current working tree, via a throwaway index
  local idx; idx="$(mktemp -u "$GD/harness-idx.XXXXXX")"
  local parent=(); git rev-parse -q --verify HEAD >/dev/null && parent=(-p "$(git rev-parse HEAD)")
  local tree; tree="$(GIT_INDEX_FILE="$idx" bash -c 'git add -A >/dev/null 2>&1; git write-tree')"
  rm -f "$idx"
  git -c user.name=harness -c user.email=harness@local commit-tree "$tree" "${parent[@]}" -m "harness checkpoint"
}

case "$cmd" in
  save)
    name="${1:-$(date +%Y%m%d-%H%M%S)}"; valid "$name"
    git update-ref "refs/harness/ckpt/$name" "$(snapshot)"
    echo "checkpoint saved: $name"
    ;;
  list)
    git for-each-ref --format='%(refname:strip=3)  %(creatordate:iso)' refs/harness/ckpt/ | sort
    ;;
  rollback)
    name="${1:-}"; valid "$name"; [ "${2:-}" = "--yes" ] || { echo "rollback restores files from '$name' and overwrites current edits. Re-run with --yes (a pre-rollback checkpoint is saved first)." >&2; exit 4; }
    git rev-parse -q --verify "refs/harness/ckpt/$name" >/dev/null || { echo "no such checkpoint: $name" >&2; exit 2; }
    git update-ref "refs/harness/ckpt/pre-rollback-$(date +%H%M%S)" "$(snapshot)"
    git restore --source="refs/harness/ckpt/$name" --worktree --staged -- .
    extra="$(git ls-files --others --exclude-standard | while read -r f; do git cat-file -e "refs/harness/ckpt/$name:$f" 2>/dev/null || echo "$f"; done)"
    echo "rolled back to: $name"
    [ -n "$extra" ] && { echo "files created after the checkpoint were left in place (delete by hand if unwanted):"; echo "$extra" | sed 's/^/  /'; }
    exit 0
    ;;
  worktree)
    name="${1:-}"; valid "$name"
    grep -qxF '.worktrees/' "$GD/info/exclude" 2>/dev/null || { mkdir -p "$GD/info"; echo '.worktrees/' >>"$GD/info/exclude"; }
    git worktree add -q ".worktrees/$name" -b "agent/$name"
    echo "worktree: $ROOT/.worktrees/$name (branch agent/$name). Remove: git worktree remove .worktrees/$name"
    ;;
  budget)
    key="${1:-}"; valid "$key"; max="${2:-3}"; f="$GD/harness/budget-$key"; mkdir -p "$GD/harness"
    n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$n" >"$f"
    if [ "$n" -gt "$max" ]; then echo "BUDGET EXHAUSTED: $key attempt $n > $max. Stop, report BLOCKED with evidence." >&2; exit 3; fi
    echo "attempt $n/$max for $key"
    ;;
  budget-reset) key="${1:-}"; valid "$key"; rm -f "$GD/harness/budget-$key"; echo "budget reset: $key" ;;
  *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
