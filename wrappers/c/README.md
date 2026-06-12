# libRangeMap C Wrapper

This directory provides a first-party C wrapper path over the shared C ABI.

The wrapper keeps behavior explicit in C while preserving the same validation,
error codes, and mapping contract as `csrc/librangemap_core.h`.
Current scope: integer, float, boolean, text, bytes, sequences, categorical, temporal, image-like, and maps/structs/object mapping.

## Install/use

From this directory:

```powershell
.\test.cmd
```

The verification build uses the repository-owned Zig compiler launcher and does not
require third-party runtime libraries.


## 2-line quickstart

Use the exact canonical entrypoint for this runtime:

```c
double mapped;
lrm_map_integer(0, 100, -1.0, 1.0, 0, 50, &mapped);
lrm_map_float(0.0, 1.0, -1.0, 1.0, 0, 0.5, &mapped);
lrm_map_boolean(-1.0, 1.0, -1.0, 1.0, 1, &mapped); // true -> 1.0
```

### Bytes

```c
unsigned char bytes[] = {0, 127, 255};
double mapped_bytes[3];
lrm_map_bytes(bytes, 3, -1.0, 1.0, 0, mapped_bytes);
```

### Text

```c
double mapped_text[3];
int mapped_length = 0;
lrm_map_text("Ada", NULL, -1.0, 1.0, &mapped_length, mapped_text);
```

### Categorical

```c
const char* tokens[] = {"red", "green", "blue"};
double mapped;
lrm_map_categorical("green", tokens, 3, -1.0, 1.0, &mapped);
```

### Image-like

```c
unsigned char pixels[] = {0, 127, 255};
double mapped_pixels[3];
lrm_map_image_bytes(pixels, 3, -1.0, 1.0, 0, mapped_pixels);
```

### Temporal

```c
double mapped_ts;
lrm_map_temporal(0.0, 1.7e9, -1.0, 1.0, 0, 1.6e9, &mapped_ts); // Unix seconds
```

### Maps / Structs / Objects

```c
const lrm_map_object_schema_field_t schema[] = {
    { .name = "score", .family = LRM_OBJECT_FIELD_INTEGER, .allow_missing = 0, .mapper_spec = &(lrm_map_object_integer_spec_t){ .input_min = 0, .input_max = 100, .output_min = -1.0, .output_max = 1.0, .clip = 0 } },
};
double out_values[1];
lrm_map_object(schema, 1, &(lrm_map_object_input_field_t[]){ { .name = "score", .has_value = 1, .family = LRM_OBJECT_FIELD_INTEGER, .value.integer = 100 } }, 1, 0, out_values);
```

### Sequences

```c
int64_t values[] = {0, 50, 100};
double mapped_values[3];
lrm_map_integer_sequence(0, 100, -1.0, 1.0, 0, values, 3, mapped_values);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- The bundled verifier also exercises repeated integer mapping on the canonical path to confirm deterministic output.
- `lrm_map_text` maps C strings deterministically as codepoint or alphabet vectors, rejects empty input by default, and fails on unknown or duplicate alphabet tokens.
- `lrm_map_bytes` maps each byte into the configured range and rejects empty payloads by default.
- `lrm_map_categorical` requires a non-empty unique token list, maps by stable token order, and rejects unknown tokens explicitly.
- `lrm_map_integer_sequence` and `lrm_map_float_sequence` map typed C arrays element-by-element, reject empty sequences by default, and preserve ordering deterministically.
- `lrm_map_image_bytes` maps raw grayscale-style byte buffers deterministically using the same byte-range policy as `lrm_map_bytes`.
- The bundled verifier also exercises repeated integer mapping, canonical map/object mapping, byte-family mapping, categorical mapping, and typed sequence mapping to confirm deterministic output.
- `lrm_map_temporal` maps explicit numeric epoch values (timestamp mode) through explicit `input_range`/`output_range`, with clipping/strict policy preserved by shared linear math and deterministic failure handling for malformed non-finite inputs.
- Maps/struct-like/object values are mapped through explicit schemas; unknown keys fail by default and may be ignored when `allow_unknown` is enabled; missing values must be configured as missing-policy fields.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.

