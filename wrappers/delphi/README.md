# libRangeMap Delphi/Object Pascal Wrapper

This directory contains a first-party Delphi/Object Pascal implementation of the Alpha v1 integer mapper.

It is a dependency-free reference implementation that follows the shared mapping contract:

- validates input bounds and output bounds
- strict mode by default, optional clipping mode
- deterministic output in `[output_min, output_max]` with finite inputs


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```pascal
mapped := MapIntegerValue(50, 0, 100, -1, 1, False);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.