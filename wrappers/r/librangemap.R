# libRangeMap for R
#
# Dependency-free integer mapping implementation for Alpha v1.

map_integer_value <- function(value, input_min, input_max, output_min = -1.0, output_max = 1.0, clip = FALSE) {
  if (length(input_min) != 1L || length(input_max) != 1L) {
    stop("input_min and input_max must be single values")
  }
  if (!is.numeric(input_min) || !is.numeric(input_max) || !is.finite(input_min) || !is.finite(input_max)) {
    stop("input_min and input_max must be finite numbers")
  }
  if (!is.numeric(value) || !is.finite(value)) {
    stop("value must be finite")
  }
  if (value != as.integer(value)) {
    stop("value must be an integer for Alpha v1")
  }

  input_min <- as.integer(input_min)
  input_max <- as.integer(input_max)
  if (input_min >= input_max) stop("input_min must be less than input_max")

  if (output_min >= output_max) stop("output_min must be less than output_max")
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }

  if (clip) {
    if (value < input_min) value <- input_min
    if (value > input_max) value <- input_max
  } else if (value < input_min || value > input_max) {
    stop("value is out of range")
  }

  output_span <- output_max - output_min
  input_span <- as.double(input_max - input_min)
  output_min + ((as.double(value) - as.double(input_min)) / input_span) * output_span
}

map_float_value <- function(value, input_min, input_max, output_min = -1.0, output_max = 1.0, clip = FALSE) {
  if (length(input_min) != 1L || length(input_max) != 1L) {
    stop("input_min and input_max must be single values")
  }
  if (!is.numeric(input_min) || !is.numeric(input_max) || !is.finite(input_min) || !is.finite(input_max)) {
    stop("input_min and input_max must be finite numbers")
  }
  if (!is.numeric(value) || !is.finite(value)) {
    stop("value must be finite")
  }
  if (input_min >= input_max) stop("input_min must be less than input_max")
  if (output_min >= output_max) stop("output_min must be less than output_max")
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }
  if (value < input_min) {
    if (clip) value <- input_min else stop("value is out of range")
  } else if (value > input_max) {
    if (clip) value <- input_max else stop("value is out of range")
  }
  output_span <- output_max - output_min
  input_span <- as.double(input_max - input_min)
  output_min + ((as.double(value) - as.double(input_min)) / input_span) * output_span
}

map_boolean_value <- function(value, output_min = -1.0, output_max = 1.0, false_value = output_min, true_value = output_max) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop("value must be a non-missing boolean")
  }
  if (output_min >= output_max) {
    stop("output_min must be less than output_max")
  }
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.numeric(false_value) || !is.numeric(true_value)) {
    stop("output values must be numeric")
  }
  if (!is.finite(output_min) || !is.finite(output_max) || !is.finite(false_value) || !is.finite(true_value)) {
    stop("output values must be finite")
  }
  if (false_value < output_min || false_value > output_max || true_value < output_min || true_value > output_max) {
    stop("false_value/true_value must be within output range")
  }
  if (identical(false_value, true_value)) {
    stop("false_value and true_value must be different")
  }
  if (value) true_value else false_value
}

create_mapper <- function(input_range, output_range = c(-1.0, 1.0), clip = FALSE) {
  if (length(input_range) != 2L) stop("input_range must contain exactly two integers")
  if (length(output_range) != 2L) stop("output_range must contain exactly two numbers")
  if (input_range[1] >= input_range[2]) stop("input_range must be strictly increasing")
  if (output_range[1] >= output_range[2]) stop("output_range must be strictly increasing")

  structure(
    list(
      input_range = as.integer(input_range),
      output_range = as.numeric(output_range),
      clip = as.logical(clip)
    ),
    class = "librangemap_integer_mapper"
  )
}

create_float_mapper <- function(input_range, output_range = c(-1.0, 1.0), clip = FALSE) {
  if (length(input_range) != 2L) stop("input_range must contain exactly two numbers")
  if (length(output_range) != 2L) stop("output_range must contain exactly two numbers")
  if (input_range[1] >= input_range[2]) stop("input_range must be strictly increasing")
  if (output_range[1] >= output_range[2]) stop("output_range must be strictly increasing")
  structure(
    list(
      input_range = as.double(input_range),
      output_range = as.numeric(output_range),
      clip = as.logical(clip)
    ),
    class = "librangemap_float_mapper"
  )
}

create_boolean_mapper <- function(output_range = c(-1.0, 1.0), false_value = output_range[1], true_value = output_range[2]) {
  if (length(output_range) != 2L) stop("output_range must contain exactly two numbers")
  if (output_range[1] >= output_range[2]) stop("output_range must be strictly increasing")
  structure(
    list(
      output_range = as.numeric(output_range),
      false_value = as.numeric(false_value),
      true_value = as.numeric(true_value)
    ),
    class = "librangemap_boolean_mapper"
  )
}

map_value <- function(mapper, value) {
  map_integer_value(
    value = value,
    input_min = mapper$input_range[1],
    input_max = mapper$input_range[2],
    output_min = mapper$output_range[1],
    output_max = mapper$output_range[2],
    clip = mapper$clip
  )
}

map_float <- function(mapper, value) {
  map_float_value(
    value = value,
    input_min = mapper$input_range[1],
    input_max = mapper$input_range[2],
    output_min = mapper$output_range[1],
    output_max = mapper$output_range[2],
    clip = mapper$clip
  )
}

map_boolean <- function(mapper, value) {
  map_boolean_value(
    value = value,
    output_min = mapper$output_range[1],
    output_max = mapper$output_range[2],
    false_value = mapper$false_value,
    true_value = mapper$true_value
  )
}

if (identical(environment(), globalenv())) {
  # Self-check when sourced directly.
  m <- create_mapper(c(0, 100), clip = FALSE)
  stopifnot(identical(map_value(m, 0), -1.0))
  stopifnot(identical(map_value(m, 50), 0.0))
  stopifnot(identical(map_value(m, 100), 1.0))

  fm <- create_float_mapper(c(0.0, 1.0), c(-1.0, 1.0), clip = FALSE)
  stopifnot(isTRUE(all.equal(map_float(fm, 0.0), -1.0)))
  stopifnot(isTRUE(all.equal(map_float(fm, 0.5), 0.0)))
  stopifnot(isTRUE(all.equal(map_float(fm, 1.0), 1.0)))

  bm <- create_boolean_mapper(c(-1.0, 1.0), false_value = -1.0, true_value = 1.0)
  stopifnot(identical(map_boolean(bm, TRUE), 1.0))
  stopifnot(identical(map_boolean(bm, FALSE), -1.0))
}
