---
name: java-enterprise-workflow
description: General-purpose coding-agent workflow for Java enterprise backend projects. Use when implementing features, fixing bugs, refactoring, reviewing code/PRs, adding fields/APIs/database schema changes, changing REST/RPC endpoints, repository/mapper persistence, MQ/CDC consumers, transaction boundaries, JUnit/Mockito/Spock tests, or validating Maven/Gradle Spring layered backend code. Designed for open-source reuse across Java teams; avoid company-specific assumptions.
---

# Java Enterprise Workflow

Use this skill to work safely and systematically in Java enterprise backend repositories, especially Maven/Gradle multi-module projects, Spring/Spring Boot, layered/modular architecture, ORM/mapper-based persistence, messaging consumers, transaction-heavy service logic, and test-heavy codebases.

This skill is intentionally generic. Do not assume private architecture, internal system names, business-specific approval flows, proprietary middleware, or company-only conventions.

## Immediate Startup Rules

- If the user names a repository/path, work there. If no repository is provided and the request is to improve this workflow/skill, work in this skill directory. Otherwise ask for the repository path and target outcome.
- Before code edits, check local project guidance (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `README.md`) and `git status --short`. Do not overwrite user changes.
- For implementation tasks, first locate the real entry point and one adjacent example; do not patch by filename guess.
- For non-trivial Java changes, separate: investigation → concise plan → edit → targeted verification → summary.

## Scope and Non-Goals

