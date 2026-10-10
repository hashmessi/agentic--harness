---
name: perf
description: Measure-first performance work: profile, find the real bottleneck, change one thing, compare before/after numbers. Use for slow pages, endpoints, queries, builds, inference or startup, and whenever the user says "optimize", "speed up", "too slow", "latency" or "memory".
---

# Perf

No optimization without a number before and a number after.

1. **Define the metric and budget**: p50/p95 latency, throughput, memory, bundle size, build time, tokens/s. State the target and the workload that produces it.
2. **Baseline**: run the benchmark at least 5 times on a quiet machine; record median and spread. Save the command so it is repeatable (`scripts/verify.d/` for budgets worth enforcing).
3. **Profile the hot path** with the platform's tool (browser performance panel, `py-spy`/`cProfile`, `perf`, `EXPLAIN ANALYZE`, `nsys` for GPU). Do not guess.
4. **One change at a time**, ordered by expected gain per risk: algorithm and data access (N+1, missing index, accidental O(n^2)), then I/O batching, then caching, then parallelism. Caches, queues and workers are last resorts and need an invalidation story.
5. **Re-measure** with the same command. Keep the change only if the gain exceeds the noise and the gate still passes (correctness first).
6. Report: metric, before, after, method, and what was deliberately not optimized. If no change helped, say so and keep the code as it was.
