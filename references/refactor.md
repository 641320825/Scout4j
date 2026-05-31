# Refactor Workflow

Use when changing structure without intended behavior changes.

## Rules

1. Establish current behavior with tests or targeted verification.
2. Keep behavior changes separate from mechanical refactors.
3. Prefer small commits/patches when possible.
4. Preserve public APIs unless explicitly changing them.
5. Run tests before and after if the refactor is risky.

## Change plan should include

- moved/renamed classes;
- dependency direction changes;
- deleted dead code;
- compatibility risk;
- verification commands.
