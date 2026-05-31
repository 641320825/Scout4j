# Stack Variants

Use when the repository stack is unfamiliar, mixed, or not clearly Maven/Spring. Detect before assuming framework-specific patterns.

## Build tools

### Maven

Signals: `pom.xml`, `.mvn/`, `mvnw`.

Common commands:

```bash
./mvnw -pl <module> test
./mvnw -pl <module> -am test
./mvnw verify
```

### Gradle

Signals: `settings.gradle`, `settings.gradle.kts`, `build.gradle`, `build.gradle.kts`, `gradlew`.

Common commands:

```bash
./gradlew projects
./gradlew tasks
./gradlew :<module>:test
./gradlew :<module>:test --tests 'com.example.XxxTest'
```

## Web/API layers

- Spring MVC: `@RestController`, `@RequestMapping`, `@GetMapping`, `@PostMapping`.
- JAX-RS/Jakarta REST: `@Path`, `@GET`, `@POST`.
- RPC/IDL frameworks: look for generated interfaces, protobuf/thrift/IDL files, or project-local resource/facade naming.

Follow adjacent endpoint style rather than introducing a new API style.

## Persistence styles

- MyBatis: mapper interfaces/XML, `@Mapper`, SQL provider annotations.
- JPA/Hibernate: `@Entity`, `JpaRepository`, JPQL/Criteria.
- JDBC/jOOQ: SQL strings, generated table classes, DSL contexts.

When adding fields, update all model/query/converter/schema paths that the project actually uses; do not assume a missing mapper update will fail compilation.

## Mapping and boilerplate tools

- MapStruct: mapper interfaces annotated with `@Mapper`; generated code may require compile to validate.
- Lombok: generated getters/builders/constructors may hide compile-time requirements; check annotations before adding boilerplate.
- Records/immutables/builders: update constructors, builders, JSON annotations, and tests consistently.

## Test frameworks

- JUnit 4/5: `*Test.java`, `@Test` imports indicate version.
- Mockito: mock setup and verification style should follow nearby tests.
- Spock: `*Spec.groovy`, `given/when/then`, usually still run through Maven/Gradle test tasks.
- Spring Boot Test/Testcontainers: useful but heavier; prefer narrower unit tests unless integration behavior is the risk.

## Rule

Do not introduce a new framework, annotation style, or test stack unless the user explicitly asks or the repository already uses it nearby.
