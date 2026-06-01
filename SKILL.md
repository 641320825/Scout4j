---
name: scout4j
description: "Java 代码审查与开发工作流（Scout4j）。覆盖两种模式：① 主动审查（/scout4j）— 读取 git diff，对照硬闸规则（@Transactional 位置、事务/消息顺序、Mapper 同步、MQ 幂等、游标一致性等）输出 ✅/❌/⚠️ 结构化报告；② 工作流引导 — 安全、系统地在 Java 企业级后端仓库（Maven/Gradle、Spring Boot、MyBatis/JPA、Kafka/MQ）中实现需求、修 Bug、重构、改字段/接口、处理事务边界。安装后自动注册 UserPromptSubmit hook，Java 相关 prompt 自动注入对应编码规范。"

metadata:
  skillhub.creator: "wb_lvzhenyu"
  skillhub.updater: "wb_lvzhenyu"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
---

# Scout4j

Scout4j 提供两种能力：

1. **主动审查**（`/scout4j`）— 扫描当前 diff，对照硬闸规则输出 ✅/❌/⚠️ 报告
2. **工作流引导** — 安全、系统地完成 Java 企业级后端开发任务

---

## Installation

**首次使用前，运行 install.sh 注册 hook：**

```bash
# 通过 skill 市场安装后
bash ~/.claude/skills/scout4j/scripts/install.sh

# 或直接克隆仓库后
bash ~/.claude/scout4j/scripts/install.sh
```

install.sh 会自动完成：
- 将 `scout4j_hook.py` 拷贝到 `~/.claude/scripts/` 并注册到 `~/.claude/settings.json` 的 `UserPromptSubmit` hooks
- 注册完成后，所有含 Java 关键词的 prompt 将自动注入对应编码规范（无需手动触发）

若 hook 已注册，脚本幂等跳过，不重复添加。

---

## Active Review（主动审查）

### 调用方式

```
/scout4j                  # 审查全量未提交改动（git diff HEAD）
/scout4j --staged         # 只审查已 staged 的改动（git diff --cached）
/scout4j <file>           # 审查指定文件
/scout4j <commit>         # 审查某次 commit（如 HEAD~1、abc1234）
/scout4j --all            # 强制跑所有规则域，不做关键词过滤
```

### 执行步骤

**Step 1 — 获取 diff**

按参数执行对应命令；`--staged` 用 `git diff --cached`，指定文件用 `git diff HEAD -- <file>`，指定 commit 用 `git show <commit>`，默认 `git diff HEAD`。diff 为空则提示用户后终止。diff 超过 500 行先列文件清单，询问是否全量审查。

**Step 2 — 检测规则域（可多命中）**

| 域 | 触发关键词/模式 |
|---|---|
| `transactions` | `@Transactional`、commit、rollback、outbox、一致性 |
| `mq-consumer` | `@KafkaListener`、`@MafkaListener`、Consumer、Listener、MQ |
| `add-field` | 新增 `private` 字段、DTO、`@JsonProperty`、schema |
| `rpc-dependency` | OctoClient、`@Reference`、RestTemplate、RPC、重试 |
| `data-repair` | Backfill、Repair、BatchUpdate、刷数、全量 |
| `bugfix` | NPE、`NullPointerException`、fix、修复 |
| `performance` | LIMIT、PageHelper、cursor、分页、慢查询、索引 |
| `compatibility-rollout` | `@Deprecated`、灰度、双写、Feature Flag |

**Step 3 — 加载 reference 文件**

用 Read 工具加载 `references/<域>.md`（路径：skill 目录下的 `references/`）作为审查依据。

**Step 4 — 硬闸检查**

以下任一条件成立，报告中标记 **❌ HARD FAIL**，说明位置和修复建议：

1. `@Transactional` 加在 `private` 方法上（Spring proxy 不拦截）
2. `@Transactional` 加在同类自调用方法上（`this.xxx()` 或无前缀调用）
3. 事务提交前已发出成功事件/消息（应用 `afterCommit` 或 outbox 模式）
4. 改了 Mapper 方法签名，但 XML/SQL、`@Param`、测试未同步更新
5. 游标分页的 cursor 字段在 service/mapper/SQL/test 四处不一致
6. 测试 helper 是占位符（`// TODO`、`assertTrue(true)`），不执行真实路径
7. 注释里描述了幂等/重试，但代码没有实际实现
8. 引入大量无关辅助类，非核心文件占 diff 行数超过 50%

**Step 5 — 语义证明检查**

对 diff 中的写操作，检查能否回答三个问题（回答不上来标记 **⚠️**）：

1. **Invariant**：成功/重试/回滚/部分失败后，什么业务不变量必须保持？
2. **Enforcement**：哪段代码（事务边界/幂等键/锁/SQL）保证了它？
3. **Proof**：哪个测试/断言会在不变量被破坏时失败？

**Step 6 — 输出审查报告**

```
## Scout4j 审查报告

审查范围：git diff HEAD（N 行变更，K 个文件）
命中规则域：transactions / mq-consumer

### 硬闸检查（§七）
❌ [HARD FAIL] @Transactional 加在 private 方法上
   位置：src/.../OrderService.java:42
   原因：Spring proxy 不拦截 private 方法，注解无效
   修复：将方法改为 public，或提取到独立的 @Service bean

✅ 无事务提交前发出消息问题
✅ Mapper 签名变更已同步 XML 和测试

### 语义证明（§八）
⚠️ OrderService.createOrder() 存在 DB 写操作，未找到幂等键或回滚断言
   建议：添加唯一约束 + 对应测试用例

✅ MQ 消费者已有幂等键检查

结论：发现 1 处硬闸违规（❌），需重写后再提交。
```

审查只看 diff 的 `+` 行，不审查未变动代码。

---

## Java Enterprise Workflow

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
