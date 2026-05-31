# MQ / CDC / Async Consumer Workflow

Use for Kafka/RabbitMQ/RocketMQ/JMS listeners, binlog/CDC consumers, event handlers, and async processing pipelines.

## Checklist

- Message schema and version compatibility.
- Idempotency: repeated messages must be safe.
- State pre-check: skip if target state is already reached.
- Dirty-data filtering: deleted/invalid/out-of-order records may arrive.
- Retry semantics: distinguish retryable vs non-retryable failures.
- For at-least-once delivery, prefer durable idempotency such as state pre-checks, unique business keys, or a processed-message record when the project has that convention.
- Ordering assumptions and partition/key behavior.
- Transaction boundary: DB writes and emitted events should have clear atomicity guarantees.
- Observability: logs, metrics, trace IDs, dead-letter handling.
- Tests: happy path, duplicate message, null/invalid payload, stale/deleted record, downstream failure.

## Generic pattern

```text
parse/validate message
→ load current state
→ if already processed, return success
→ if invalid/stale/deleted, skip with observability
→ apply minimal state transition
→ persist atomically
→ emit follow-up event if needed
```
