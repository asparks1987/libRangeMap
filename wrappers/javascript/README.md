# libRangeMap JavaScript Wrapper

This directory contains the first-party JavaScript runtime path for `libRangeMap`.

It depends only on Node's standard library and keeps the integer mapping contract dependency-free.

## Local validation

```powershell
node --test .\wrappers\javascript\test.js
```

The implementation is intentionally small and mirrors the shared integer mapping contract used by the rest of the project.
