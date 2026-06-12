# libRangeMap Ruby Wrapper

This directory provides a first-party Ruby wrapper path over the shared C ABI.

It uses only Ruby standard-library `fiddle` and the shared `librangemap_core.dll`.
Current scope: integer, float, boolean, text, bytes, sequences, categorical, map/object, temporal, and image-like mapping.

## Install/use

From this directory:

```powershell
.\test.cmd
```

The verification script checks mapping, spec serialization roundtrip, clipping, strict mode failures, and default empty-bytes rejection.
It also checks the dependency-free float and boolean families, the text, bytes, sequence, categorical, and temporal families, and repeated deterministic mapping for the same input.
Object and image-like smoke paths are now explicit in this release.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```ruby
mapped = LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(50)
```

### Float

```ruby
mapped = LibrangeMap::FloatRangeMapper.new(0.0, 10.0).map_value(5.0)
```

### Boolean

```ruby
mapped = LibrangeMap::BooleanRangeMapper.new(-1.0, 1.0).map_value(true)
```

### Text

```ruby
mapper = LibrangeMap::TextRangeMapper.new(-1.0, 1.0, "alphabet", "ABC")
mapped = mapper.map_value("AC")
```

### Bytes

```ruby
bytes_mapper = LibrangeMap::BytesRangeMapper.new
mapped = bytes_mapper.map_value([0, 127, 255])
```

### Sequences

```ruby
mapper = LibrangeMap::SequenceRangeMapper.new(->(value) { LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(value) })
mapped = mapper.map_value([0, 50, 100])
```

### Temporal

```ruby
mapped = LibrangeMap::TemporalRangeMapper.new(-10.0, 10.0).map_value(Time.at(0).utc)
```

### Map/Object

```ruby
mapper = LibrangeMap::ObjectRangeMapper.new(
  "age" => LibrangeMap::IntegerRangeMapper.new(0, 130),
  "active" => LibrangeMap::BooleanRangeMapper.new(-1.0, 1.0),
)
mapped = mapper.map_value({ "age" => 42, "active" => true })
```

### Image-like

```ruby
mapper = LibrangeMap::ImageRangeMapper.new
mapped = mapper.map_value([[0, 127, 255], [64, 192, 32]])
```

### Categorical

```ruby
mapper = LibrangeMap::CategoricalRangeMapper.new(["cat", 1, true])
mapped = mapper.map_value("cat")
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `FloatRangeMapper` accepts finite numeric scalars and rejects `NaN`/`Inf`; `allow_integer` is explicit policy.
- `BooleanRangeMapper` accepts only `true` and `false` by default and rejects unknown truthy/falsey inputs.
- `TextRangeMapper` accepts `String` inputs for `codepoint` and `alphabet` modes, and `String` or integer arrays for `byte` mode; alphabet mode requires a non-empty alphabet with at least two unique characters.
- `BytesRangeMapper` accepts `String` and integer arrays; empty input is invalid unless `allow_empty=true`.
- `SequenceRangeMapper` accepts Array inputs, maps nested Arrays recursively, and rejects empty arrays by default unless `allow_empty=true`.
- `CategoricalRangeMapper` accepts only JSON-serializable scalar vocabulary tokens, preserves boolean and numeric distinctions, and rejects unknown or unsupported tokens explicitly.
- `ObjectRangeMapper` requires explicit schemas, rejects unknown fields unless `allow_unknown=true`, supports per-field missing-value fill policy, and rejects missing required fields by default.
- `TemporalRangeMapper` accepts `Time`, `DateTime`, and numeric timestamps and maps them against explicit epoch ranges.
- `ImageRangeMapper` accepts nested numeric image-like arrays (grayscale or channel-grouped pixels), uses explicit mode policy (`auto`, `rgb`, `rgba`), and rejects malformed shapes explicitly.
- The bundled verification script exercises integer, float, boolean, text, bytes, sequence, categorical, and temporal smoke cases plus repeated deterministic mapping.
- The bundled verification script also exercises default empty-bytes rejection, object strictness, image-like determinism, plus categorical unknown-token, unknown-type, and duplicate-vocabulary rejection.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
