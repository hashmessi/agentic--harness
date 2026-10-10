---
name: security-audit
description: Security review of code, a diff, or a feature for injection, authn/authz, secrets, input validation, dependency and data-exposure risks. Use for auth, payments, file upload, user data, LLM or agent tool use, public endpoints, or when asked to "audit", "harden", "threat model" or "is this safe".
---

# Security Audit

Authorized, defensive work on code the user owns. Read-only unless asked to fix.

1. **Scope and assets**: what is protected (accounts, PII, money, keys, infra), who the attackers are, where trust boundaries sit (client to server, service to service, user content to shell/SQL/HTML/prompt).
2. **Walk the boundaries** with this checklist; each hit needs a concrete exploit scenario (input, state, result), else drop it:
   - Authn/authz: missing checks, IDOR, role confusion, client-only validation, JWT/session handling.
   - Injection: SQL, shell, path traversal, template, SSRF, XSS, prompt injection into tools.
   - Secrets: in code, logs, errors, client bundles, git history (`git log -p -S`), `.env` tracked.
   - Data: over-broad queries, missing row-level policies (Supabase/Postgres), PII in logs, no retention limit.
   - Abuse: no rate limit, unbounded upload/regex/loop, replayable or non-idempotent actions, race conditions.
   - Supply chain: new dependencies (verify package, maintainer, version), install scripts, unpinned CI actions.
   - Agent/LLM: tool permissions wider than needed, untrusted content treated as instructions, no human gate on destructive tools.
3. Run available tools only if the repo configures them (`npm audit`, `pip-audit`, `cargo audit`, semgrep). Report unavailable ones as not run.
4. **Report** ranked by exploitability x impact: finding, `file:line`, scenario, minimal fix. Mark each CONFIRMED (reproduced or traced end to end) or PLAUSIBLE.
5. Never write exploits for systems the user does not own (R2.1). Never echo secret values; name the location only.
