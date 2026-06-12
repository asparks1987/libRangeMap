# libRangeMap Scratch Runtime Path

This directory defines the Alpha v1 mapping contract for Scratch integration.

Scratch does not provide a built-in native numeric exception model, so this implementation uses explicit branching blocks:

- compare input against `input_min` and `input_max`
- if `clip = true`, clamp to bounds before mapping
- if `clip = false`, route out-of-range values to an explicit `error` broadcast
- apply the linear formula using base math blocks in the editor

Use `librangemap.md` as the canonical block-level mapping spec for Scratch extension authorship.
The spec covers integer, float, boolean, text, bytes, sequence, categorical, map/object, temporal, and image-like policies.
Temporal mapping is documented as a numeric epoch contract with explicit strict/clipping behavior.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```text
mapped := map_integer_value(50, 0, 100, -1, 1, false)
```

```text
mapped := map_float_value(0.5, 0, 1, -1, 1, false)
```

```text
mapped := map_boolean_value(true, -1, 1, -1, 1)
```

```text
mapped := map_text_value("b", "alphabet", "abc", -1, 1)
```

```text
mapped := map_categorical_value("dog", ["cat", "dog"], -1, 1)
```

```text
mapped := map_temporal_value(1609459200, 0, 2000000, -1, 1, false)
```

### Sequences

```text
mapped := map_sequence_value([0, 50, 100], 0, 100, -1, 1, false)
```

### Map/Object

```text
mapped := map_object_value({"active": true, "age": 0}, [{"name": "age", "family": "integer", "inputMin": 0, "inputMax": 100}, {"name": "active", "family": "boolean"}])
```

### Image-like

```text
mapped := map_image_raw_value([0, 127, 255], 3, 1, 1, -1, 1, false)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Float policies require finite values and explicit clipping behavior.
- Boolean policies require explicit false/true values within the configured output range.
- Text policies require explicit codepoint, byte, or alphabet mode and fail on unknown alphabet characters.
- Sequence policies preserve order and nested shape recursively, and empty sequences fail unless the block contract explicitly allows them.
- Categorical policies require an explicit unique vocabulary list and fail on unknown tokens.
- Map/object policies require explicit schema fields, sorted schema-name output order, unknown-field rejection by default, and explicit missing-value policy.
- Image-like policies require raw channel lists plus explicit width, height, and channel metadata; malformed shape/length combinations fail explicitly.
- Temporal policies require numeric finite epoch values plus explicit `timestamp` unit policy; strict and clip mode behavior follows the canonical guard rails.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.

Scratch text, categorical, sequence, map/object, temporal, and image-like behavior is documented in `librangemap.md` so the block contract stays aligned with the beta wrapper matrix.
