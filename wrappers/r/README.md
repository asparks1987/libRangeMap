# libRangeMap R Runtime

This directory contains a first-party R runtime path for the Alpha v1 mapping contract, including integer, float, and boolean families.

It is dependency-free and uses only base language features.

## Contract

- Integer input range is a pair of integers: `c(input_min, input_max)`.
- Float input range is a pair of finite numbers, default output range is `c(-1.0, 1.0)`.
- Boolean values map `FALSE`/`TRUE` via explicit false/true policy values.
- Output range is a pair of finite floating values, default `c(-1.0, 1.0)`.
- `clip = FALSE` (default): out-of-range values raise an error.
- `clip = TRUE`: clamp to input bounds before mapping.

## Quick Check

```powershell
"C:\\Program Files\\R\\R-4.6.0\\bin\\Rscript.exe" .\librangemap.R
```



## Quickstart examples

Use canonical entrypoints for the supported families:

```r
mapped <- map_integer_value(50, 0, 100)
```

```r
mapped <- map_float_value(0.5, 0.0, 1.0)
```

```r
mapped <- map_boolean_value(TRUE)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Boolean mapping requires TRUE/FALSE input and explicit false/true policy values.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
