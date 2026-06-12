# libRangeMap Classic VB6 Runtime Path

This directory contains a first-party Visual Basic 6 reference module path for Alpha v1.

It documents a classic-VB-compatible mapping formula and strict/clipping behavior.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```vb
mapped = MapIntegerValue(50, 0, 100, -1, 1, False)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.