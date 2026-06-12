# libRangeMap C# Wrapper

This directory contains the first-party C# wrapper over the shared C ABI.
Float, boolean, bytes, categorical, image-like, temporal, text, sequence, and object families are implemented here with explicit local range policy and strict failure behavior.

The wrapper depends only on the .NET runtime and the native `librangemap_core.dll` already produced by the project.

## Install/use

```powershell
dotnet run --project .\Verify\Verify.csproj
```


## 2-line quickstart

Use the exact canonical entrypoints for supported families:

`ImageRangeMapper` handles raw byte arrays and nested numeric pixel containers deterministically.

```csharp
double mapped = new LibRangeMap.IntegerRangeMapper(0, 100).MapValue(50);
```

```csharp
double floatMapped = new LibRangeMap.FloatRangeMapper(0.0, 1.0).MapValue(0.5);
double boolMapped = new LibRangeMap.BooleanRangeMapper().MapValue(true);
```

```csharp
var temporal = new LibRangeMap.TemporalRangeMapper(1_700_000_000_000, 1_700_000_100_000);
double temporalMapped = temporal.MapValue(DateTimeOffset.FromUnixTimeMilliseconds(1_700_000_050_000));
```

```csharp
var categorical = new LibRangeMap.CategoricalRangeMapper(new object[] { "cat", 1, true });
double categoricalMapped = categorical.MapValue("cat");
```

```csharp
double[] bytesMapped = new LibRangeMap.BytesRangeMapper().Map("AB");
double[] clipped = new LibRangeMap.BytesRangeMapper(0, 20, allowEmpty: false).Map(new byte[] { 0, 127, 255 });
```

```csharp
var image = new LibRangeMap.ImageRangeMapper();
object[] imageMapped = (object[])image.Map(new object[]
{
    new object[] { 0, 128, 255 },
    new object[] { 64, 192, 32 }
});
```

```csharp
var seqMapped = new LibRangeMap.SequenceRangeMapper(new LibRangeMap.IntegerRangeMapper(0, 3), allowEmpty: false);
var sequence = seqMapped.Map(new object[] { 0, new object[] { 1, 2 }, 3 });
```

```csharp
double textMapped = new LibRangeMap.TextRangeMapper().MapValue('A');
double[] textArray = new LibRangeMap.TextRangeMapper("alphabet", alphabet: "ABC").Map("ABC");
```

```csharp
var mapMapper = new LibRangeMap.ObjectRangeMapper(
    new Dictionary<string, object>
    {
        ["age"] = new LibRangeMap.IntegerRangeMapper(0, 120),
        ["active"] = new LibRangeMap.BooleanRangeMapper()
    });
var mappedRecord = mapMapper.Map(new Dictionary<string, object> { ["age"] = 30, ["active"] = true });
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Bytes family:
  - accepted inputs are UTF-8 strings and `byte[]`/`ReadOnlySpan<byte>` payloads.
  - empty payload is invalid unless `allowEmpty=true`.
  - strict mode rejects values outside configured input range; clipping mode clamps.
- Image family:
  - accepted inputs are raw byte arrays and nested numeric arrays representing grayscale or pixel channels.
  - empty payload is invalid unless `allowEmpty=true`.
  - strict mode rejects values outside 0..255; clipping mode clamps.
- Temporal family:
  - accepted inputs are `DateTimeOffset` and `DateTime` values, with `DateTimeKind.Unspecified` rejected explicitly.
  - values are normalized as UTC Unix milliseconds before range mapping.
  - strict mode rejects values outside the configured epoch-millisecond range; clipping mode clamps.
- Categorical family:
  - accepted vocabulary tokens are strings, booleans, characters, finite numbers, and null.
  - vocabulary must be non-empty, and duplicate tokens are rejected during construction.
  - unknown tokens fail explicitly with a typed error.
- Sequence family:
  - accepted inputs are arrays/lists of supported element values and nested containers of those.
  - mapping is shape-preserving and recursion is applied to nested containers.
  - unknown element types and dict-like containers are rejected explicitly.
  - empty sequence payload is rejected unless `allowEmpty=true`.
- Map/Object family:
  - accepted inputs are dictionaries with string keys and object instances with readable public fields/properties.
  - unknown input keys fail unless `allowUnknown=true`.
  - missing required schema fields fail unless `missingValue` is configured.
  - empty map/object payload is invalid unless `allowEmpty=true`.
- The bundled verify app exercises bytes repeated mapping, explicit missing-field
  rejection, image mapping, empty-alphabet rejection, nested map/object composition twice, and
  repeated-call behavior in addition to the scalar smoke cases.
- Text family:
  - accepted modes are `codepoint`, `alphabet`, and `byte`.
  - `alphabet` mode requires a non-empty alphabet (minimum 2 symbols) and unknown symbols are explicit errors.
  - strict mode rejects out-of-range values unless clipping is enabled.
  - empty text is invalid unless `allowEmpty=true`.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.

