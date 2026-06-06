# libRangeMap Assembly Language Runtime

This directory provides a first-party assembly reference implementation path for Alpha v1 integer mapping.

The included `librangemap.asm` contains an Intel-syntax algorithm and explicit branch points for:

- range validation
- optional clipping
- linear interpolation using integer math converted to floating-point scale

This path is intentionally low-level and designed as a reference for platform-specific build recipes.
