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
