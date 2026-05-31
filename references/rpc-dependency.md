# RPC / Downstream Dependency Checklist

Use when code calls another service, SDK, HTTP client, RPC client, message gateway, payment provider, identity provider, or any downstream dependency.

## Risks to handle

- Timeout, transport failure, throttling, and partial downstream outage.
- Retry amplification and duplicate side effects.
- Holding a local database transaction open while waiting on a remote dependency.
- Ambiguous exception contracts: callers cannot distinguish retryable transport errors from business failures.
- Logging or surfacing sensitive request/response data.
- Fallbacks that silently hide data loss or stale state.

## Implementation checklist

- Keep remote calls outside local database transactions unless the project has an explicit saga/outbox pattern.
- Bound retries with a small maximum attempt count and a clear retryable-error predicate.
- Retry only transport/transient failures, not validation, authorization, not-found, or non-idempotent business errors.
- Preserve the downstream contract's declared exception type where practical; do not wrap final transport failures in a generic runtime exception unless that is the project convention.
- If the current public API or adjacent caller contract exposes a checked transport exception, retry exhaustion should preserve that checked type; do not convert the last checked transport failure into an unchecked wrapper just to simplify a helper signature.
- Retry helper methods should either declare the checked transport exception or return a project-native result/error form that preserves caller-visible transport semantics.
- Add a test seam for backoff/sleep so retry tests are deterministic and fast.
- Restore interrupt status if a retry delay is interrupted, then fail explicitly.
- Make idempotency explicit when a retry can duplicate a remote or local side effect.
- Do not swallow the last failure. Propagate or record it according to the caller contract.

## Transaction boundary pattern

A safe shape is usually:

1. Validate local request.
2. Perform the remote call with bounded retry outside the write transaction.
3. Enter a real local write boundary only for the local state change.
4. Persist the result through an existing transactional service/repository boundary, an injected collaborator, or `TransactionTemplate`.
5. Ensure the orchestrator calls that write boundary instead of bypassing it with a direct repository/DAO write when a transactional seam is required.
6. Emit events after commit or through an outbox when the project has that convention.

The transactional boundary must be reachable through framework semantics. In Spring-style code, a private method or self-invoked method annotated with `@Transactional` is not a real proxy boundary. Prefer an existing application service, a separate injected collaborator, or `TransactionTemplate` instead of comments or self-invocation.

## Patch self-check

- The orchestrating method does not hold a database transaction while waiting on the remote call.
- The local write still has a concrete transaction boundary; removing an annotation is not enough.
- Retry count is bounded and easy to test.
- Retry predicate is narrow and excludes business exceptions.
- Final transport failure preserves the caller-visible contract, including checked exception type when that is already part of the API.
- Backoff is deterministic in tests and does not slow the suite.
- The orchestrator reaches a real transactional write seam; it does not bypass that seam with a direct repository/DAO write after introducing one.
- Tests cover success-after-retry, retry exhaustion, and non-retryable errors.
- The original public constructor/API is preserved or all visible call sites are updated.
- No fake/test helper is truncated; every referenced method and field exists in the patch.

## Tests to add or update

- success without retry;
- success after one retryable transport failure;
- retry exhaustion propagates the final transport failure with the caller-visible exception contract and performs no local write if the remote result was never obtained;
- non-retryable/business exception is attempted once;
- local write happens through the intended transaction boundary, and the orchestration path actually invokes that boundary rather than writing directly;
- interrupted backoff restores interrupt status and fails deterministically.

## Do not

- Catch `Exception` and retry everything.
- Sleep directly in production code without a test seam.
- Put remote I/O inside a local transaction for convenience.
- Add broad fallback behavior that silently writes stale or partial data.
- Invent unavailable Spring/JUnit/Mockito dependencies in a small project that does not already use them.
- Keep duplicate unused persistence fields after introducing a dedicated write collaborator.
