# Scout4j

Scout4j is an AgentSkill for Java enterprise backend work. It provides two integrated capabilities:

1. **Active Review** (`/scout4j`) — scan the current git diff against hard-gate rules and output a structured ✅/❌/⚠️ report
2. **Java Enterprise Workflow** — guide a coding agent to investigate, plan, implement, and verify changes safely in Java repositories

A `UserPromptSubmit` hook is included to automatically inject the relevant coding reference into context when Java-related keywords are detected in a prompt — no manual trigger needed.

---

## What Scout4j provides

- **Hard-gate checks** for common Java enterprise failure modes:
  - `@Transactional` on `private` methods or self-invocations (Spring proxy blind spot)
  - Committing DB state and emitting an event/message before the transaction commits
  - Mapper method signature changes without syncing XML/SQL, `@Param`, and tests
  - Cursor field inconsistency across service / mapper / SQL / test layers
  - Placeholder tests that do not execute the real path
  - Idempotency or retry described only in comments, not implemented in code

- **Semantic proof check** — for every write operation in the diff, verify the three-line invariant: what must remain true, what code enforces it, and which test would fail if it breaks

- **Focused references** for common enterprise Java scenarios loaded on demand:
  - transactions and consistency boundaries
  - MQ/CDC consumers and idempotency
  - RPC/downstream retries, timeouts, and failure propagation
  - field/API/schema changes and compatibility rollout
  - data repair/backfill jobs
  - pagination, performance, and mapper/SQL consistency
  - bug fixes, code reviews, refactors, testing

- **Lightweight helper scripts** for stack detection and release-time leakage checks

---

## Installation

Clone this repository into your agent's skills directory and run the install script:

```bash
git clone https://github.com/641320825/Scout4j.git ~/.claude/scout4j
bash ~/.claude/scout4j/scripts/install.sh
```

`install.sh` registers the `UserPromptSubmit` hook in `~/.claude/settings.json`. The script is idempotent — safe to run multiple times.

If you install via a skill marketplace, run the install script from the installed location instead:

```bash
bash <install-path>/scripts/install.sh
```

---

## Usage

### Active Review

```bash
/scout4j                  # review all uncommitted changes (git diff HEAD)
/scout4j --staged         # review staged changes only (git diff --cached)
/scout4j <file>           # review a specific file
/scout4j <commit>         # review a specific commit (e.g. HEAD~1, abc1234)
/scout4j --all            # force all rule domains regardless of keywords
```

### Automatic context injection

After the hook is registered, any prompt that contains Java-related keywords (transaction, MQ, backfill, RPC, pagination, etc.) will automatically receive the relevant coding reference as additional context — no slash command needed.

### Java workflow guidance

Open any Java repository and describe your task. The skill will:
1. Detect the stack (Maven/Gradle, Spring Boot, MyBatis/JPA, etc.)
2. Classify the task and load the narrowest applicable reference
3. Investigate entry points and affected layers before editing
4. Propose a change plan for non-trivial work
5. Verify with the smallest meaningful command

---

## Repository layout

```text
SKILL.md                              AgentSkill entry point (unified: workflow + active review)
references/*.md                       Focused workflow references loaded on demand
scripts/detect-java-stack.sh          Lightweight Java stack detection helper
scripts/scout4j_hook.py               UserPromptSubmit hook (auto-inject references)
scripts/install.sh                    Registers the hook in ~/.claude/settings.json
scripts/check_java_skill_deoverfit.py Release guard against benchmark leakage
```

---

## What Scout4j is not

- It is not tied to a specific company architecture
- It does not assume Spring Boot, Maven, MyBatis, JPA, Kafka, or DDD unless the target repository shows those patterns
- It does not authorize destructive production operations, schema/data migrations, PR publication, or external side effects without explicit user confirmation
- It does not include local evaluation apparatus, benchmark fixtures, or A/B harnesses

---

## Quality gate (for contributors)

Before publishing changes, run:

```bash
python3 scripts/check_java_skill_deoverfit.py
```

Expected result:

```text
de-overfit grep OK
```

This prevents benchmark fixture names and standard-answer patterns from leaking into the reusable skill.

---

## License

MIT. See `LICENSE`.
