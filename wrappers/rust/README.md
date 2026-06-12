# libRangeMap Rust Wrapper

This directory contains the first-party Rust wrapper over the shared C ABI.

It depends only on the Rust standard library and the native `librangemap_core.dll` already built by the project.

## Local validation

```powershell
.\test.cmd
```

The build and test scripts route linking through Rust's own `rust-lld` so the wrapper stays dependency-free on Windows.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```rust
let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.