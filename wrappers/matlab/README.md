# libRangeMap MATLAB Wrapper

This directory contains a first-party MATLAB reference for Alpha v1 integer, float, boolean, text, sequences, categorical, bytes, temporal, image-like, and map/object mapping.

The implementation uses no toolbox dependencies and follows the shared linear formula and range rules.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```matlab
mapped = librangemap(50, 0, 100);
```

### Float

```matlab
mapped = librangemap_float(5.0, 0.0, 10.0);
```

### Boolean

```matlab
mapped = librangemap_boolean(true);
```

### Text

```matlab
mapped = librangemap_text("Ada");
```

### Temporal

```matlab
mapped = librangemap_temporal(0.0, -10.0, 10.0);
```

### Bytes

```matlab
bytes = uint8([0 255]);
mapped = librangemap_bytes(bytes);
```

### Image-like

```matlab
mapped = librangemap_image(uint8([0 127; 255 64]));
```

### Categorical

```matlab
mapped = librangemap_categorical("green", ["red" "green" "blue"]);
```

### Sequences

```matlab
mapped = librangemap_sequence([0 50 100], 0, 100);
```

### Map/Object

```matlab
schema = struct("name", {"age", "active"}, "family", {"integer", "boolean"}, "input_min", {0, []}, "input_max", {120, []});
mapped = librangemap_object(schema, struct("name", {"active", "age"}, "family", {"boolean", "integer"}, "value", {true, 42}), false);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `librangemap_float` accepts finite numeric scalars and rejects `NaN`/`Inf`; integer acceptance is explicit policy.
- `librangemap_boolean` accepts only logical scalars and never coerces other truthy/falsey values.
- `librangemap_text` maps strings deterministically in codepoint, byte, or alphabet mode, rejects empty text by default, and fails on unknown alphabet characters or duplicate alphabet entries.
- `librangemap_bytes` accepts strings or integer-valued numeric byte vectors, rejects empty payloads by default, and maps each byte deterministically.
- `librangemap_image` accepts numeric grayscale matrices, preserves shape, rejects empty input by default, and maps each pixel deterministically.
- `librangemap_sequence` accepts numeric vectors or matrices, preserves nested shape for matrices, rejects empty arrays by default, and maps each element through the same explicit range policy.
- `librangemap_categorical` requires a non-empty unique token list, maps by stable token order, and rejects unknown tokens explicitly.
- `librangemap_temporal` accepts numeric timestamps or `datetime` scalars against explicit epoch ranges.
- `librangemap_object` accepts explicit schema and input struct arrays, emits values in sorted schema-name order, rejects duplicate or unknown fields by default, and supports explicit missing-field substitution.
- Tables and custom MATLAB objects are not silently coerced; project them into supported schema/input struct arrays first.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
