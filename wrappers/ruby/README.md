# libRangeMap Ruby Wrapper

This directory provides a first-party Ruby wrapper path over the shared C ABI.

It uses only Ruby standard-library `fiddle` and the shared `librangemap_core.dll`.

## Local validation

From this directory:

```powershell
.\test.cmd
```

The verification script checks mapping, spec serialization roundtrip, clipping, and strict mode failures.
