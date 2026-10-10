#!/usr/bin/env node
// Claude Code PreToolUse hook (matcher: Bash) - sends destructive or gate-bypassing commands to the human
// for approval instead of running them. It asks; it never silently allows or silently blocks.
// Patterns are deliberately narrow so normal work is not interrupted.
import { readFileSync } from "node:fs";

const RULES = [
  [/\bgit\s+push\b[^|;&\n]*(--force\b|--force-with-lease\b|\s-f\b|\s\+\S)/, "force-push rewrites remote history"],
  [/\bgit\s+push\b[^|;&\n]*\s(main|master)\b/, "push to main/master"],
  [/\bgit\s+reset\s+--hard\b/, "git reset --hard discards uncommitted work"],
  [/\bgit\s+clean\b[^|;&\n]*-\w*[fd]/, "git clean deletes untracked files"],
  [/\bgit\s+(checkout|restore)\b[^|;&\n]*\s--\s+\.(\s|$)/, "discards all uncommitted changes"],
  [/\bgit\s+branch\s+-D\b/, "force-deletes a branch"],
  [/--no-verify\b|--no-gpg-sign\b|commit\.gpgsign=false/, "bypasses git hooks/signing (R9.2)"],
  [/\bHARNESS_ALLOW_(TEST_CHANGES|SUPPRESSIONS)\s*=\s*1|\bVERIFY_SKIP\s*=|\bHARNESS_SKIP_GATE\s*=\s*1/, "human-only gate override (AGENTS.md section 2)"],
  [/\brm\s+(-\w*\s+)*-\w*[rR]\w*\s+(-\w+\s+)*(\/|~|\$HOME|\.|\*|\.\.|[A-Za-z]:[\\/]?)(\s|$|\*)/, "recursive delete of a root, home, or the working tree"],
  [/\b(Remove-Item|rm)\b[^|;&\n]*-Recurse\b[^|;&\n]*(\s[A-Za-z]:\\?(\s|$)|\s~|\s\$HOME)/i, "recursive delete of a drive or home"],
  [/\b(drop\s+(table|database)|truncate\s+table)\b/i, "destructive SQL"],
  [/\b(curl|wget|iwr|Invoke-WebRequest)\b[^|\n]*\|\s*(sudo\s+)?(ba|z)?sh\b/i, "pipes a download into a shell"],
  [/\b(npm|pnpm|yarn)\s+publish\b|\bcargo\s+publish\b|\btwine\s+upload\b|\bgh\s+release\s+create\b/, "publishes a release (R9.4)"],
];

export function check(command) {
  for (const [re, why] of RULES) if (re.test(command)) return why;
  return null;
}

if (process.argv[1]?.endsWith("guard-bash.mjs")) {
  let input = {};
  try { input = JSON.parse(readFileSync(0, "utf8")); } catch { process.exit(0); } // unparseable -> do not interfere
  const command = String(input?.tool_input?.command ?? "");
  const why = check(command);
  if (why) {
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: `Harness guard: ${why}. Needs explicit human approval.`,
      },
    }));
  }
  process.exit(0);
}
