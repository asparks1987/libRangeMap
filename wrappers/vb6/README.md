# libRangeMap Classic VB6 Runtime Path

This directory contains a first-party Visual Basic 6 reference module path for Alpha v1 integer, float, boolean, text, sequences, categorical, bytes, temporal, image-like, and map/object mapping.

It documents a classic-VB-compatible mapping formula and strict/clipping behavior.

Current scope: integer, float, boolean, text, sequences, categorical, bytes, temporal, image-like, and map/object mapping. Broader family coverage is tracked in `docs/compatibility.md`.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```vb
Dim mapper As Variant
mapper = MapIntegerValue(50, 0, 100, -1, 1, False)
```

```vb
Dim x As Double
x = MapFloatValue(0.5, 0#, 1#, -1#, 1#, False)
```

```vb
Dim y As Double
y = MapBooleanValue(True, -1#, 1#, -1#, 1#)
```

```vb
Dim textMapped As Variant
textMapped = MapTextValue("cab", -1#, 1#, "alphabet", "abc", False, False)
```

```vb
Dim tokens(0 To 2) As Variant
tokens(0) = "red"
tokens(1) = "green"
tokens(2) = "blue"
Dim c As Double
c = MapCategoricalValue("green", tokens, -1#, 1#)
```

```vb
Dim seq As Variant
seq = MapIntegerSequenceValue(Array(0, 50, 100), 0, 100, -1#, 1#, False)
```

```vb
Dim image As Variant
image = MapImageValue(Array(Array(CByte(0), CByte(127)), Array(CByte(255))), -1#, 1#, False, False)
```

```vb
Dim raw As Object
Set raw = CreateObject("Scripting.Dictionary")
raw.Add "age", 42
raw.Add "active", True

Dim schema As Object
Set schema = CreateObject("Scripting.Dictionary")
schema.Add "age", Array("integer", 0, 100, False)
schema.Add "active", Array("boolean")

Dim mappedObject As Object
Set mappedObject = MapObjectValue(raw, schema)
```

```vb
Dim b() As Byte
b = StrConv("abc", vbFromUnicode)
Dim bytesMapped As Variant
bytesMapped = MapBytesValue(b, -1#, 1#, False, False)
```

```vb
Dim temporalMapped As Double
temporalMapped = MapTemporalValue(1700000050#, 1700000000#, 1700000100#, -1#, 1#, False)
```

### Failure contract

- Invalid ranges fail explicitly before mapping begins.
- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Unknown/unsupported types and malformed values fail explicitly.
- `NaN`/`Inf` are rejected by the float family.
- Boolean mapping uses explicit false/true policy values and rejects invalid metadata.
- Text mapping accepts Unicode strings in `codepoint` mode and explicit alphabets in `alphabet` mode, rejects unknown characters explicitly, and requires at least two unique alphabet characters.
- Categorical mapping requires a non-empty unique token array, maps by stable token order, and rejects unknown tokens explicitly.
- Bytes mapping accepts byte arrays, rejects non-numeric items and out-of-range values explicitly, and preserves order.
- Sequence mapping accepts `Variant` arrays, preserves nested shape for nested arrays, rejects empty arrays by default, and maps each element through the same explicit range policy.
- Temporal mapping accepts explicit epoch-second numbers and applies the same explicit range/clipping policy as the scalar families.
- Map/object mapping accepts `Scripting.Dictionary` records plus explicit schema dictionaries; unknown fields are explicit errors unless `allowUnknownFields=True`, missing fields are errors unless `allowMissing=True`, and output keys are deterministically sorted by field name before mapping.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.




