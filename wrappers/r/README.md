# libRangeMap R Runtime

This directory contains a first-party R runtime path for the Alpha v1 mapping contract, including integer, float, boolean, text, bytes, sequences, categorical, temporal, image-like, and map/object families.

It is dependency-free and uses only base language features.

## Contract

- Integer input range is a pair of integers: `c(input_min, input_max)`.
- Float input range is a pair of finite numbers, default output range is `c(-1.0, 1.0)`.
- Boolean values map `FALSE`/`TRUE` via explicit false/true policy values.
- Bytes map from raw vectors, strings, or numeric byte vectors into normalized doubles.
- Text values map as UTF-8 code points or bytes with explicit mode selection.
- Sequences map recursively through explicit element mappers while preserving nested shape.
- Temporal values map from `Date`, `POSIXct`, `POSIXlt`, or numeric timestamps against explicit epoch ranges.
- Image-like values map raw vectors, numeric pixel vectors, or nested lists recursively into the configured range.
- Map/object values map through explicit field schemas, preserving field order and rejecting unknown fields unless allowed.
- Output range is a pair of finite floating values, default `c(-1.0, 1.0)`.
- `clip = FALSE` (default): out-of-range values raise an error.
- `clip = TRUE`: clamp to input bounds before mapping.

## Quick Check

```powershell
"C:\\Program Files\\R\\R-4.6.0\\bin\\Rscript.exe" .\librangemap.R
```

## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use canonical entrypoints for the supported families:

```r
mapped <- map_integer_value(50, 0, 100)
mapped_float <- map_float_value(0.5, 0.0, 1.0)
```

```r
mapped_bool <- map_boolean_value(TRUE)
```

```r
mapped_bytes <- map_bytes_value(as.raw(c(0, 255)))
```

```r
mapped_text <- map_text_value("AB")
```

```r
seq_mapper <- create_sequence_mapper(function(x) map_integer_value(x, 0, 100))
mapped_seq <- map_sequence(seq_mapper, list(0, list(25, 50)))
```

```r
mapped_category <- map_categorical_value("cat", c("cat", "dog"))
```

```r
mapped_time <- map_temporal_value(as.POSIXct("1970-01-01 00:00:00", tz = "UTC"), -10.0, 10.0)
```

```r
mapped_image <- map_image_value(as.raw(c(0, 127, 255)))
```

```r
object_mapper <- create_object_mapper(list(
  tag = function(value) map_categorical_value(value, c("ok", "warn", "err")),
  score = function(value) map_float_value(value, 0.0, 1.0)
))
mapped_object <- map_object(object_mapper, list(tag = "warn", score = 0.5))
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Boolean mapping requires TRUE/FALSE input and explicit false/true policy values.
- Byte mapping requires raw, string, or numeric byte-vector input and preserves deterministic normalization.
- Text mapping requires a single string and maps either UTF-8 code points or bytes with an explicit mode.
- Sequence mapping requires an explicit element mapper, preserves nested shape, and rejects empty sequences by default.
- Categorical mapping requires a non-empty character vocabulary and rejects unknown or duplicate tokens.
- Temporal mapping requires Date/POSIXct/POSIXlt or numeric timestamp input and explicit epoch ranges.
- Image-like mapping requires raw vectors, numeric pixel vectors, or nested lists and preserves shape recursively.
- Map/object mapping requires explicit schemas, rejects unknown fields unless allow_unknown=TRUE, and rejects missing required fields unless has_missing_value is TRUE.
- The bundled self-check also exercises repeated integer mapping on the canonical path plus bytes, text, sequence, categorical, temporal, and image-like mapping.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
