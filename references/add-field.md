# Add Field / API / Schema Change Checklist

Use when adding, renaming, removing, or changing semantics of a field in request/response objects, persistence models, search/read models, or SDK/client contracts.

## Checklist

- Persistence model/entity.
- Database migration or schema definition, if present.
- Mapper/DAO XML or annotations.
- DTO/request/response classes.
- Converter/mapper/assembler logic.
- Validation annotations or manual validation.
- API docs/OpenAPI/protobuf/IDL/client SDK if present.
- Search index/read model/denormalized projection if present.
- Serialization compatibility and default values.
- Backward/forward compatibility, rollout, and old-data behavior; see `compatibility-rollout.md` for migrations or public contracts.
- Tests for old data, missing field, and populated field.

## Rules of thumb

- After changing an entity/model field, grep for converters/mappers involving that type.
- Do not assume mapper/converter omissions always fail compilation; verify runtime mapping expectations.
- For backward compatibility, define behavior when older clients omit the field.
