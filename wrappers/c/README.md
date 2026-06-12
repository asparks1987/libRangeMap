# libRangeMap C Wrapper

This directory provides a first-party C wrapper path over the shared C ABI.

The wrapper keeps behavior explicit in C while preserving the same validation,
error codes, and mapping contract as `csrc/librangemap_core.h`.

## Local validation

From this directory:

```powershell
.\test.cmd
```

The verification build uses the repository-owned Zig compiler launcher and does not
require third-party runtime libraries.


## 2-line quickstart

Use the exact canonical entrypoint for this runtime:

```c
double mapped;
lrm_map_integer(0, 100, -1.0, 1.0, 0, 50, &mapped);
lrm_map_float(0.0, 1.0, -1.0, 1.0, 0, 0.5, &mapped);
lrm_map_boolean(-1.0, 1.0, -1.0, 1.0, 1, &mapped); // true -> 1.0
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
