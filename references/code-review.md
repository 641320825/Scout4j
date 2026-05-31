# Code Review / PR Review Checklist

Use for reviewing a diff, pull request, patch, or proposed implementation. Prefer findings over generic praise. If there are no material findings, say so and mention what was checked.

## Review order

1. Understand the intended behavior and affected entry points.
2. Inspect public API, persistence, transaction, async, and compatibility impact.
3. Compare tests against the risk surface.
4. Report issues by severity, with concrete file/line references when available.
5. Separate blocking defects from optional cleanup.

## What to check

### Correctness

- Does the implementation match the requirement and existing domain model?
- Are edge cases handled: nulls, empty collections, missing related records, invalid state, duplicates?
- Are state transitions guarded against already-done or stale inputs?
- Are errors handled consistently with nearby code?

### API and compatibility

- Are request/response DTOs, validation, serialization names, API docs, and clients consistent?
- Is the change backward compatible for older clients or old data?
- Are default values and omitted fields defined clearly?

### Persistence and data access

- Are entity/model fields, mapper/DAO queries, migrations, indexes, and converters aligned?
- Are pagination and limits present for unbounded reads?
- Watch for N+1 queries, accidental full-table scans, missing tenant/user filters, or soft-delete leaks.

### Transactions and consistency

- Is the transaction boundary explicit and small enough?
- Are DB writes, emitted events/messages, cache updates, and read-model updates ordered safely?
- Could retries, duplicate messages, or partial failures corrupt state?
- For detailed checks, read `transactions.md`.

### Security and privacy

- Check authentication and authorization at the correct boundary.
- Watch for injection risks, unsafe deserialization, path traversal, SSRF, insecure logging, and secret leakage.
- Do not include private business details or credentials in review output.

### Performance and operability

- Are expensive calls batched, cached, paginated, or guarded by limits?
- Are pagination/sorting/index choices safe for expected data size? For details, read `performance.md`.
- Are downstream timeouts/retries/fallbacks safe and bounded? For details, read `rpc-dependency.md`.
- Are logs useful without being noisy or sensitive?
- Are metrics/traces/dead-letter handling present where the project convention expects them?

### Tests

- Do tests cover happy path, invalid input, boundary cases, idempotency, rollback/partial failure, and old-data compatibility where relevant?
- Are tests deterministic and aligned with existing style?

## Reporting format

Use this structure unless the user asks otherwise:

```text
Findings
- [High|Medium|Low] <issue> — <why it matters> (<file:line>)

Questions / assumptions
- <only if needed>

Verification reviewed
- <tests, commands, or files checked>
```

Avoid rewriting large patches in the review unless the user asks for implementation help.
