# libRangeMap Rust Wrapper

This directory contains the first-party Rust wrapper over the shared C ABI.

It depends only on the Rust standard library and the native `librangemap_core.dll` already built by the project.
Current scope: integer, float, boolean, text, bytes, sequences, categorical, temporal, image-like, and map/object mapping.

## Install/use

```powershell
.\test.cmd
```

The build and test scripts route linking through Rust's own `rust-lld` so the wrapper stays dependency-free on Windows.
The bundled test also checks JSON spec round-trips, explicit out-of-range failures, repeated-call determinism on the canonical integer path, and text family round-trips with explicit unknown-token rejection.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```rust
let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;
```

### Float

```rust
let mapped = FloatRangeMapper::new_default(0.0, 10.0)?.map_value(5.0)?;
```

### Boolean

```rust
let mapped = BooleanRangeMapper::new_default()?.map_value(true);
```

### Text

```rust
let mapped = TextRangeMapper::new_alphabet("ABC".to_string(), [-1.0, 1.0], false, false, None)?.map_value("CA")?;
```

### Bytes

```rust
let mapped = TextRangeMapper::new_bytes([-1.0, 1.0], false, false, None)?.map_bytes_value(&[0, 127, 255])?;
```

### Categorical

```rust
let mapped = CategoricalRangeMapper::new_default(vec!["red".to_string(), "green".to_string(), "blue".to_string()])?.map_value("green")?;
```

### Sequences

```rust
let integer_mapper = IntegerRangeMapper::new_default(0, 100)?;
let sequence_mapper = SequenceRangeMapper::new(|value: &i64| integer_mapper.map_value(*value), false)?;
let mapped = sequence_mapper.map_value(&[0, 50, 100])?;
```

### Temporal

```rust
let mapped = TemporalRangeMapper::new_default(-10.0, 10.0)?.map_value(0.0)?;
```

### Image-like

```rust
let mapper = ImageRangeMapper::new_default()?;
let mapped = mapper.map_value(&[0, 127, 255])?;
```

### Map/Object

```rust
let mapper = ObjectRangeMapper::new(
    vec![
        ObjectFieldSpec {
            name: "status".to_string(),
            allow_missing: false,
            missing_value: None,
            mapper: ObjectValueMapper::Categorical(
                CategoricalRangeMapper::new_default(vec![
                    "pending".to_string(),
                    "active".to_string(),
                    "complete".to_string(),
                ]).unwrap(),
            ),
        },
        ObjectFieldSpec {
            name: "active".to_string(),
            allow_missing: false,
            missing_value: None,
            mapper: ObjectValueMapper::Boolean(BooleanRangeMapper::new_default().unwrap()),
        },
        ObjectFieldSpec {
            name: "score".to_string(),
            allow_missing: false,
            missing_value: None,
            mapper: ObjectValueMapper::Sequence(
                Box::new(ObjectValueMapper::Integer(
                    IntegerRangeMapper::new_default(0, 100).unwrap(),
                )),
                false,
            ),
        },
    ],
    false,
).unwrap();
let mapped = mapper.map(&[
    ObjectFieldValue {
        name: "status".to_string(),
        value: ObjectValue::Text("complete".to_string()),
    },
    ObjectFieldValue {
        name: "active".to_string(),
        value: ObjectValue::Boolean(true),
    },
    ObjectFieldValue {
        name: "score".to_string(),
        value: ObjectValue::Sequence(vec![
            ObjectValue::Integer(0),
            ObjectValue::Integer(50),
            ObjectValue::Integer(100),
        ]),
    },
]).unwrap();
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- JSON specs reject unsupported `mapper_type` values during recovery.
- `FloatRangeMapper` accepts finite numeric scalars, rejects `NaN`/`Inf`, and exposes `map_int_value` when integer input is explicitly allowed.
- `BooleanRangeMapper` accepts only `true` and `false` and never coerces other truthy/falsey inputs.
- `TextRangeMapper` accepts Unicode strings for `codepoint` and `alphabet` modes, and byte slices for `byte` mode; alphabet mode requires a non-empty unique alphabet.
- `TextRangeMapper::new_bytes` accepts byte slices for `byte` mode and preserves order.
- `SequenceRangeMapper` accepts typed slices through an explicit element-mapper function, preserves nested shape when nested sequence mappers are composed, rejects empty slices by default, and fails on unsupported element mappings.
- `CategoricalRangeMapper` requires a non-empty unique token list, maps by stable token order, and rejects unknown tokens explicitly.
- `TemporalRangeMapper` accepts finite epoch-second values and maps them against explicit ranges.
- `ImageRangeMapper` accepts byte slices and nested byte rows, preserves order, and rejects empty input by default.
- `ObjectRangeMapper` maps fixed schemas only, errors on unknown/missing fields unless `allow_missing` is set, preserves deterministic output order, and rejects invalid nested payload types explicitly.
- The bundled test also checks repeated-call determinism for the canonical integer path and JSON round-trips for the float, boolean, text, bytes, sequence, categorical, temporal, and image-like mappers.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
