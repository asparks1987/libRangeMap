# libRangeMap Swift Wrapper

This directory contains a first-party Swift runtime path for Alpha v1 integer mapping.

No third-party packages are used; it relies only on the Swift standard library.

```powershell
# When swift is available:
swiftc .\LibrangeMap.swift -o .\librangemap-swift && .\librangemap-swift
```


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```swift
let mapped = IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue(50)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.