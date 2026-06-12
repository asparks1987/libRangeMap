# libRangeMap Visual Basic Wrapper

This directory provides a first-party Visual Basic (VB.NET) wrapper path over the shared C ABI.

It keeps the runtime dependency-free and relies only on the shared `librangemap_core.dll` from the project root.

## Local validation

From this directory:

```powershell
.\test.cmd
```

The verification program checks mapping behavior, spec roundtrip, clipping, and strict-mode failures.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```vb
Dim mapped As Double = New IntegerRangeMapper(0, 100).MapValue(50)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.