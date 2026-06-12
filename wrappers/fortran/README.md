# libRangeMap Fortran Wrapper

This directory provides a first-party Fortran 2008 reference implementation for Alpha v1 integer, float, boolean, text, bytes, sequences, categorical, temporal, image-like, and schema-driven map/object mapping.

No external libraries are required.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```fortran
x = map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.)
```

```fortran
x = map_float_value(0.5d0, 0.0d0, 1.0d0, -1.0d0, 1.0d0, .false.)
```

```fortran
x = map_boolean_value(.true., -1.0d0, 1.0d0, -1.0d0, 1.0d0)
```

```fortran
x = map_text_value('cab', -1.0d0, 1.0d0, 'alphabet', 'abc', .false., .false.)
```

```fortran
x = map_categorical_value('cat', [character(len=3) :: 'cat', 'dog'], -1.0d0, 1.0d0)
```

```fortran
xs = map_integer_sequence_value([0, 50, 100], 0, 100, -1.0d0, 1.0d0, .false.)
```

```fortran
bytes = map_bytes_value('ABC', -1.0d0, 1.0d0, .false., .false.)
```

```fortran
x = map_temporal_value(0.0d0, -10.0d0, 10.0d0, -1.0d0, 1.0d0, .false.)
```

```fortran
image = map_image_value('ABC', -1.0d0, 1.0d0, .false., .false.)
```

```fortran
image2d = map_image_value(reshape([0, 127, 255, 64], [2, 2]), -1.0d0, 1.0d0, .false.)
```

```fortran
type(map_object_field_t), allocatable :: object_values(:), object_schema(:)
real(8), allocatable :: object_mapped(:)
allocate(object_values(1))
allocate(object_schema(1))
object_schema(1)%name = 'age'
object_schema(1)%family = MAP_FAMILY_INTEGER
object_schema(1)%int_input_min = 0
object_schema(1)%int_input_max = 100
object_schema(1)%output_min = -1.0d0
object_schema(1)%output_max = 1.0d0
object_values(1)%name = 'age'
object_values(1)%family = MAP_FAMILY_INTEGER
object_values(1)%int_value = 50
object_mapped = map_object_value(object_values, object_schema)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Float mapping rejects non-finite values and preserves the clipping contract.
- Boolean mapping uses explicit false/true policy values and rejects invalid metadata.
- Text mapping accepts `codepoint` or `alphabet` mode, rejects unknown characters explicitly, and requires at least two unique alphabet characters.
- Categorical mapping accepts a non-empty explicit vocabulary and rejects unknown or duplicate tokens.
- Bytes mapping accepts strings as byte payloads, rejects empty payloads by default, and maps each byte into the configured range.
- Sequence mapping accepts typed integer arrays, preserves nested shape for 2-D arrays, rejects empty arrays by default, and maps each element through the same explicit range policy.
- Temporal mapping uses explicit epoch-second values and preserves the clipping contract.
- Image-like mapping accepts byte strings or numeric 2-D pixel arrays and preserves shape recursively.
- Map/object mapping is schema-driven; unknown fields, missing keys, and duplicate keys are explicit failures unless schema policies permit alternatives.
- The generated verifier script also exercises repeated integer, float, boolean, text, sequence, categorical, bytes, temporal, image-like, and map/object mapping on the canonical path to confirm deterministic output.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.



