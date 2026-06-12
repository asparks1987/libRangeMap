# libRangeMap Ada Wrapper

This directory contains a first-party Ada implementation path for Alpha v1 integer mapping.

No external dependencies are required; this package uses only the Ada runtime and standard packages.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```ada
mapped : Long_Float := Map_Integer_Value(50, 0, 100, -1.0, 1.0, False);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.