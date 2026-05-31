# Scout4j

Scout4j is an AgentSkill for Java enterprise backend work. It helps coding agents investigate, plan, implement, and verify changes in Java repositories without jumping straight to fragile patches.

It is designed for common backend engineering tasks such as feature work, bug fixes, refactors, transaction-boundary changes, mapper/persistence updates, RPC/downstream dependency handling, MQ/CDC consumers, data repair jobs, performance fixes, and targeted verification.

## What Scout4j provides

- A structured workflow for Java backend changes: investigate → plan → edit → verify → summarize.
- Repository-first guidance: read local conventions and adjacent examples before changing code.
- Focused references for common enterprise Java scenarios:
  - feature and field/API/schema changes;
  - bug fixes and code reviews;
  - transactions and consistency boundaries;
  - RPC/downstream retries, timeouts, and failure propagation;
  - MQ/CDC consumers and projection updates;
  - data repair/backfill jobs;
  - pagination, performance, and mapper/SQL consistency;
  - testing and verification.
- Lightweight helper scripts for stack detection and release-time leakage checks.

## What Scout4j is not

- It is not tied to a specific company architecture.
- It does not assume Spring Boot, Maven, MyBatis, JPA, Kafka, or DDD unless the target repository shows those patterns.
- It is not a benchmark answer key and does not include the local evaluation apparatus, fixtures, harnesses, logs, or benchmark outputs.
- It does not authorize destructive production operations, schema/data migrations, PR publication, or external side effects without explicit user confirmation.

## Repository layout

```text
SKILL.md                                  AgentSkill entry point
references/*.md                           Focused workflow references loaded as needed
scripts/detect-java-stack.sh              Lightweight Java stack detection helper
scripts/check_java_skill_deoverfit.py     Release guard against benchmark leakage
```

## Installation

Copy this repository folder into your agent's skills directory, or install it using the skill mechanism supported by your agent runtime.

The skill name inside `SKILL.md` is:

```text
java-enterprise-workflow
```

Use Scout4j when asking an agent to work on Java enterprise backend code.

## Usage

When the skill is active, the agent should read `SKILL.md` first, then load the narrowest applicable reference from `references/`.

Examples:

- RPC/downstream retry issue → `references/rpc-dependency.md`
- Data repair/backfill job → `references/data-repair.md`
- Cursor pagination/performance issue → `references/performance.md`
- Transaction consistency issue → `references/transactions.md`
- Testing/verification task → `references/testing.md`
- Public API or persisted field change → `references/add-field.md` and `references/compatibility-rollout.md`

## Quality gate

Before publishing changes to this standalone skill package, run:

```bash
python3 scripts/check_java_skill_deoverfit.py
```

Expected result:

```text
de-overfit grep OK
```

This prevents benchmark fixture names and standard-answer patterns from leaking into the reusable skill.

You can also run a basic diff hygiene check before committing:

```bash
git diff --check
```

## License

MIT. See `LICENSE`.
