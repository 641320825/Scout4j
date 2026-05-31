# Add Feature Workflow

## When to use

Use for new behavior, new endpoints, new scheduled jobs, new service logic, or changes that add a business capability.

## Steps

1. Clarify target behavior, source of truth, expected output, and compatibility requirements.
2. Locate the entry point and existing adjacent feature.
3. Trace the call chain to application/domain/service/persistence boundaries.
4. Draft a change plan if 3+ files or public behavior changes are involved.
5. Implement from domain/application outward, keeping adapters thin.
6. Add or update tests for:
   - happy path;
   - null/empty input;
   - invalid or unsupported state;
   - idempotency if repeated calls/messages are possible;
   - feature-flag disabled path if a rollout switch exists.
7. Run targeted Maven verification, then broaden if needed.

## Generic checklist

- Does the change belong in controller/adapter, application orchestration, domain logic, or persistence?
- Are DTOs, converters, validation, and API docs/contracts updated?
- Are errors handled consistently with nearby code?
- Is the change backward compatible?
- Is there an existing feature flag/rollout convention?
