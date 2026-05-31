# Skill Benchmark Cases

This file is for skill regression/self-check only. Do not load it during normal Java implementation work unless the user explicitly asks to benchmark, audit, or improve this skill.

Use these cases to validate whether the skill is effective for real Java enterprise backend work. For each case, check whether the agent loads the right reference file(s), asks only necessary clarifying questions, proposes a safe plan when needed, and reports verification honestly.

## Case 1: Add response field

Prompt: "Add `fooStatus` to this API response."

Expected references: `add-field.md`, possibly `compatibility-rollout.md`, `testing.md`.

Expected checks: DTO, converter/mapper, source model, old data/default behavior, serialization name, tests.

Unacceptable mistakes: only editing DTO; not checking converter; making field required without confirmation.

## Case 2: Add DB-backed field

Prompt: "Persist a new field and expose it in the detail endpoint."

Expected references: `add-field.md`, `compatibility-rollout.md`.

Expected checks: schema/migration, entity/model, mapper/DAO, DTO, converter, backfill/default, rollback/mixed deployment.

Unacceptable mistakes: schema-only or code-only change; no old-data handling.

## Case 3: Fix duplicate MQ processing

Prompt: "This consumer processes some messages twice; make it safe."

Expected references: `mq-consumer.md`, `transactions.md`, `testing.md`.

Expected checks: message ID/business key, state pre-check, processed-message table or unique constraint if project convention supports it, retry semantics, duplicate test.

Unacceptable mistakes: in-memory dedupe only; swallowing failures without observability.

## Case 4: Review DB write + event publishing

Prompt: "Review this PR that writes an order and publishes an event."

Expected references: `code-review.md`, `transactions.md`, possibly `rpc-dependency.md`.

Expected checks: event after commit/outbox, rollback behavior, duplicate consumer safety, partial failure handling.

Unacceptable mistakes: saying it is safe because both lines are in one method.

## Case 5: Slow list query

Prompt: "This list endpoint is slow; refactor it to cursor pagination."

Expected references: `performance.md`, `compatibility-rollout.md`, `testing.md`.

Expected checks: stable sort with unique tie-breaker, index alignment, page size limit, old-client behavior, tests for boundary cursor.

Unacceptable mistakes: cursor based only on non-unique timestamp; changing default page behavior silently.

## Case 6: Data repair job

Prompt: "Repair incorrect status values for existing records."

Expected references: `data-repair.md`, `transactions.md`, `performance.md`.

Expected checks: dry-run, feature flag/enable switch, compare-before-write, bounded batches, resumability, summary metrics, no unintended side effects.

Unacceptable mistakes: unbounded update; no dry-run; triggering normal business side effects unintentionally.

## Case 7: RPC timeout/retry bug

Prompt: "A downstream service times out sometimes; add retry."

Expected references: `rpc-dependency.md`, `transactions.md`, `testing.md`.

Expected checks: idempotency of retried operation, bounded retry/backoff, timeout, business vs transport failure, transaction boundary.

Unacceptable mistakes: blindly retrying side-effecting call; remote call inside long DB transaction.

## Case 8: Permission or tenant leak

Prompt: "Users can see records they should not see; fix the query."

Expected references: `bugfix.md`, `code-review.md`, `testing.md`.

Expected checks: auth boundary, tenant/user/org filters, soft-delete filters, repository methods, tests for cross-tenant/user access.

Unacceptable mistakes: filtering only in controller after data was already fetched broadly; no negative authorization test.

## Case 9: Refactor service method

Prompt: "Clean up this large service method without changing behavior."

Expected references: `refactor.md`, `testing.md`.

Expected checks: establish current behavior, separate mechanical refactor from behavior change, preserve public API, run before/after tests if practical.

Unacceptable mistakes: mixing feature changes into refactor; deleting edge-case handling without tests.

## Case 10: Mapper/converter omission

Prompt: "Why is the new field always null in the response?"

Expected references: `bugfix.md`, `add-field.md`.

Expected checks: persistence read path, mapper XML/annotations, converter/assembler, DTO serialization, old data/defaults, regression test.

Unacceptable mistakes: only checking DB column; assuming compilation catches mapper omissions.

## Additional Benchmark Dimensions

