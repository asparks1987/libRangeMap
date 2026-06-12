# libRangeMap Prolog Wrapper

This directory contains a first-party Prolog predicate reference for Alpha v1 mapping.

The code mirrors the spec for integer, float, boolean, text, bytes, sequences, categorical, and temporal range behavior without external dependencies.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```prolog
?- map_integer_value(50, 0, 100, -1.0, 1.0, false, Mapped).
```

### Float

```prolog
?- map_float_value(5.0, 0.0, 10.0, -1.0, 1.0, false, Mapped).
```

### Boolean

```prolog
?- map_boolean_value(true, -1.0, 1.0, Mapped).
```

### Text

```prolog
?- map_text_value('ABC', -1.0, 1.0, alphabet, false, false, 'ABC', Mapped).
```

### Categorical

```prolog
?- map_categorical_value(cat, [cat, 1, true], -1.0, 1.0, Mapped).
```

### Map/Object

```prolog
?- map_object_value(
     _{age: 25, active: true, profile: _{score: 50}},
     _{
       age: integer(0, 120),
       active: boolean,
       profile: object(_{score: float(0.0, 100.0)})
     },
     -1.0, 1.0, false, false, false, _Mapped).
```

```prolog
?- map_object_value(_{age: 25}, _{age: integer(0, 120)}, -1.0, 1.0, false, false, false, _).
```

### Bytes

```prolog
?- map_bytes_value([0, 127, 255], -1.0, 1.0, false, Mapped).
```

### Sequences

```prolog
?- map_sequence_integer_value([0, [50], 100], 0, 100, -1.0, 1.0, false, false, Mapped).
```

### Temporal

```prolog
?- map_temporal_value(1700000050.0, 1700000000.0, 1700000100.0, -1.0, 1.0, false, Mapped).
```

### Image-like

```prolog
?- map_image_value([0, 127, 255], -1.0, 1.0, false, false, auto, Mapped).
```

```prolog
?- map_image_value([[0, 127, 255], [64, 192, 255]], -1.0, 1.0, false, false, rgb, _Mapped).
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `map_float_value/7` accepts numeric scalars and uses the same strict/clip policy as integers.
- `map_boolean_value/4` accepts only `true` and `false` and never coerces other truthy/falsey values.
- `map_text_value/8` accepts atoms or strings for `codepoint` and `alphabet` modes, lists of byte integers for `byte` mode, and requires an explicit alphabet with at least two unique characters for alphabet mode.
- `map_bytes_value/5` accepts a list of integers in `[0, 255]` and preserves order.
- `map_sequence_integer_value/8` accepts lists and nested lists of integers, maps them recursively, and rejects empty sequences by default unless `AllowEmpty=true`.
- `map_categorical_value/5` accepts atomic tokens from an explicit vocabulary and rejects unknown tokens or duplicate vocabulary entries.
- `map_temporal_value/7` accepts explicit epoch-second numbers and uses the same strict/clip policy as the scalar families.
- `map_object_value/8` accepts dictionary objects and explicit schema specs, rejects unknown fields by default, rejects missing required fields unless `AllowEmpty=true`, and preserves deterministic field order from schema order.
- `map_image_value/7` maps nested numeric image-like lists recursively, supports `auto`, `rgb`, and `rgba` modes, supports empty images only when `AllowEmpty=true`, and rejects malformed payloads or non-byte scalars by default.
- The bundled smoke helper `run_self_check/0` exercises integer, float, boolean, text, bytes, sequence, categorical, and temporal mappings on the canonical path.
- The smoke helper now exercises map/object and image-like mappings plus explicit unknown/missing/empty-type failures for those families.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.



