# libRangeMap Java Wrapper

This directory contains the first-party Java wrapper over the shared C ABI.

The wrapper depends only on the JDK and the native `librangemap_java.dll` built from the project sources.

## Local validation

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
.\build.cmd
.\test.cmd
```

The build script uses the repository-owned Zig launcher to compile the JNI bridge.
The test script adds both native DLL directories to `PATH` so the JVM can load the JNI bridge and the shared C core on Windows.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```java
double mapped = new librangemap.IntegerRangeMapper(0, 100).mapValue(50);
```

### Sequence support

```java
Object mapped = new librangemap.SequenceRangeMapper(new librangemap.IntegerRangeMapper(0, 100))
    .mapValue(new Object[] {0, new Object[] {25, 50}, 100});
```

### Text support

```java
double[] mapped = new librangemap.TextRangeMapper().map("ab");
double[] vocabMapped = new librangemap.TextRangeMapper(-1.0, 1.0, "alphabet", "abc", false, true, "labels")
    .map("cab");
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
