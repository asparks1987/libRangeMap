# libRangeMap PL/SQL Runtime Path

This directory holds a PL/SQL procedure-oriented reference for Alpha v1 integer, float, boolean, text, bytes, sequences, categorical, temporal, map/object, and image-like mapping.

Use it as a direct adaptation in Oracle environments for deterministic normalization of ordinary scalar and text values.

## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```sql
mapped := libRangeMap_map_integer(50, 0, 100, -1, 1, FALSE);
```

```sql
mapped := libRangeMap_map_float(0.5, 0, 1, -1, 1, FALSE);
```

```sql
mapped := libRangeMap_map_boolean(TRUE, -1, 1, -1, 1);
```

```sql
mapped := libRangeMap_map_text('Ada', 'codepoint', NULL, -1, 1);
```

```sql
mapped := libRangeMap_map_categorical('green', SYS.ODCIVARCHAR2LIST('red', 'green', 'blue'), -1, 1);
```

```sql
mapped := libRangeMap_map_bytes(HEXTORAW('00FF'), -1, 1, FALSE, FALSE);
```

```sql
mapped := libRangeMap_map_temporal(1700000050000, 1700000000000, 1700000100000, -1, 1, FALSE);
```

```sql
mapped := libRangeMap_map_sequence(SYS.ODCINUMBERLIST(0, 50, 100), 0, 100, -1, 1, FALSE, FALSE);
```

```sql
mapped := libRangeMap_map_image_raw(HEXTORAW('007FFF'), 3, 1, 1, -1, 1, FALSE, FALSE);
```

```sql
mapped := libRangeMap_map_object_value(
  '{"age":34,"active":true,"label":"green","payload":{"x":0.2,"y":0.8}}',
  '{"family":"object","schema":{"age":{"mapper_type":"integer","input_min":0,"input_max":120},"active":{"mapper_type":"boolean"},"label":{"mapper_type":"categorical","vocabulary":["red","green","blue"]},"payload":{"mapper_type":"object","schema":{"x":{"mapper_type":"float","input_min":0,"input_max":1},"y":{"mapper_type":"float","input_min":0,"input_max":1}}}}}'
);
```

```sql
mapped := libRangeMap_map_object(
  '{"age":34,"active":true,"label":"green","payload":{"x":0.2,"y":0.8}}',
  '{"age":{"mapper_type":"integer","input_min":0,"input_max":120},"active":{"mapper_type":"boolean"},"label":{"mapper_type":"categorical","vocabulary":["red","green","blue"]},"payload":{"mapper_type":"object","schema":{"x":{"mapper_type":"float","input_min":0,"input_max":1},"y":{"mapper_type":"float","input_min":0,"input_max":1}}}}',
  FALSE,
  FALSE,
  FALSE,
  NULL,
  -1,
  1,
  FALSE
);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Float mapping rejects non-finite values and preserves clipping semantics.
- Boolean mapping uses explicit false/true policy values and rejects invalid metadata.
- Text mapping supports codepoint, byte, and alphabet modes, rejects empty text by default, and fails on unknown or duplicate alphabet tokens.
- Bytes mapping accepts RAW payloads, rejects empty payloads by default, and preserves order.
- Image-like mapping accepts RAW grayscale/RGB/RGBA-style channel payloads with explicit width, height, and channel metadata; malformed shape/length combinations fail explicitly.
- Categorical mapping requires a non-empty unique token list, maps by stable token order, and rejects unknown tokens explicitly.
- Sequence mapping accepts `SYS.ODCINUMBERLIST` values, preserves order, rejects empty lists by default, and maps each element through the same explicit range policy.
- Map/object mapping now accepts schema-directed nested object specs for deterministic field projection, unknown-field fail-fast behavior, and explicit missing-value policy in structured payloads.
- Temporal mapping uses Unix-millisecond `NUMBER` timestamps and preserves the same explicit clipping and range-checking policy.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
