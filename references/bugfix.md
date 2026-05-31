# Bugfix Workflow

## Steps

1. Reproduce or identify the failing scenario from logs, tests, or code path.
2. State expected vs actual behavior.
3. Find the minimal responsible layer.
4. Add a failing test when practical.
5. Fix the root cause, not only the symptom.
6. Add regression coverage for boundary cases.
7. Run the smallest relevant test command.

## Pitfalls to check

- Null or empty collections.
- Already-processed / target-state-already-reached inputs.
- Transaction boundary assumptions.
- Async/event listener timing.
- Mapper/converter fields silently missing.
- Soft-deleted or dirty data arriving from upstream systems.
