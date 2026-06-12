# libRangeMap Swift Wrapper

This directory contains a first-party Swift runtime path for Alpha v1 integer, float, boolean, text, bytes, sequences, categorical, map/object, temporal, and image-like mapping.

No third-party packages are used; it relies only on the Swift standard library.

```powershell
# When swift is available:
swiftc .\LibrangeMap.swift -o .\librangemap-swift && .\librangemap-swift
```


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```swift
let mapped = IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue(50)
```

### Float

```swift
let mapped = FloatRangeMapper(inputMin: 0.0, inputMax: 10.0).mapValue(5.0)
```

### Boolean

```swift
let mapped = BooleanRangeMapper().mapValue(true)
```

### Text

```swift
let mapped = TextRangeMapper().mapValue("Ada")
```

### Bytes

```swift
let mapped = BytesRangeMapper().mapValue([0, 127, 255])
```

### Image-like

```swift
let mapped = ImageRangeMapper().mapRows([[0, 127], [255]])
```

### Categorical

```swift
let mapped = CategoricalRangeMapper(tokens: ["red", "green", "blue"]).mapValue("green")
```

### Sequences

```swift
let integerMapper = IntegerRangeMapper(inputMin: 0, inputMax: 100)
let sequenceMapper = SequenceRangeMapper<Int64, Double>(elementMapper: { integerMapper.mapValue($0) })
let mapped = sequenceMapper.mapValue([0, 50, 100])
```

### Temporal

```swift
let mapped = TemporalRangeMapper(inputMin: 1_700_000_000_000, inputMax: 1_700_000_100_000).mapValue(Date(timeIntervalSince1970: 1_700_000_050_000.0 / 1000.0))
```

### Map/Object

```swift
let objectMapper = ObjectRangeMapper(schema: [ObjectFieldSpec(name: "age", family: .integer, inputMin: 0, inputMax: 120), ObjectFieldSpec(name: "active", family: .boolean)])
let mapped = objectMapper.mapValue([ObjectFieldInput(name: "active", value: .boolean(true)), ObjectFieldInput(name: "age", value: .integer(42))])
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `FloatRangeMapper` accepts finite numeric scalars and rejects non-finite values; integer input must be routed through `mapIntegerValue` and is explicit policy.
- `BooleanRangeMapper` accepts only `Bool` and never coerces truthy/falsey values.
- `TextRangeMapper` maps strings deterministically in codepoint, byte, or alphabet mode, rejects empty text by default, and fails on unknown alphabet characters or duplicate alphabet entries.
- `BytesRangeMapper` maps byte arrays deterministically, rejects empty input by default, and preserves order.
- `ImageRangeMapper` maps grayscale byte rows and nested byte rows deterministically, preserves shape, and rejects empty input by default.
- `SequenceRangeMapper` maps typed arrays through an explicit element-mapper function, preserves nested shape when nested sequence mappers are composed, rejects empty arrays by default, and fails on unsupported element mappings.
- `CategoricalRangeMapper` requires a non-empty unique token list, maps by stable token order, and rejects unknown tokens explicitly.
- TemporalRangeMapper accepts Unix-millisecond `Int64` values and `Date` values, normalizing them to UTC epoch milliseconds before applying the range formula.
- `ObjectRangeMapper` accepts explicit schema/input field arrays, emits values in sorted schema-name order, rejects duplicate or unknown input fields by default, and supports explicit missing-field substitution.
- Maps, records, classes, and other custom runtime objects are not silently coerced; project them into supported `ObjectFieldInput` values with an explicit extractor first.
- The bundled self-check also exercises float, boolean, bytes, image-like, sequence, map/object, categorical, and temporal canonical paths in addition to repeated integer mapping.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
