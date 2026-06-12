# libRangeMap Go Wrapper

This first-party Go wrapper targets the shared C ABI from the root native core.

It keeps the wrapper dependency-free and uses only the Go standard library plus the native `librangemap_core.dll` that is already part of the project.
Current scope: integer, float, boolean, text, bytes, sequences, categorical, temporal, image-like, and maps/structs/objects.

## Install/use

From this directory:

```powershell
$env:CC = "$PWD\\..\\..\\tools\\zigcc.cmd"
$env:PATH = "$PWD\\..\\..\\librangemap\\native;$env:PATH"
$env:CGO_ENABLED = "1"
go test ./...
```

The `test.cmd` helper performs the same setup for Windows shells and the Zig launcher auto-discovers the installed compiler.
The bundled test also checks JSON spec round-trips, out-of-range failures, repeated-call determinism for the canonical integer path, and explicit unknown-token/unknown-field behavior for text, bytes, sequence, categorical, temporal, image-like, and map/object families.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```go
mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)
```

### Float

```go
mapper, _ := NewDefaultFloatRangeMapper(0.0, 10.0); mapped, _ := mapper.MapValue(5.0)
```

### Boolean

```go
mapper, _ := NewDefaultBooleanRangeMapper(); mapped := mapper.MapValue(true)
```

### Text

```go
mapper, _ := NewDefaultTextRangeMapper("alphabet", "ABC"); mapped, _ := mapper.MapValue("CA")
```

### Bytes

```go
mapper, _ := NewDefaultBytesRangeMapper(); mapped, _ := mapper.MapString("A")
```

### Temporal

```go
mapper, _ := NewDefaultTemporalRangeMapper(1700000000000, 1700000100000); mapped, _ := mapper.MapTime(time.UnixMilli(1700000050000))
```

### Image-like

```go
mapper, _ := NewDefaultImageRangeMapper(); mapped, _ := mapper.MapRows([][]byte{{0, 127}, {255}})
```

### Categorical

```go
mapper, _ := NewDefaultCategoricalRangeMapper([]any{"cat", int64(1), true}); mapped, _ := mapper.MapValue("cat")
```

### Sequences

```go
inner, _ := NewDefaultIntegerRangeMapper(0, 100)
seq, _ := NewSequenceRangeMapper(inner.MapValue, false); mapped, _ := seq.MapValue([]int64{0, 50, 100})
```

### Maps / Structs / Objects

```go
inner, _ := NewDefaultIntegerRangeMapper(0, 100)
innerJSON, _ := inner.ToJSON(); fieldMapper, _ := NewMapObjectRangeMapper([]MapObjectField{{Name: "score", Family: "integer_range", MapperJSON: innerJSON}}, false)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- JSON mapper specs reject unsupported `mapper_type` values, unsupported `spec_version` values, and malformed payloads.
- `FloatRangeMapper` accepts finite numeric values, rejects `NaN`/`Inf`, and exposes `MapIntValue` when integer input is explicitly allowed.
- `BooleanRangeMapper` accepts only `true` and `false` and never coerces other truthy/falsey values.
- `TextRangeMapper` accepts strings in `codepoint` and `alphabet` modes, and byte slices in `byte` mode; alphabet mode requires a non-empty unique alphabet.
- `BytesRangeMapper` accepts byte slices or strings, rejects empty payloads by default, and maps each byte into the configured range.
- `ImageRangeMapper` accepts grayscale byte rows and nested byte rows, preserves shape, and rejects empty image input by default.
- `CategoricalRangeMapper` accepts explicit vocabularies of strings, booleans, characters, finite numbers, and null; unknown tokens and duplicate vocabulary entries fail explicitly.
- `SequenceRangeMapper` accepts typed slices through an explicit element-mapper function, preserves nested shape when nested sequence mappers are composed, rejects empty slices by default, and fails on unsupported element mappings.
- Maps/struct-like/object-like values are mapped through explicit schemas; fields, nested maps, and typed children are documented and unknown fields fail unless `allow_unknown` is enabled.
- `TemporalRangeMapper` accepts Unix-millisecond values directly or `time.Time` values via `MapTime`, normalizing to UTC milliseconds before applying the range formula.
- The bundled test also checks repeated-call determinism for the canonical integer path and JSON round-trips for the float, boolean, text, bytes, temporal, categorical, and sequence mappers.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
