# libRangeMap Ruby Wrapper

This directory provides a first-party Ruby wrapper path over the shared C ABI.

It uses only Ruby standard-library `fiddle` and the shared `librangemap_core.dll`.

## Local validation

From this directory:

```powershell
.\test.cmd
```

The verification script checks mapping, spec serialization roundtrip, clipping, and strict mode failures.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```ruby
mapped = LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(50)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.