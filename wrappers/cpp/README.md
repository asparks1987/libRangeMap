# libRangeMap C++ Wrapper

This directory contains the first-party C++ wrapper over the shared C ABI.

It depends only on the C++ standard library and the native `librangemap_core.dll` already built by the project.

## Local validation

```powershell
.\build.cmd
.\test.cmd
```

The build script uses the repository-owned Zig launcher to compile the wrapper and verifier.
