# Data Repair / Refresh / Backfill Workflow

Use for scripts, scheduled jobs, one-off repair tasks, bulk updates, or rebuilding derived data.

## Required safeguards

- Dry-run mode when practical.
- Feature flag or explicit enable switch for writes.
- Compare-before-write: update only rows that still match the observed stale/inconsistent state.
- Bounded batch size and resumability.
- Clear transaction boundary for each write batch.
- Audit/operation logs if the project has a convention.
- Metrics or structured summary output: scanned, matched, changed, skipped, failed, next cursor, has more.
- Rollback or remediation plan for risky writes.

## Concrete patch pattern

For jobs shaped like an unbounded update followed by a normal business event, replace the broad side effect with a small, project-native repair API.

Prefer the simplest shape that fits the repository:

- accept dry-run flag, batch size, and cursor/checkpoint;
- select at most one bounded page of repair candidates;
- count scanned and matched rows separately;
- in dry-run, do not write and do not publish normal business events;
- in apply mode, use a conditional update that checks the state observed during selection;
- return a structured result object or existing metrics sink update;
- return enough cursor/page metadata to resume safely.

A minimal pseudocode shape:

```java
RepairResult repair(RepairRequest request) {
    RepairPage<CandidateRow> page = repository.findCandidates(request.cursor(), request.batchSize());
    RepairResult result = new RepairResult();
    for (CandidateRow row : page.rows()) {
        result.scanned++;
        if (!row.needsRepair()) {
            continue;
        }
        result.matched++;
        if (request.dryRun()) {
            continue;
        }
        int affected = repository.updateIfCurrent(row.id(), row.observedState(), row.targetState());
        if (affected > 0) {
            result.changed++;
        } else {
            result.skipped++;
        }
    }
    result.nextCursor = page.nextCursor();
    result.hasMore = page.hasMore();
    return result;
}
```

Repository contracts should make resumability and compare-before-write executable, for example:

```java
RepairPage<CandidateRow> findCandidates(Cursor cursor, int limit);
int updateIfCurrent(long id, State observedState, State targetState);
```

Use existing domain models when present. If the repository lacks a row model, introduce the smallest project-native DTO/value object and ensure tests/fakes use the same visible type as the production interface.

## Patch self-check

- Dry-run performs no repository writes and publishes no normal business event.
- Updates are bounded by one page/batch, not a whole-table update without a limit.
- Each write is conditional/idempotent or otherwise safe to rerun.
- Progress cursor/checkpoint is returned or accepted so the job can resume after partial failure.
- Return value/log/metrics reports scanned, matched/changed, skipped, failed.
- Changed count uses the conditional update return value; a zero-row update is skipped/concurrent change, not changed.
- Tests cover dry-run no writes, apply path, batch/resume, already-correct or concurrently changed rows, and no blind event publication.
- Patch applies and compiles before semantic quality is discussed.

## Repository/interface hard gates

- Do not replace a top-level repository interface with a nested repository class or shadow type. Extend the existing interface with the minimum new methods.
- Do not invent a second row/value type when the existing repository interface already exposes one. Match the exact visible type and method signatures used by the interface and tests.
- Fake implementations must exactly match interface generics; a lookalike test-local row type is not a valid override of a production row type.
- Do not assign to final fields in fixtures or fakes. If status changes are needed, update mutable fixture state through the repository method or construct a replacement value object according to the existing model shape.
- Do not leave the old unbounded update as a callable path on the repair job. If compatibility requires keeping it in the interface, mark it unused/deprecated and make the repair job never call it.
- Do not remove an existing event publisher contract merely to avoid calling it. Keep the interface compatible and ensure the repair job does not invoke normal business publication during repair.
- Do not count a row as changed unless the conditional update returns a positive affected-row count. Count zero as skipped/concurrent change.
- Do not print the only summary to standard output; return a structured result or update an existing metrics sink.
- Dry-run must not increment changed; use matched, would-change, or planned for rows that would be changed.
- Expose resumability in the public API/result: accept a cursor/checkpoint and return next cursor plus has-more/page state when only one bounded page is processed.
- Batch size must come from request/options/config or an existing bounded constant; do not hardcode an unchangeable magic number in the loop.
- Candidate selection should return only repair candidates when possible; if the repository can return non-candidates, metrics must distinguish scanned from matched.
- Preserve existing constructor/API compatibility when feasible, especially if the original job accepted collaborators such as publishers or repositories.
- Compare-before-write must use state observed during candidate selection, not a universal hardcoded source state.

## Hard failure patterns for data-repair patches

- adding unrelated audit/clock/event abstractions that make the patch large or non-applyable;
- package-private top-level DTO classes in the same Java file when nested classes or existing models would fit better;
- hardcoded repair semantics without using row data;
- local-only cursor variables with no returned/supplied checkpoint;
- dry-run and apply paths selecting different candidates.

## Do not

- Reuse utility methods blindly if they have side effects such as writing logs, emitting events, or overwriting unrelated fields.
- Run unbounded updates without pagination or a limit.
- Hide partial failures.

## Test cases

- no-op when data is already consistent;
- updates only inconsistent rows;
- dry-run does not write;
- feature flag disabled does not write;
- null/missing related data;
- batch resume or partial failure behavior.
