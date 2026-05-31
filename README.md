# Java Enterprise Workflow Skill

Reusable AgentSkill guidance for safe Java enterprise backend work: features, bug fixes, refactors, transactions, persistence, RPC/downstream calls, data repair, performance, and verification.

This package is the **skill** layer only. It is intended to be portable across Java teams and should not contain benchmark-specific answers, private architecture assumptions, or environment-specific configuration.

## What this skill does

- Encourages repository-first investigation instead of guessing from filenames.
- Separates investigation, plan, edit, verification, and summary.
- Provides focused references for common Java enterprise work:
  - feature and field/API/schema changes;
  - bug fixes and code reviews;
  - transaction boundaries and consistency;
  - RPC/downstream dependency handling;
  - MQ/CDC consumers;
  - data repair/backfill jobs;
  - performance and cursor pagination;
  - testing and stack variants.
- Requires executable verification when practical and honest reporting when verification is blocked.

## What this skill is not

- It is not tied to a specific company architecture.
- It does not assume Spring Boot, Maven, MyBatis, JPA, Kafka, or DDD unless the target repository shows those patterns.
- It is not a benchmark answer key. Fixture-specific lessons belong in `references/benchmark.md` or in an evaluation repository, not in the general references.
- It does not authorize destructive production operations, schema/data migrations, PR publication, or external side effects without explicit user confirmation.

## Layout

```text
SKILL.md                                  Main skill entry point
references/*.md                           Focused workflow references
scripts/detect-java-stack.sh              Lightweight stack detection helper
scripts/check_java_skill_deoverfit.py     Release guard against benchmark leakage
```

## Usage

Install or copy this folder as an AgentSkill. When the user asks for Java enterprise backend work, load `SKILL.md` first, then select the narrowest applicable reference from `references/`.

For example:

- RPC/downstream retry issue → `references/rpc-dependency.md`
- Data repair/backfill job → `references/data-repair.md`
- Cursor pagination/performance issue → `references/performance.md`
- Transaction consistency issue → `references/transactions.md`
- Testing/verification task → `references/testing.md`

## Quality rules

Before publishing changes to this standalone skill package, run:

```bash
python3 scripts/check_java_skill_deoverfit.py
```

Expected result: `de-overfit grep OK`.

This prevents benchmark fixture names and standard-answer patterns from leaking into the reusable skill.

## License

MIT. See `LICENSE`.
