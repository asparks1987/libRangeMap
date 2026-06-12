# libRangeMap Fortran Wrapper

This directory provides a first-party Fortran 2008 reference implementation for Alpha v1 integer mapping.

No external libraries are required.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```fortran
x = map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.