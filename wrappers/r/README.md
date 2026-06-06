# libRangeMap R Runtime

This directory contains a first-party R runtime path for the Alpha v1 integer mapping contract.

It is dependency-free and uses only base language features.

## Contract

- Input range is a pair of integers: `c(input_min, input_max)`.
- Output range is a pair of finite floating values, default `c(-1.0, 1.0)`.
- `clip = FALSE` (default): out-of-range values raise an error.
- `clip = TRUE`: clamp to input bounds before mapping.

## Quick Check

```powershell
"C:\\Program Files\\R\\R-4.6.0\\bin\\Rscript.exe" .\librangemap.R
```

