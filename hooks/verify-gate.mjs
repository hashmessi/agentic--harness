#!/usr/bin/env node
// Claude Code Stop hook — refuses to let the agent finish while files it edited in a git repo
// have not passed `bash scripts/verify.sh` in their current state.
//
// Passes when: the agent edited nothing in this repo, the tree equals HEAD, the tree hash matches the
// stamp written by a fully passing verify.sh, this is already a re-prompted stop (stop_hook_active),
// or HARNESS_SKIP_GATE=1. Blocks (exit 2, reason on stderr) otherwise.
import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync, realpathSync, rmSync } from "node:fs";
import { basename, dirname, join } from "node:path";

const EDIT_TOOLS = new Set(["Edit", "Write", "MultiEdit", "NotebookEdit"]);

function git(cwd, args, env) {
  return execFileSync("git", args, {
    cwd,
    env: env ? { ...process.env, ...env } : process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  }).trim();
}

// Canonical form for comparing paths: resolves symlinks and Windows 8.3 short names (HASHVA~1 vs Hashvanth)
// through the nearest existing ancestor, so deleted files still compare correctly.
function canonical(p) {
  let head = String(p), tail = "";
  while (!existsSync(head)) {
    const parent = dirname(head);
    if (parent === head) break;
    tail = "/" + basename(head) + tail;
    head = parent;
  }
  try { head = realpathSync.native(head); } catch { /* keep as given */ }
  const s = (head + tail).replace(/\\/g, "/").replace(/\/+$/, "");
  return process.platform === "win32" ? s.toLowerCase() : s;
}

// Same algorithm as tree_hash() in verify.sh: hash the full working tree through a throwaway index.
export function treeHash(root, gitDir) {
  mkdirSync(join(gitDir, "harness"), { recursive: true });
  const tmp = join(gitDir, "harness", `index.${process.pid}`);
  try {
    if (existsSync(join(gitDir, "index"))) copyFileSync(join(gitDir, "index"), tmp);
    git(root, ["add", "-A", "--", "."], { GIT_INDEX_FILE: tmp });
    return git(root, ["write-tree"], { GIT_INDEX_FILE: tmp });
  } finally {
    rmSync(tmp, { force: true });
  }
}

function editedInside(transcriptPath, root) {
  if (!transcriptPath || !existsSync(transcriptPath)) return false;
  const prefix = canonical(root) + "/";
  const seen = new Map();
  for (const line of readFileSync(transcriptPath, "utf8").split("\n")) {
    if (!line.includes("tool_use")) continue;
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    const content = entry?.message?.content;
    if (!Array.isArray(content)) continue;
    for (const block of content) {
      if (block?.type !== "tool_use" || !EDIT_TOOLS.has(block.name)) continue;
      const file = block.input?.file_path ?? block.input?.notebook_path;
      if (!file) continue;
      if (!seen.has(file)) seen.set(file, canonical(file).startsWith(prefix));
      if (seen.get(file)) return true;
    }
  }
  return false;
}

function main(input) {
  if (input.stop_hook_active || process.env.HARNESS_SKIP_GATE === "1") return 0;
  const cwd = input.cwd || process.cwd();
  let root, gitDir;
  try {
    root = git(cwd, ["rev-parse", "--show-toplevel"]);
    gitDir = git(cwd, ["rev-parse", "--absolute-git-dir"]);
  } catch {
    return 0; // not a git repo — nothing to gate
  }
  if (!editedInside(input.transcript_path, root)) return 0;

  if (!existsSync(join(root, "scripts", "verify.sh"))) {
    process.stderr.write(
      "Harness gate: you edited files in a repo with no verification gate. Run " +
        "`bash ~/agent-harness/bin/harness-init.sh` in the repo root, then `bash scripts/verify.sh`, fix failures, " +
        "and report the results. If verification is genuinely not applicable, say so explicitly and report status UNVERIFIED.\n",
    );
    return 2;
  }

  const tree = treeHash(root, gitDir);
  let head = null;
  try { head = git(root, ["rev-parse", "HEAD^{tree}"]); } catch { /* unborn branch */ }
  if (tree === head) return 0;

  const stampFile = join(gitDir, "harness", "verify-stamp");
  const stamp = existsSync(stampFile) ? readFileSync(stampFile, "utf8").trim() : "";
  if (stamp === tree) return 0;

  process.stderr.write(
    "Harness gate: the working tree changed since the last fully passing `bash scripts/verify.sh`. " +
      "Run it now, fix any failures (root cause, never by weakening tests or adding suppressions), rerun until it passes, " +
      "then report with exact results. If it cannot pass, report status BLOCKED with the failing output instead of claiming success.\n",
  );
  return 2;
}

let raw = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  let input = {};
  try { input = raw.trim() ? JSON.parse(raw) : {}; } catch { /* malformed input: fail open */ }
  let code = 0;
  try { code = main(input); } catch (e) {
    process.stderr.write(`verify-gate: internal error, not blocking: ${e?.message ?? e}\n`);
  }
  process.exit(code);
});