Use the repository as the source of truth. This skill does **not** replace project-local guidance such as `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, `README.md`, architecture decision records, or team coding standards.

Do not assume:
- the project follows DDD, clean architecture, or any specific layering style;
- the stack is Spring Boot, Maven, MyBatis, JPA, MapStruct, Lombok, Kafka, or any specific tool;
- every change needs MQ/CDC/search-index/cache updates;
- database schema or production data may be changed without an explicit requirement;
- external side effects are safe to trigger during local verification.

For destructive writes, production data repair, schema migration, public API changes, large refactors, or operations with external side effects, stop and confirm the plan before proceeding.

## Core Principles

1. Clarify before coding when requirements are vague or the target repository is missing.
2. Protect user work: inspect `git status --short`; avoid overwriting unrelated changes.
3. Locate entry points and domain boundaries before editing.
4. For complex changes, propose a change plan before making edits.
5. Keep persistence models, DTOs, converters/mappers, API contracts, migrations, and tests consistent.
6. Verify with the smallest meaningful command first, then broaden if needed.
7. Report actual verification only; do not describe static checks as tests or compilation.
8. Capture reusable pitfalls as generic notes; do not store project secrets.
9. Generalize private lessons before adding them to this skill; if a lesson cannot be safely generalized, do not include it.

## Investigation Workflow

When starting in an unfamiliar codebase or after receiving a task without an obvious entry point:

1. **Detect the stack** — run `scripts/detect-java-stack.sh` or manually find build files (`pom.xml`, `build.gradle*`, `settings.gradle*`), source layouts, and test conventions.
2. **Find entry points** — locate controllers, RPC/resource classes, message listeners, scheduled jobs, or CLI runners for the affected area.
3. **Trace the call chain** — follow the request from the entry point through application/domain/service to the persistence boundary.
4. **Identify affected layers** — note converters/mappers, DTOs, entities, repository/mapper/DAO, migrations, and tests.
5. **Check adjacent patterns** — read nearby tests, existing error-handling style, and API conventions before introducing new patterns.

## Start-of-Task Triage

Classify the request:

- **Feature / behavior change** → read `references/add-feature.md`.
- **Bug fix** → read `references/bugfix.md`.
- **Permission / tenant / data-scope leak** → read `references/bugfix.md` and `references/code-review.md`; add negative authorization tests where practical.
- **Field/API/schema change** → read `references/add-field.md`; also `references/compatibility-rollout.md` for public APIs, persisted data, migrations, or mixed-version rollout.
- **Code review / PR review / risk audit** → read `references/code-review.md`.
- **Transaction-boundary or consistency change** → read `references/transactions.md`.
- **MQ / CDC / async consumer change** → read `references/mq-consumer.md`.
- **RPC / downstream dependency / retry / timeout change** → read `references/rpc-dependency.md`.
- **Performance / slow query / pagination / fan-out issue** → read `references/performance.md`.
- **Data repair / data refresh / backfill** → read `references/data-repair.md`.
- **Refactor** → read `references/refactor.md`.
- **Testing or verification** → read `references/testing.md`.
- **Unfamiliar stack, Gradle/Maven choice, or framework variant** → read `references/stack-variants.md`.
- **Memory / knowledge capture** → read `references/memory-policy.md`.
- **Skill self-check / regression benchmark** → read `references/benchmark.md`.

If multiple apply, read the most specific one first.

## Startup Reference Selection Heuristics

When choosing references, prefer the narrowest file but do not stop there if the task crosses boundaries. Many enterprise Java failures are cross-cutting. Add one extra reference when these signals appear:

- **Remote call + write / retry / timeout** → read both `references/rpc-dependency.md` and `references/transactions.md`.
- **Bulk repair / backfill / refresh** → read `references/data-repair.md`; if it writes DB state, also check transaction boundaries and idempotency.
- **Pagination / batch processing / large queries** → read `references/performance.md`; if cursor or mutable data is involved, also check `references/transactions.md` batch guidance.
- **Public API + persistence change** → combine `references/add-field.md`, `references/compatibility-rollout.md`, and `references/testing.md`.
- **MQ/CDC + DB update** → combine `references/mq-consumer.md` and `references/transactions.md`.

After reading, convert the references into a concrete patch checklist. Do not merely mention risks in the plan: make the diff enforce them through method shape, constants, guards, tests, and explicit failure behavior.


## Active Review Mode

Use this mode when the user asks to review a Java backend diff, audit staged changes, check a commit, or run a pre-submit review. This is a review workflow, not a built-in slash command; follow it only when requested by the user or clearly appropriate for a code-review task.

Read `references/code-review.md` for the detailed review checklist, semantic-proof questions, and report format. Keep the review repository-first and stack-aware: apply checks only when the repository uses the relevant technology or the diff shows the relevant pattern.

## Benchmark Plateau Guard

Recent Java-workflow backtests showed the workflow can satisfy checklist terms while still failing judge review. Treat this as a hard failure mode: the goal is not to mention enterprise concerns, but to make the patch enforce the business invariant.

Before finalizing any non-trivial patch, write a 3-line semantic proof in your scratch plan and ensure the diff backs it up:

1. **Invariant:** what must always remain true after success, retry, rollback, partial failure, and rerun.
2. **Enforcement path:** the exact production code path that guarantees it, including transaction boundary, cursor/order, idempotency key, mapper SQL, lock, or failure propagation.
3. **Proof:** the targeted test, dry-run/apply parity check, or executable assertion that would fail if the invariant were broken.

If you cannot name all three, pause and inspect more code instead of adding comments, constants, or superficial guards.

### Hard Failure Gates

If any gate below is triggered, treat the current patch as invalid and rewrite it before finalizing. Do not explain around the failure in prose.

- The diff claims a cursor/resume fix but the cursor contract is split across inconsistent service, mapper, SQL, and test parameters.
- A test helper is a placeholder, always returns empty data, or does not execute the path that enforces the claimed invariant.
- Mapper SQL order/predicate and test expected order disagree, or pagination lacks a deterministic unique tie-breaker.
- Multi-parameter MyBatis mapper changes omit stable `@Param` names or an equivalent single-parameter object contract.
- State, cursor, or retry progress is advanced before durable side effects commit, without an idempotent recovery path.
- The patch invents broad helper classes or rewrites unrelated APIs instead of the smallest project-native change.
- Tests or fake repositories access private fields, return `null` placeholders, ignore `limit`/cursor arguments, or do not mutate/check state for compare-before-write.
- The patch removes existing constructor/API parameters only to silence a side effect instead of preserving compatibility or clearly migrating callers.
- A resumable cursor is represented as an opaque unvalidated string when the ordered fields are known and can be modeled as a typed cursor/result.

### Common judge-failure patterns to actively prevent

- **Cursor / batch resume:** use deterministic unique ordering, a single cursor contract, and boundary tests that prove no skip/duplicate across equal sort keys, page boundaries, inserted-between-pages rows, and retry-after-partial-success. Detailed benchmark anti-patterns live in `references/benchmark.md`; load that file only for benchmark/debug work.
- **Transaction / concurrency:** put atomic state changes inside the real Spring proxy boundary; avoid self-invocation traps. Define rollback behavior and after-commit/outbox timing explicitly.
- **Mapper / SQL contract:** update Java signatures, `@Param` names, XML/annotation SQL, result mappings, and tests together. Do not leave a method shape that compiles only by coincidence.
- **Idempotency / retry:** retries must be bounded and safe to rerun. Duplicate delivery or partial completion should converge to one business result.
- **Verification quality:** a passing checklist is insufficient; add at least one negative or edge-case test that proves the business invariant, not just that a helper was called.

## Quality Bar Against Baseline

The workflow should create visibly better results than a generic Java coding attempt. Before finalizing a plan or patch, check whether it adds at least one of these concrete improvements over baseline:

- safer transaction boundary or after-commit/outbox behavior;
- bounded/idempotent retry or explicit timeout/failure propagation;
- dry-run/apply parity, resumable batching, metrics, or auditability;
- deterministic pagination with unique tie-breaker and boundary tests;
- negative tests for authorization, rollback, duplicate delivery, retry exhaustion, or partial failure;
- compatibility handling for old data, mixed versions, or API consumers.

If the change only describes these concerns without changing code/tests, treat it as incomplete.

## Semantic / Style Self-Review

Before presenting a patch as done, review it as if it were going into a real enterprise Java repository, not just a benchmark:

- It should compile with the repository's existing build and test framework; do not introduce JUnit/Mockito/AssertJ/Spring dependencies that the project does not already use.
- It should follow adjacent naming, package layout, exception style, logging style, and test style.
- It should avoid regex-gaming: constants, annotations, and comments are not enough unless the behavior is implemented and tested.
- For Spring features, check real framework semantics such as transactional proxy interception, bean boundaries, event timing, and rollback rules.
- Prefer the smallest project-native change over broad helper-class invention. If a helper/collaborator is needed, name why and keep it aligned with existing patterns.
- If no executable verification was run, say so clearly and do not call the change proven.

## Clarification Template

When the request is ambiguous, ask concise questions before editing:

1. My understanding: `<expected behavior / target outcome>`.
2. Likely affected scope: `<modules/classes/APIs/data paths>`.
3. Unclear points: `<source of truth, edge cases, compatibility, rollout>`.

For non-trivial tasks, ask up to three high-value questions. Do not block on trivial uncertainty if the repository makes the answer obvious.

## Change Plan Rule

Before editing, output a change plan and wait for confirmation when a task likely touches 3+ files or changes public behavior/API/data contracts.

A good plan lists:
- target files/classes;
- intended changes;
- compatibility or migration concerns;
- tests to add/update;
- Maven/Gradle commands to run.

For small localized fixes, proceed directly after inspection.

## Edit Safety Rules

- Keep changes minimal and aligned with nearby patterns; avoid broad refactors unless explicitly requested.
- If files already have user changes, edit only clearly required hunks and mention the pre-existing dirty state.
- Do not create or run data migrations/backfills, call production services, or trigger external side effects without explicit approval.
- When adding fields, always trace write path, read path, conversion path, serialization/API path, and old-data/default behavior.
- When changing transactions, MQ consumers, schedulers, or retries, include idempotency and partial-failure behavior in tests or explicit risk notes.

## Code Exploration

Prefer `scripts/detect-java-stack.sh <repo>` for initial stack discovery. For focused follow-up, search only the affected area and keep output bounded.

Look for:
- entry points: controllers/resources, RPC handlers, listeners, schedulers, command runners;
- business logic: services, domain/application classes, validators, policy objects;
- persistence: repositories, mappers/DAOs, XML/SQL, entities/models, migrations;
- conversion and contracts: DTOs, assemblers/converters, serializers, API docs;
- tests near the changed behavior.

## Verification

Use the smallest meaningful project command first, preferring wrappers (`./mvnw`, `./gradlew`). For command examples and stack-specific variants, read `references/testing.md` and `references/stack-variants.md`.

If full verification is too expensive or blocked, run the best targeted substitute and say exactly what was and was not verified.

## Completion Checklist

Before reporting done:
- Explain what changed.
- Mention tests/verification run and results.
- Call out unverified areas honestly.
- Suggest follow-up only when useful.
