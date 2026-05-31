# Compatibility / Rollout / Migration Checklist

Use when changing public APIs, request/response fields, database schema, message schemas, client SDKs, serialized formats, or behavior consumed by other services.

## Compatibility dimensions

- Source compatibility: existing client code still compiles against generated/client artifacts.
- Wire compatibility: old clients and new servers can still serialize/deserialize correctly.
- Semantic compatibility: old clients still observe behavior they would reasonably expect.

## Safer change patterns

- Prefer additive changes over rename/remove/type changes.
- Do not add required request fields to existing APIs unless versioning or a migration plan exists.
- When adding optional request fields, define default behavior that matches previous behavior.
- Continue populating existing response fields even if a replacement field is introduced.
- Treat renames as add-new + deprecate-old + migrate-readers + remove later only with explicit approval.
- Be careful adding enum values to response/resource fields; older clients may not handle unknown values.
- For database changes, prefer expand-contract:
  1. add nullable/new column or new table;
  2. deploy writers/readers compatible with both old and new data;
  3. backfill safely;
  4. switch reads;
  5. remove old path only after confirmation.

## Rollout checks

- Feature flag or config gate for risky behavior changes.
- Backward and forward compatibility during mixed-version deployment.
- Old data, missing field, null field, and partially backfilled data behavior.
- Rollback path: what happens if code rolls back after schema/data changes?
- Monitoring: metrics/logs to detect unexpected client errors, validation failures, or migration drift.

## Tests

- Old request without the new field.
- New request with the field set.
- Old persisted data missing the new field.
- Mixed compatibility where reader/writer versions may differ.
- Rollback or feature-flag-disabled behavior when practical.
