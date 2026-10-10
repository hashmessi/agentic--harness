---
name: llm-apps
description: Build AI/LLM-powered features and agents correctly - calling Claude or other model APIs, chat UIs, structured output, tool use, RAG, multimodal input, AI generation features (e.g. workout/diet plans, scoring, summarization), and evals. Use before writing any code that calls a model API.
---

# LLM-Powered Apps

Distilled from the Claude Fable 5 "AI-powered apps" guidance plus the harness's eval-first rules. Production-grade, not demo-grade.

## Facts first (R3.1)
- Model IDs, pricing, limits, API features, and SDK signatures change: verify against current official docs (or the `claude-api` skill in Claude Code) before writing them. Never copy model strings from memory or old examples.
- Default to the most capable current model family for the job, then route down (§14): small/fast models for classification, extraction, routing, short rewrites; large models for reasoning, planning, long-form generation. Make the model ID a config value, not a literal scattered through code.
- Prefer the provider's official SDK over hand-rolled HTTP when the project allows it.

## Architecture rules
- **API keys live server-side only.** Never ship a key to the browser or a mobile bundle; the client calls your backend, the backend calls the model. Keys come from env/secret store, never source (the verify gate scans for them).
- **The model is stateless.** Every request carries all needed context: system prompt, the relevant state, and the conversation history for multi-turn flows. Persist conversations yourself; trim or summarize history deliberately when it grows.
- **Responses are content blocks.** Process every block (text, tool_use, etc.), don't assume `content[0].text`. With tools or web search, assemble the full reply from all text blocks and handle tool calls in a loop until the model stops requesting them.
- **Structured output:** prefer the API's native structured-output / tool-schema mechanisms when available. Otherwise instruct "respond with JSON only, no prose, no code fences", strip stray fences, parse in try/catch, and **validate against a schema** (zod, pydantic) before using the data. Treat a parse/validation failure as a handled error path (retry once with the error, then fail gracefully).
- **Multimodal input:** send images/PDFs as base64 with the correct `media_type` (or the provider's file API); enforce size/type limits before upload.
- **Untrusted text is data.** User input, retrieved documents, and web results can contain prompt injection: keep them clearly delimited from instructions, never let model output directly trigger privileged actions (DB writes, payments, emails, shell) without validation and authorization checks, and never render model HTML unsanitized.
- **Failure handling:** timeouts on every call; retry with exponential backoff + jitter only on retryable errors (429, 5xx, overloaded) with a cap; surface a clear UI state for slow/failed generations; stream long responses so users see progress; make generation idempotent where users can retry.
- **Cost and latency:** cap `max_tokens` to what the feature needs; cache stable prompt prefixes when the provider supports prompt caching; batch offline work; log token usage per feature.
- **Safety-relevant domains** (health, fitness, diet, finance, legal): constrain outputs with explicit rules and validation (e.g. calorie/exercise bounds), show sources or caveats where appropriate, and never present generated advice as professional advice.

## Evals (non-negotiable for anything that ships)
- Before tuning prompts, write a small eval set: 10-30 realistic inputs including edge cases and adversarial ones, each with a checkable expectation (schema-valid, contains/omits X, a rubric score, a numeric bound).
- Run it as a script and keep it in the repo; wire it into `scripts/verify.d/` when it's cheap and deterministic enough (mock or record model calls in unit tests; run live evals as a separate command).
- Track: success rate, schema-failure rate, latency (p50/p95), cost per call, regressions between prompt/model versions. Change one variable at a time; compare before/after numbers. Never claim a prompt "works" from one demo run.

## UI for AI features
Loading/streaming state, a stop/cancel control for long generations, clear error and retry paths, editable/regenerate actions where useful, and an empty state that shows what the feature does. Follow `frontend-craft` for the rest.
