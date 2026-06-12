# libRangeMap C++ Wrapper

This directory contains the first-party C++ wrapper family for libRangeMap.
Float and boolean families are implemented in this wrapper with explicit local
range policy and strict failure behavior.

It depends only on the C++ standard library and the native `librangemap_core.dll` already built by the project.

## Local validation

```powershell
.\build.cmd
.\test.cmd
```

The build script uses the repository-owned Zig launcher to compile the wrapper and verifier.


## 2-line quickstart

Use the exact canonical one-liners for this runtime:

```cpp
double mapped = librangemap::IntegerRangeMapper(0, 100).map_value(50);
double float_mapped = librangemap::FloatRangeMapper(0.0, 1.0).map_value(0.5);
double bool_mapped = librangemap::BooleanRangeMapper().map_value(true);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
