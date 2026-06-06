# libRangeMap Rust Wrapper

This directory contains the first-party Rust wrapper over the shared C ABI.

It depends only on the Rust standard library and the native `librangemap_core.dll` already built by the project.

## Local validation

```powershell
.\test.cmd
```

The build and test scripts route linking through Rust's own `rust-lld` so the wrapper stays dependency-free on Windows.
