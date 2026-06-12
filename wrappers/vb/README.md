# libRangeMap Visual Basic Wrapper

This directory provides a first-party Visual Basic (VB.NET) wrapper path over the shared C ABI.

It keeps the runtime dependency-free and relies only on the shared `librangemap_core.dll` from the project root.

Current scope: integer, float, boolean, text, bytes, image-like, sequences, categorical, temporal, and map/object range mapping. Broader family coverage is tracked in `docs/compatibility.md`.

## Install/use

From this directory:

```powershell
.\test.cmd
```

The verification program now includes object/schema mapping checks, including unknown-field rejection and map/object spec round-trip verification, alongside mapping behavior, spec roundtrip, repeated-call determinism, clipping, and strict-mode failures.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```vb
Dim mapper As New IntegerRangeMapper(0, 100)
Dim mapped As Double = mapper.MapValue(50)
```

```vb
Dim floatMapper As New FloatRangeMapper(0.0, 1.0)
Dim floatMapped As Double = floatMapper.MapValue(0.5)
```

```vb
Dim booleanMapper As New BooleanRangeMapper()
Dim booleanMapped As Double = booleanMapper.MapValue(True)
```

```vb
Dim textMapper As New TextRangeMapper()
Dim textMapped() As Double = textMapper.MapValue("Ada")
```

```vb
Dim bytesMapper As New BytesRangeMapper()
Dim bytesMapped() As Double = bytesMapper.MapValue(System.Text.Encoding.UTF8.GetBytes("abc"))
```

```vb
Dim imageMapper As New ImageRangeMapper()
Dim imageMapped() As Double = imageMapper.MapValue(New Byte() {0, 127, 255}, width:=1, height:=1, channels:=3)
```

```vb
Dim categoricalMapper As New CategoricalRangeMapper(New String() {"cat", "dog"})
Dim categoricalMapped As Double = categoricalMapper.MapValue("cat")
```

```vb
Dim sequenceMapper As New SequenceRangeMapper(Of Long, Double)(Function(value As Long) New IntegerRangeMapper(0, 100).MapValue(value))
Dim sequenceMapped() As Double = sequenceMapper.MapValue(New Long() {0, 50, 100})
```

```vb
Dim temporalMapper As New TemporalRangeMapper(1700000000000, 1700000100000)
Dim temporalMapped As Double = temporalMapper.MapValue(New DateTimeOffset(2023, 11, 14, 0, 0, 50, TimeSpan.Zero))
```



```vb
Dim objectSchema = New Dictionary(Of String, Object)(StringComparer.Ordinal) From {
    {"tag", New CategoricalRangeMapper(New String() {"ok", "warn", "err"})},
    {"score", New FloatRangeMapper(0.0, 1.0)}
}
Dim objectMapper As New ObjectRangeMapper(objectSchema)
Dim objectInput As New Dictionary(Of String, Object)(StringComparer.Ordinal) From {
    {"tag", "ok"},
    {"score", 0.5}
}
Dim objectMapped As Dictionary(Of String, Object) = objectMapper.Map(objectInput)
```
### Failure contract

- Invalid ranges fail explicitly during construction.
- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Unknown/unsupported types and malformed values fail explicitly.
- `FloatRangeMapper` rejects `NaN`/`Inf`, invalid ranges, and out-of-range values unless clipping is enabled.
- `BooleanRangeMapper` keeps `false`/`true` mappings explicit and rejects invalid spec metadata.
- `TextRangeMapper` maps strings as codepoint, byte, or alphabet vectors, rejects empty input by default, and fails on unknown or duplicate alphabet tokens.
- `BytesRangeMapper` maps strings or byte arrays, rejects empty payloads by default, and preserves order.
- `ImageRangeMapper` maps raw byte arrays with explicit `width`, `height`, and `channels` shape metadata, rejects malformed shapes, and preserves channel order.
- `SequenceRangeMapper` maps typed arrays through an explicit element mapper, preserves nested shape when nested sequence mappers are composed, rejects empty arrays by default, and fails on unsupported element mappings.
- `ObjectRangeMapper` maps dictionary or object-like inputs from explicit schemas, rejects unknown fields unless `allowUnknown=True`, and rejects missing required fields unless a missing-value policy is configured.
- `CategoricalRangeMapper` accepts a non-empty explicit string vocabulary and rejects unknown or duplicate tokens.
- `TemporalRangeMapper` accepts Unix-millisecond integers and `DateTime` / `DateTimeOffset` values, normalizing to UTC milliseconds before applying the range formula.
- The bundled verification program also checks repeated-call determinism for integer, float, boolean, bytes, image-like, categorical, temporal, sequence, and object/schema inputs.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
