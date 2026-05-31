# Performance / Query / Pagination Checklist

Use when a change touches query performance, large lists, batch jobs, reporting endpoints, fan-out calls, or user-visible latency.

## First identify

- Hot path: online request, async job, scheduled batch, admin-only operation, or one-off script.
- Data size assumptions: current and expected future cardinality.
- Existing indexes, sort order, tenant/user filters, soft-delete filters, and partition keys.
- Whether the bottleneck is DB, cache, search engine, RPC fan-out, serialization, or lock contention.

## Query and persistence checks

- Avoid unbounded reads; require limit/page size for list and batch operations.
- Watch for N+1 queries from loops calling repositories/RPCs.
- Keep filtering and sorting aligned with available indexes.
- For cursor pagination, use stable ordering with a unique tie-breaker; avoid relying only on non-unique timestamps.
- Do not change pagination defaults in a way that breaks older clients expecting the previous result shape.
- For batch reads/writes, bound batch size and memory usage; prefer streaming/chunking if supported by the project.
- Use `explain`/query plan or project-local profiling tools when the risk is DB performance.

## RPC and fan-out checks

- Avoid serial per-item remote calls in request paths; batch, cache, or prefetch when appropriate.
- Bound concurrency for parallel fan-out; do not create unbounded thread/task growth.
- Apply timeouts and fallback behavior consistent with nearby code.
- Preserve partial-failure semantics: fail fast, return partial data, retry later, or mark degraded explicitly.

## Validation ideas

- Targeted unit test for pagination boundaries and stable sorting.
- Integration test or local query-plan check for changed SQL/mapper queries.
- Benchmark/load test only when the repo already has a convention or the performance risk is central.
- At minimum, report data-size assumptions and unverified performance risks.

## Cursor pagination patch contract

When converting non-unique timestamp cursor pagination to keyset pagination, keep one coherent cursor contract across API, repository/mapper, XML/SQL, and tests.

Preferred MyBatis-safe shape:

```java
import org.apache.ibatis.annotations.Param;

List<Order> list(@Param("cursor") SeekCursor cursor, @Param("limit") int limit);
```

If the fixture cannot assume MyBatis annotations are available, use one request object instead of two loose parameters:

```java
List<Order> list(PageRequest request);
public static final class PageRequest {
    public final SeekCursor cursor;
    public final int limit;
}
```

```xml
<select id="list" resultType="Order">
  select * from orders
  <where>
    <if test="cursor != null">
      and (sort_time &lt; #{cursor.sortTime}
        or (sort_time = #{cursor.sortTime} and id &lt; #{cursor.id}))
    </if>
  </where>
  order by sort_time desc, id desc
  limit #{limit}
</select>
```

Rules:

- Do not split the contract by adding separate `cursorTime` / `cursorId` parameters while leaving a `SeekCursor` object unused.
- For MyBatis multi-parameter methods, add stable `@Param` names or use a single parameter object; do not rely on compiler parameter-name retention.
- Preserve first-page compatibility: support `null` cursor or keep the old one-argument constructor/factory if existing callers use it.
- Keep the unique tie-breaker in both `ORDER BY` and the seek predicate, with matching directions.
- If changing constructor shape, provide a compatibility constructor/factory or update every call site shown in the repo.
- Tests should prove multi-page traversal with equal timestamps and page size 1 or exact boundaries; if no MyBatis test harness exists, at least add a mapper-signature/XML binding self-check or note the integration gap honestly.
- In synthetic fixtures without JUnit/build files, do not use bare `assert` or placeholder `main` tests as proof. If you must add plain Java tests, make them throw `AssertionError` explicitly and exercise the real pagination predicate/order helper; otherwise state that executable verification is unavailable.
- First-page/null-cursor behavior is mandatory. XML should guard cursor predicates with `<if test="cursor != null">` or equivalent dynamic SQL.
- If the task says index alignment, either add the existing project migration/index file, or explicitly call out that schema migration is not present in the fixture and remains unverified; do not silently omit it.
- A fake repository/test helper must implement the same seek predicate and sort order, not return `null` or an empty placeholder.
- Boundary tests should assert actual ordered IDs across pages, not only row counts or presence of keywords.
- Mapper namespace/interface mismatch is a warning sign; align namespace to the real mapper interface when the fixture gives enough context, or call out the omitted binding explicitly.
- If MyBatis `@Param` is not available in the tiny fixture, prefer a single parameter object (`PageRequest` with `cursor` and `limit`) over relying on runtime parameter names.
- Mapper namespace must match the mapper/repository interface package/name when the XML is meant to bind to that interface. Do not leave `namespace="RowMapper"` while editing `Repository` unless the repo proves that is the real mapper name.
- If adding `@Param`, include the import in the interface patch (`org.apache.ibatis.annotations.Param`) or choose a single request object to avoid unavailable imports.
- Cursor constructor compatibility matters: keep the old one-argument constructor/factory if the repo shows existing callers, and add a two-field constructor/factory for subsequent pages.
- Pagination tests should cover: page-size 1 through equal timestamps, full traversal until empty, final partial page, empty repository, and no duplicate IDs across pages.
- Index alignment cannot be silently implied by `ORDER BY`. Add the existing migration/index file when present; otherwise include an explicit TODO/risk note in the report and do not claim it was fully implemented.
