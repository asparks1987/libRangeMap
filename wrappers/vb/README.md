# libRangeMap Visual Basic Wrapper

This directory provides a first-party Visual Basic (VB.NET) wrapper path over the shared C ABI.

It keeps the runtime dependency-free and relies only on the shared `librangemap_core.dll` from the project root.

## Local validation

From this directory:

```powershell
.\test.cmd
```

The verification program checks mapping behavior, spec roundtrip, clipping, and strict-mode failures.
