# libRangeMap Java Wrapper

This directory contains a first-party Java wrapper over the shared C ABI.

The wrapper depends only on the JDK and the native `librangemap_java.dll` built from the project sources.

## Install/use

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
.\build.cmd
.\test.cmd
```

The build script uses the repository-owned Zig launcher to compile the JNI bridge.
The test script adds both native DLL directories to `PATH` so the JVM can load the JNI bridge and the shared C core on Windows.

## 2-line quickstart

Use the exact canonical entrypoints for supported families:

```java
double mapped = new librangemap.IntegerRangeMapper(0, 100).mapValue(50);
double clipped = new librangemap.IntegerRangeMapper(0, 10, -1.0, 1.0, true).mapValue(-5);
```

```java
double floatMapped = new librangemap.FloatRangeMapper(0.0, 1.0).mapValue(0.5);
double boolMapped = new librangemap.BooleanRangeMapper().mapValue(true);
```

```java
double[] mappedText = new librangemap.TextRangeMapper().map("ab");
double[] mappedBytes = new librangemap.BytesRangeMapper().mapValue("ab");
```

```java
double mappedCategory = new librangemap.CategoricalRangeMapper(new Object[] {"cat", "dog"}).mapValue("dog");
```

```java
var catLabels = new librangemap.CategoricalRangeMapper(new Object[] {"cat", "dog", null});
double mappedNull = catLabels.mapValue(null);
```

```java
var temporal = new librangemap.TemporalRangeMapper(
    0.0,
    60.0,
    -1.0,
    1.0,
    false,
    "duration",
    0.0,
    "naive_is_utc",
    null
);
double midMinute = temporal.mapValue(java.time.Duration.ofSeconds(30));
```

```java
var image = new librangemap.ImageRangeMapper();
Object[] mappedImage = (Object[]) image.mapValue(new Object[] {
    new Object[] {0, 128, 255},
    new Object[] {64, 192, 32}
});
```

```java
Object[] mappedSeq = (Object[]) new librangemap.SequenceRangeMapper(
    new librangemap.IntegerRangeMapper(0, 100)
).mapValue(new Object[] {0, new Object[] {25, 50}, 100});
```

```java
var schema = new java.util.LinkedHashMap<String, Object>();
schema.put("age", new librangemap.IntegerRangeMapper(0, 120));
schema.put("active", new librangemap.BooleanRangeMapper());
var profile = new librangemap.ObjectRangeMapper(schema);
java.util.Map<String, Object> mapped = profile.map(new java.util.LinkedHashMap<String, Object>() {{
    put("age", 42);
    put("active", true);
}});
```

### Failure contract

- Out-of-range values in strict mode are explicit `IllegalArgumentException` failures.
- Enable clipping in the runtime API (`clip = true`) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `BytesRangeMapper` accepts raw UTF-8 `String`, `byte[]`, or `int[]` values.
- Empty bytes inputs are invalid unless `allowEmpty = true`.
- Unknown byte values in strict mode fail with explicit bounds messages.
- `SequenceRangeMapper` preserves container shape and fails explicit on unknown nested element types.
- `ObjectRangeMapper` requires explicit schema declarations, rejects unknown object keys unless `allowUnknown = true`,
  and requires explicit missing-field policy when fields are absent.
- `ObjectRangeMapper` maps Java objects and maps only through explicit member schemas; unsupported member types fail explicitly.
- `CategoricalRangeMapper` supports explicit vocabularies for strings/numbers/booleans/characters/null, rejects empty vocabularies, and rejects unknown tokens.
- `TemporalRangeMapper` supports explicit temporal modes (`auto`, `timestamp`, `duration`, `datetime`, `time`) and epoch/policy handling, and rejects malformed temporal inputs explicitly.
- `ImageRangeMapper` supports nested grayscale and RGB/RGBA-style pixel arrays plus raw byte arrays, preserves shape, and rejects malformed pixels explicitly.
- The bundled verifier exercises nested sequence/object composition twice to confirm deterministic repeated-call behavior in addition to the scalar, temporal, image, and bytes smoke cases.
- The bundled verifier also exercises repeated integer mapping on the canonical path.
- The bundled verifier also exercises a nested map/sequence/categorical JSON
  round-trip to confirm composite serialization stays deterministic.
- The bundled verifier also exercises bytes repeated mapping and round-trip mapping
  to confirm deterministic byte handling.
- The bundled verifier also exercises explicit missing-field rejection when no
  fallback policy is configured.
- Unknown category values (including unsupported token kinds) fail with explicit `IllegalArgumentException`.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