### DB/MQ/event chains
Must inspect both consumer idempotency and producer transaction boundary. A delayed message or event sent before DB commit can survive rollback unless the project uses after-commit hooks, outbox, or equivalent safeguards.

### Permission work
Classify functional permission vs data permission before editing. Functional permission follows menu/role/permission-code/cache/session paths; data permission follows SQL/mapper/data-scope injection and needs negative cross-tenant/user tests.

### Scheduler/command idempotency
Is multi-window: before submit, after command insert, after scheduler pickup, while instance is running, and during retry/failure recovery. Do not rely only on API-layer running-instance checks or in-memory locks.

### Config/publishing systems
Distinguish server-side write success from client-visible success. Trace persistence, cache invalidation, notification/long-polling, cluster propagation, version history, and failure compensation.

### BPM/workflow engines
Must not be reduced to a single status update. Review runtime projection, history/audit projection, listeners/jobs, side effects, optimistic locking, and async execution windows together.

### High-throughput IoT/telemetry chains
Need early checks for tenant/device identity, partitioning/backpressure, batching, out-of-order or duplicate messages, and rule-chain side-effect observability.

### Derived projections
For fields that enter search indexes, caches, read models, or analytics tables, add-field planning must include projection mapping plus rebuild/reindex/backfill and compatibility for old data.

## Fixture Verification

Prefer real project verification: Maven/Gradle targeted tests, then `javac` compile, then static contract tests only as an explicit fallback. Report the actual verification layer used; do not describe static contract checks as compilation or unit-test success.

For patch-based fixtures, verify both directions:

```bash
git apply --check <patch>
git apply <patch>
git apply -R --check <patch>
git apply -R <patch>
```

Keep fixtures small and reversible; do not keep large benchmark clones in the workspace.

## Plan/Patch Split Benchmark Additions

- Split Java workflow benchmarks into two layers: plan scoring for risk/checklist coverage, and patch scoring for diff applicability plus semantic contracts.
- Do not treat patch formatting failures as the only signal of workflow value; report plan deltas separately.
- Patch prompts should force small diffs, exact paths, existing-file edits, and valid applyable hunks; record whether `git apply --check` or `git apply --recount` was needed.
- For generated patches, verify both forward and reverse application when practical, and keep fixtures small enough to review manually.

## Benchmark failure archive: checklist overfit gates

These cases are for benchmark/debug work only. Do not load this file during normal startup unless the task is to tune or audit this skill.

### Regression pattern: cursor contract checklist overfit

Symptom:
- A workflow-assisted patch reached full mechanical rule coverage but reviewed worse than a simpler baseline.
- The model learned to mention cursor concerns without preserving a coherent implementation contract.

Bad patterns observed:
- Split cursor contract: passing both a cursor object and separate cursor fields such as timestamp/id through service, mapper, and SQL.
- Mapper/API drift: Java signatures, MyBatis XML/annotation parameter names, and tests were not aligned around one binding shape.
- Weak tests: placeholder helpers returned empty data, or tests did not exercise the real mapper/service path that should enforce the resume invariant.
- SQL/test mismatch: expected ordering risked contradicting the actual `ORDER BY`, especially with equal timestamps or tie-breakers.
- Compatibility risk: cursor constructors/factory methods were changed without preserving initial-page compatibility or hidden-call-site behavior.
- Sentinel-first-page risk: first-page handling used sentinel cursor values instead of nullable cursor/dynamic SQL without proving that this matched project convention.

Hard gate to apply:
- If any of the above appears in a patch, reject the patch and rewrite it. Do not accept prose explanations that merely name keyset pagination, tie-breakers, or high-water marks.

### Regression pattern: dry-run batch repair became non-executable

Symptom:
- A workflow-assisted patch regressed to non-executable while a simpler baseline remained executable.

Bad patterns to check before finalizing similar changes:
- Large rewrites or helper invention that bypass the existing dry-run/apply structure.
- Dry-run and apply paths no longer share the same candidate selection logic.
- Tests or verification do not execute both modes against the same inputs.
- Patch cannot apply/compile, but final answer still describes intended behavior as if implemented.

Hard gate to apply:
- If the patch is not executable/applicable, stop and fix that before discussing semantic quality. Non-executable enterprise patches are automatic failures.
