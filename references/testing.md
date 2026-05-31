# Testing and Verification

## Coverage standard

For handler/facade/service changes, cover at least:

- happy path;
- null/empty input;
- invalid state;
- idempotency or already-done state, if applicable;
- feature-flag disabled/dry-run path, if applicable.

## Test style

Follow existing project conventions: JUnit, Mockito, Spring Boot Test, Spock, Testcontainers, etc. Prefer nearby tests as templates.

## Maven commands

Start narrow:

```bash
./mvnw -pl <module> test -Dtest=XxxTest
./mvnw -pl <module> test
./mvnw -pl <module> -am test
./mvnw verify
```

For Groovy/Spock, the standard Maven test phase is usually still appropriate:

```bash
./mvnw -pl <module> test -Dtest=XxxSpec
```

## Reporting

Always report commands run and whether they passed. If not run, say why.
