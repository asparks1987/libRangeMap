# libRangeMap SQL Runtime Path

This directory provides a first-party SQL reference implementation path for Alpha v1 integer, float, boolean, text, bytes, sequences, categorical, temporal, image-like, and map/object mapping.

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
- Float mapping rejects non-finite values and keeps the same clipping contract.
- Boolean mapping uses explicit false/true policy values and rejects invalid metadata.
- Categorical mapping accepts non-null text tokens from an explicit vocabulary and rejects unknown or duplicate tokens.

Use file `librangemap.sql` as a shared implementation reference for PostgreSQL/compatible engines and can be adapted for SQL Server/PL/SQL forms.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```sql
SELECT libRangeMap_map_integer(50, 0, 100, -1.0, 1.0, FALSE);
```

```sql
SELECT libRangeMap_map_float(0.5, 0.0, 1.0, -1.0, 1.0, FALSE);
```

```sql
SELECT libRangeMap_map_boolean(TRUE, -1.0, 1.0, -1.0, 1.0);
```

```sql
SELECT libRangeMap_map_text('Ada', 'codepoint', NULL, -1.0, 1.0);
```

```sql
SELECT libRangeMap_map_bytes(E'\\x00ff'::bytea, -1.0, 1.0, FALSE);
```

```sql
SELECT libRangeMap_map_sequence(ARRAY[0.0, 50.0, 100.0], 0.0, 100.0, -1.0, 1.0, FALSE);
```

```sql
SELECT libRangeMap_map_categorical('cat', ARRAY['cat', 'dog'], -1.0, 1.0);
```

```sql
SELECT libRangeMap_map_temporal('1970-01-01 00:00:00+00'::timestamptz, -10.0, 10.0, -1.0, 1.0, FALSE);
```
```sql
SELECT libRangeMap_map_image_value('[0, 127, 255]'::jsonb, 'grayscale', 0.0, 255.0, -1.0, 1.0, FALSE, FALSE);
```
```sql
SELECT libRangeMap_map_image_value('"\x00ff"'::jsonb, 'raw_bytes', 0.0, 255.0, -1.0, 1.0, FALSE, FALSE);
```
Map/object mapping with explicit schemas maps deterministic field-level contracts:

```sql
SELECT libRangeMap_map_object(
  '{"age": 34, "active": true}'::jsonb,
  '{"age":{"mapper_type":"integer","input_min":0,"input_max":120},"active":{"mapper_type":"boolean"}}'::jsonb
);
```
```sql
SELECT libRangeMap_map_object(
  '{"age": 34, "active": true, "extra": "unused"}'::jsonb,
  '{"age":{"mapper_type":"integer","input_min":0,"input_max":120},"active":{"mapper_type":"boolean"}}'::jsonb,
  TRUE,
  FALSE,
  FALSE,
  NULL,
  -1.0,
  1.0,
  FALSE
);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Bytes mapping accepts `bytea` payloads, rejects empty payloads by default, and maps each byte into the configured range.
- Map/object mapping requires schema-driven records and explicit flags for unknown/missing handling.
- Sequence mapping accepts numeric arrays, rejects empty arrays by default, and maps each element into the configured range.
- Text mapping accepts explicit codepoint or alphabet-driven text modes and rejects empty input, unknown tokens, and duplicate alphabet entries.
- Categorical mapping accepts non-null text tokens from an explicit vocabulary and rejects unknown or duplicate tokens.
- Temporal mapping accepts `TIMESTAMP WITH TIME ZONE` input and maps via explicit epoch seconds.
- The SQL artifact includes a direct self-check block that exercises integer, float, boolean, bytes, sequence, categorical, temporal, image, and map/object mappings.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
