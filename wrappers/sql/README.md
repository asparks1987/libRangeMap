# libRangeMap SQL Runtime Path

This directory provides a first-party SQL reference implementation path for Alpha v1 integer mapping.

The SQL snippet is intentionally explicit and dependency-free:

```sql
CREATE OR REPLACE FUNCTION librangemap_map_value(
    p_value INT,
    p_input_min INT,
    p_input_max INT,
    p_output_min DOUBLE PRECISION,
    p_output_max DOUBLE PRECISION,
    p_clip BOOLEAN
) RETURNS DOUBLE PRECISION AS $$
```

Behavior:
- `p_input_min < p_input_max` required.
- `p_output_min < p_output_max` required.
- If `p_clip = false`, values outside the input range raise an error.
- If `p_clip = true`, values are clamped to input bounds.

Use file `librangemap.sql` as a shared implementation reference for PostgreSQL/compatible engines and can be adapted for SQL Server/PL/SQL forms.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```sql
SELECT libRangeMap_map_integer(50, 0, 100, -1.0, 1.0, FALSE);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.