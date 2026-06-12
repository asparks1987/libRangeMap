# libRangeMap Assembly Language Runtime

This directory provides a first-party assembly reference implementation path for Alpha v1 integer mapping.

The included `librangemap.asm` contains an Intel-syntax algorithm and explicit branch points for:

- range validation
- optional clipping
- linear interpolation using integer math converted to floating-point scale

This path is intentionally low-level and designed as a reference for platform-specific build recipes.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```asm
librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.