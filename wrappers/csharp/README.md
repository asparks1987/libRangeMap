# libRangeMap C# Wrapper

This directory contains the first-party C# wrapper over the shared C ABI.

The wrapper depends only on the .NET runtime and the native `librangemap_core.dll` already produced by the project.

## Local validation

```powershell
dotnet run --project .\Verify\Verify.csproj
```


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```csharp
double mapped = new LibRangeMap.IntegerRangeMapper(0, 100).MapValue(50);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
