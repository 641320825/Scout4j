# Transaction Boundaries and Consistency

Use when a change touches writes, state transitions, messages/events, async work, cache/search updates, retries, or rollback behavior.

## Core checks

- Identify where the transaction begins and ends.
- Keep transactions small: avoid remote calls, slow loops, file I/O, and user interaction inside DB transactions.
- Confirm rollback rules for checked exceptions, runtime exceptions, and caught exceptions.
- Make retries safe with idempotency keys, uniqueness constraints, or state pre-checks.
- Define behavior for partial failure: retry, compensate, skip, dead-letter, or manual repair.

## Spring-specific reminders

- `@Transactional` on self-invoked methods usually does not take effect through the proxy.
- `private` methods and some final/proxy-unfriendly patterns may not be transactional depending on configuration.
- `readOnly = true` is not a security boundary; it is an optimization/hint and may affect flush behavior.
- Be explicit about propagation (`REQUIRED`, `REQUIRES_NEW`, `NESTED`) only when the existing default is insufficient.
- For event listeners, distinguish immediate event handling from after-commit handling.

## Spring proxy realism

In Spring proxy-based transaction management, `@Transactional` is not a magic marker on any method. Before claiming a transaction-boundary fix, verify the annotation will actually be intercepted:

- Do not put `@Transactional` on `private` methods and do not rely on self-invocation from another method in the same class; proxy advice normally will not run.
- Do not create an `@Transactional` collaborator with method-local `new` inside the caller. That behaves like self-invocation: the proxy is never built around the object, so the annotation is inert. The collaborator must be injected, an existing bean, or held as a field supplied through construction.
- A valid transactional write boundary must be externally reachable/interceptable: an injected collaborator, existing proxied service/repository boundary, or a project-native transaction template. If the orchestrating method still writes directly through a repository/DAO instead of invoking that seam, the boundary fix is incomplete.
- Prefer one of these real shapes:
  - move the DB write into a separate injected collaborator/bean with a public/package-visible transactional method;
  - use an existing proxied service/repository method that already owns the write transaction;
  - use `TransactionTemplate` if the project already uses programmatic transactions.
- In small projects where adding a Spring container is impossible, still avoid private self-invoked `@Transactional`; model the boundary as a separate collaborator or clearly use an explicit transaction template abstraction.
- Tests should not merely assert an annotation exists. They should verify the orchestration calls the transactional collaborator only after the remote call succeeds, that no DB write occurs after retry exhaustion, and that the final transport failure is surfaced with the caller-visible exception contract when the API already exposes one.

## DB write + message/event consistency

When a service writes DB state and emits a message/event:

- Prefer after-commit publication, an outbox pattern, or a project-local equivalent when consistency matters.
- If using an outbox, write business state and outbox record in the same DB transaction; expect the relay may publish more than once, so consumers still need idempotency.
- Avoid publishing a success event before the database commit is durable.
- If a message may be delivered twice, the consumer must be idempotent.
- If DB commit succeeds but message publishing fails, define how the system catches up.

## Batch writes and data repair

- Use bounded batch size and pagination.
- For cursor pagination on mutable datasets, keep deterministic ordering: order by the cursor column plus a unique tie-breaker (usually `id`), encode every ordering field in the cursor, and use seek predicates matching the sort direction. Do not replace cursor pagination with offset pagination. Add boundary tests for duplicate timestamps and no duplicate/skip across pages.
- Commit in chunks when a single transaction would be too large.
- Track progress so the job can resume safely.
- Compare-before-write to reduce unnecessary updates.
- Provide dry-run or explicit enable switches for risky repairs.

## Concrete cursor pagination patch pattern

When fixing cursor pagination that currently uses only a non-unique sort column, make the patch mechanical, not only conceptual:

```sql
where (sort_column < :cursorValue)
   or (sort_column = :cursorValue and id < :cursorId)
order by sort_column desc, id desc
limit :limit
```

For ascending order, flip the comparison operators and keep the `ORDER BY` direction aligned. The cursor object/token must carry every ordered field, for example `(sortValue, id)`, not just the non-unique sort value. Preserve the caller's limit/page size; do not switch to offset pagination as a shortcut.

Patch self-check:

- cursor DTO/token includes the unique tie-breaker;
- repository/mapper method signatures pass every cursor field needed by SQL;
- `WHERE` seek predicate and `ORDER BY` use the same columns and directions;
- `LIMIT` / page size behavior is retained;
- tests cover same-timestamp rows across a page boundary and assert no duplicate/skip.

## Tests to add when relevant

- rollback on failure;
- no duplicate effects on retry;
- no local write when a required remote call fails after all retries;
- already-processed input is a no-op;
- event/message emitted only after successful state change;
- partial failure path is observable and recoverable.
