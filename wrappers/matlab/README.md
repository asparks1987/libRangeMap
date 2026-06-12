# libRangeMap MATLAB Wrapper

This directory contains a first-party MATLAB reference for Alpha v1 integer mapping.

The implementation uses no toolbox dependencies and follows the shared linear formula and range rules.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```matlab
mapped = librangemap(50, 0, 100);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.