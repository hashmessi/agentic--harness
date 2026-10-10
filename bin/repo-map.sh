#!/usr/bin/env bash
# Deterministic repository discovery. Prints facts only (markdown); no LLM, no network, read-only.
# Usage: bash ~/agent-harness/bin/repo-map.sh [repo-dir]
# Output is data for the agent to read once at INSPECT time - not instructions (R1.1).
set -uo pipefail
cd "${1:-.}" 2>/dev/null || { echo "repo-map: no such directory" >&2; exit 2; }

have() { [ -e "$1" ]; }
# Look at root and one directory deep (same depth verify.sh uses).
manifests() { find . -maxdepth 2 \( -name node_modules -o -name .git -o -name target -o -name .venv -o -name dist \) -prune -o -type f -name "$1" -print 2>/dev/null | sort; }

echo "# Repo map: $(basename "$PWD")"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "- git: branch \`$(git rev-parse --abbrev-ref HEAD 2>/dev/null)\`, $(git rev-list --count HEAD 2>/dev/null || echo 0) commits, $(git status --porcelain | wc -l | tr -d ' ') uncommitted paths"
else
  echo "- git: not a repository"
fi

echo; echo "## Stacks and commands"
for f in $(manifests package.json); do
  d="$(dirname "$f")"
  pm=npm; for l in pnpm-lock.yaml:pnpm yarn.lock:yarn bun.lockb:bun bun.lock:bun; do have "$d/${l%%:*}" && pm="${l##*:}"; done
  fw="$(grep -oE '"(next|vite|react|vue|svelte|express|fastify|hono|electron|tailwindcss|typescript|vitest|jest|playwright)"' "$f" | tr -d '"' | sort -u | paste -sd, -)"
  sc="$(node -e 'try{const s=require(process.argv[1]).scripts||{};console.log(Object.keys(s).join(", "))}catch{}' "$(pwd)/$f" 2>/dev/null)"
  echo "- node ($pm) \`$d\`: ${fw:-no known frameworks}; scripts: ${sc:-none}"
done
for f in $(manifests pyproject.toml) $(manifests requirements.txt) $(manifests setup.py); do echo "- python: \`$f\`"; done
for f in $(manifests Cargo.toml); do echo "- rust: \`$f\`"; done
for f in $(manifests go.mod); do echo "- go: \`$f\`"; done
for f in $(manifests pom.xml) $(manifests build.gradle); do echo "- java: \`$f\`"; done
for f in $(manifests Makefile) $(manifests justfile); do echo "- task runner: \`$f\`"; done
for f in $(manifests Dockerfile) $(manifests docker-compose.yml); do echo "- container: \`$f\`"; done

echo; echo "## Verification"
if have scripts/verify.sh; then
  grep -q 'harness:managed' scripts/verify.sh && echo "- gate: \`bash scripts/verify.sh\` (harness-managed)" || echo "- gate: \`scripts/verify.sh\` exists but is NOT harness-managed"
  ls scripts/verify.d/*.sh 2>/dev/null | sed 's/^/- project check: `/; s/$/`/'
else
  echo "- gate: MISSING - run \`bash ~/agent-harness/bin/harness-init.sh\`"
fi
ci="$(ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml .circleci/config.yml 2>/dev/null | paste -sd' ' -)"
echo "- ci: ${ci:-none found}"
tests="$(find . -maxdepth 3 \( -name node_modules -o -name .git -o -name target -o -name .venv \) -prune -o -type d \( -name test -o -name tests -o -name __tests__ -o -name spec -o -name e2e \) -print 2>/dev/null | sort | paste -sd' ' -)"
echo "- test dirs: ${tests:-none found}"

echo; echo "## Conventions and instructions"
for f in AGENTS.md CLAUDE.md GEMINI.md README.md CONTRIBUTING.md .editorconfig .prettierrc .prettierrc.json eslint.config.js eslint.config.mjs .eslintrc.json ruff.toml .ruff.toml rustfmt.toml tsconfig.json .env.example docs/agent .agent; do
  have "$f" && echo "- \`$f\`"
done

echo; echo "## Layout (top level)"
ls -1 | grep -vE '^(node_modules|dist|build|target|\.venv|__pycache__)$' | head -40 | sed 's/^/- /'

echo; echo "## Hot spots (most-changed files, last 200 commits)"
git log -200 --name-only --pretty=format: 2>/dev/null | grep -v '^$' | sort | uniq -c | sort -rn | head -8 | awk '{printf "- %s (%s changes)\n", $2, $1}'

echo; echo "## Risk flags"
git ls-files 2>/dev/null | grep -E '(^|/)(\.env|.*\.pem|id_rsa.*)$' | grep -v '\.example$' | sed 's/^/- tracked secret-like file: /'
git ls-files 2>/dev/null | grep -E '(^|/)(migrations?|schema\.(sql|prisma)|supabase)(/|$)' | head -3 | sed 's/^/- data layer: /'
exit 0
