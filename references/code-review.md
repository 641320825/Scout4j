# Code Review / PR Review Checklist

Use for reviewing a diff, pull request, patch, or proposed implementation. Prefer findings over generic praise. If there are no material findings, say so and mention what was checked.

Active Review Mode is the fast path for requested diff/commit reviews; the later checklist sections are the broader menu to draw from when the change touches those areas.

## Active Review Mode

Use this mode when the user asks to review a Java backend diff, audit staged changes, check a commit, or run a pre-submit review. This is a repository-first review workflow, not a built-in slash command.

### Review scope

Choose the smallest requested scope:

- staged changes: inspect `git diff --cached`;
- current working tree: inspect `git diff HEAD`;
- a named commit or range: inspect `git show <commit>` or `git diff <range>`;
- a named file: inspect the file diff and nearby code needed to understand it.

If the diff is large, first summarize changed files and ask whether to review all of it or focus on risky areas. Do not review unrelated existing code as if it were introduced by the diff.

### High-risk checks

Prioritize these common Java enterprise backend risks. Apply checks only when the repository uses the relevant technology or the diff shows the relevant pattern. Treat clear violations as blockers unless local repository conventions prove otherwise:

- **Transaction boundary:** transactional work should run through the real framework boundary. When Spring-managed transactions are in use, watch for private methods, self-invocation, premature state progress, and unclear rollback behavior.
- **Commit ordering:** messages, events, callbacks, index updates, or success signals should not observe uncommitted DB state unless an explicit after-commit/outbox/idempotent recovery pattern exists.
- **Persistence contract:** repository/DAO/mapper signatures, query definitions, result mappings, entities, and tests should change together. If MyBatis is used, check stable `@Param` names and XML/annotation SQL consistency.
- **Cursor / pagination:** cursor fields, sort order, predicates, tie-breakers, and tests should describe one consistent contract.
- **Idempotency / retry:** duplicate delivery, retries, partial success, and reruns should converge to one business result; comments alone do not implement idempotency.
- **Remote dependency behavior:** timeouts, retries, fallback, and failure propagation should be bounded and visible to callers.
- **Data repair / backfill safety:** dry-run/apply parity, batching, resumability, auditability, and safe retry behavior should be explicit.
- **Verification quality:** tests should execute the real path and fail on the protected invariant; placeholder helpers or always-true assertions are not proof.
- **Change focus:** broad helper classes, unrelated rewrites, or compatibility-breaking API removals need an explicit reason.

### Semantic proof

For each non-trivial write path or consistency-sensitive change, ask three questions:

1. **Invariant:** what must remain true after success, retry, rollback, partial failure, and rerun?
2. **Enforcement:** which production code path enforces it, such as transaction boundary, lock, SQL predicate/order, idempotency key, outbox, or failure propagation?
3. **Proof:** which test, dry-run/apply parity check, or executable assertion would fail if the invariant broke?

If the diff cannot answer these questions, mark it as a risk and recommend the smallest project-native fix.

### Active Review report format

Use this concise format when the user asks for an active or pre-submit review:

```markdown
## Scout4j Active Review

Scope: <diff / staged / commit / files>
Repository signals: <Spring/MyBatis/MQ/etc. only when observed; omit when none are relevant>

### Findings
- ❌ BLOCKER: <issue, location, why it matters, recommended fix>
- ⚠️ RISK: <uncertain or unproven invariant, suggested evidence/fix>
- ✅ OK: <important risky area checked and found acceptable>

### Semantic proof
- Invariant: <...>
- Enforcement: <...>
- Proof: <...>

Conclusion: <pass / pass with risks / block>
```

Report actual evidence from the diff and nearby code. Do not present generic checklist items as findings.

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
