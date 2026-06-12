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

map_categorical_value <- function(value, vocabulary, output_min = -1.0, output_max = 1.0) {
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    stop("value must be a single non-missing string")
  }
  if (!is.character(vocabulary) || length(vocabulary) == 0L) {
    stop("vocabulary must be a non-empty character vector")
  }
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }
  if (output_min >= output_max) stop("output_min must be less than output_max")
  if (any(is.na(vocabulary)) || any(vocabulary == "")) stop("vocabulary tokens must be non-empty strings")
  if (any(duplicated(vocabulary))) stop("vocabulary must not contain duplicate tokens")

  index <- match(value, vocabulary)
  if (is.na(index)) stop("unknown categorical token")

  if (length(vocabulary) == 1L) {
    return((output_min + output_max) / 2.0)
  }

  output_span <- output_max - output_min
  output_min + ((as.double(index - 1L) / as.double(length(vocabulary) - 1L)) * output_span)
}

map_bytes_value <- function(value, output_min = -1.0, output_max = 1.0, clip = FALSE, allow_empty = FALSE) {
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }
  if (output_min >= output_max) stop("output_min must be less than output_max")
  if (!is.logical(clip) || length(clip) != 1L || is.na(clip)) stop("clip must be a single boolean")
  if (!is.logical(allow_empty) || length(allow_empty) != 1L || is.na(allow_empty)) stop("allow_empty must be a single boolean")

  bytes <- NULL
  if (is.raw(value)) {
    bytes <- as.integer(value)
  } else if (is.character(value) && length(value) == 1L) {
    bytes <- as.integer(charToRaw(value))
  } else if (is.numeric(value)) {
    if (length(value) == 0L) {
      bytes <- integer(0)
    } else {
      if (any(!is.finite(value))) stop("byte values must be finite")
      if (any(value != as.integer(value))) stop("byte values must be integers")
      bytes <- as.integer(value)
    }
  } else {
    stop("value must be raw, a single string, or a numeric vector")
  }

  if (!allow_empty && length(bytes) == 0L) stop("empty bytes input is invalid by default; set allow_empty=TRUE")
  if (any(bytes < 0L | bytes > 255L)) {
    if (!clip) stop("byte value out of range")
    bytes[bytes < 0L] <- 0L
    bytes[bytes > 255L] <- 255L
  }

  output_span <- output_max - output_min
  output_min + (as.double(bytes) / 255.0) * output_span
}

map_text_value <- function(value, output_min = -1.0, output_max = 1.0, clip = FALSE, allow_empty = FALSE, mode = c("codepoint", "byte")) {
  mode <- match.arg(mode)
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    stop("value must be a single non-missing string")
  }
  if (!is.logical(clip) || length(clip) != 1L || is.na(clip)) stop("clip must be a single boolean")
  if (!is.logical(allow_empty) || length(allow_empty) != 1L || is.na(allow_empty)) stop("allow_empty must be a single boolean")
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }
  if (output_min >= output_max) stop("output_min must be less than output_max")

  units <- NULL
  if (mode == "byte") {
    units <- as.integer(charToRaw(value))
  } else {
    units <- utf8ToInt(value)
  }
  if (length(units) == 0L) {
    if (allow_empty) return(numeric(0))
    stop("empty text input is invalid by default; set allow_empty=TRUE")
  }

  if (mode == "byte") {
    if (any(units < 0L | units > 255L)) {
      stop("byte values must be within [0,255]")
    }
    output_span <- output_max - output_min
    return(output_min + (as.double(units) / 255.0) * output_span)
  }

  input_min <- 0.0
  input_max <- 1114111.0
  output_span <- output_max - output_min
  input_span <- input_max - input_min
  mapped <- numeric(length(units))
  for (i in seq_along(units)) {
    current <- as.double(units[[i]])
    if (clip) {
      if (current < input_min) current <- input_min
      if (current > input_max) current <- input_max
    } else if (current < input_min || current > input_max) {
      stop("value is out of range")
    }
    mapped[[i]] <- output_min + ((current - input_min) / input_span) * output_span
  }
  mapped
}

map_sequence_value <- function(value, element_mapper, allow_empty = FALSE) {
  if (!is.function(element_mapper)) {
    stop("element_mapper must be a function")
  }
  if (is.null(value)) {
    stop("value must not be null")
  }

  if (is.list(value)) {
    if (length(value) == 0L) {
      if (allow_empty) return(list())
      stop("empty sequence input is invalid by default; set allow_empty=TRUE")
    }
    return(lapply(value, function(item) map_sequence_value(item, element_mapper, allow_empty)))
  }

  if (length(value) == 0L) {
    if (allow_empty) return(list())
    stop("empty sequence input is invalid by default; set allow_empty=TRUE")
  }

  if (length(value) > 1L) {
    return(lapply(as.list(value), function(item) map_sequence_value(item, element_mapper, allow_empty)))
  }

  element_mapper(value)
}

map_with_mapper <- function(mapper, value) {
  if (is.function(mapper)) {
    return(mapper(value))
  }
  if (inherits(mapper, "librangemap_sequence_mapper")) {
    return(map_sequence(mapper, value))
  }
  if (inherits(mapper, "librangemap_object_mapper")) {
    return(map_object(mapper, value))
  }
  if (inherits(mapper, "librangemap_integer_mapper")) {
    return(map_value(mapper, value))
  }
  if (inherits(mapper, "librangemap_float_mapper")) {
    return(map_float(mapper, value))
  }
  if (inherits(mapper, "librangemap_boolean_mapper")) {
    return(map_boolean(mapper, value))
  }
  if (inherits(mapper, "librangemap_bytes_mapper")) {
    return(map_bytes(mapper, value))
  }
  if (inherits(mapper, "librangemap_temporal_mapper")) {
    return(map_temporal(mapper, value))
  }
  stop("unsupported mapper type; provide a function or supported mapper object")
}

map_object_value <- function(value, schema, allow_unknown = FALSE, allow_empty = FALSE, has_missing_value = FALSE, missing_value = NULL) {
  if (!is.list(schema) || is.null(names(schema))) {
    stop("schema must be a named list")
  }
  if (!is.logical(allow_unknown) || length(allow_unknown) != 1L || is.na(allow_unknown)) {
    stop("allow_unknown must be a single boolean")
  }
  if (!is.logical(allow_empty) || length(allow_empty) != 1L || is.na(allow_empty)) {
    stop("allow_empty must be a single boolean")
  }
  if (!is.logical(has_missing_value) || length(has_missing_value) != 1L || is.na(has_missing_value)) {
    stop("has_missing_value must be a single boolean")
  }
  if (!allow_empty && is.list(schema) && length(schema) == 0L) {
    stop("empty object input is invalid by default; set allow_empty=TRUE")
  }
  if (!allow_empty && length(names(schema)) == 0L) {
    stop("schema keys must be explicit")
  }

  if (is.null(names(schema))) {
    stop("schema must have named fields")
  }
  if (any(names(schema) == "")) {
    stop("schema field names must be non-empty")
  }

  for (field_name in names(schema)) {
    mapper <- schema[[field_name]]
    if (
      !is.function(mapper) &&
      !inherits(mapper, "librangemap_integer_mapper") &&
      !inherits(mapper, "librangemap_float_mapper") &&
      !inherits(mapper, "librangemap_boolean_mapper") &&
      !inherits(mapper, "librangemap_bytes_mapper") &&
      !inherits(mapper, "librangemap_sequence_mapper") &&
      !inherits(mapper, "librangemap_object_mapper") &&
      !inherits(mapper, "librangemap_temporal_mapper")
    ) {
      stop(sprintf("unsupported mapper type for field %s", field_name))
    }
  }

  if (is.null(names(value)) && !is.environment(value) && !isS4(value) && !inherits(value, "data.frame")) {
    stop("object mapping input must be list-like, data-frame row, environment, or S4 object")
  }

  source_fields <- NULL
  if (is.list(value)) {
    source_fields <- names(value)
    if (is.null(source_fields)) {
      stop("value must be a named list for map/object mapping")
    }
  } else if (is.environment(value)) {
    source_fields <- names(as.list(value))
    value <- as.list(value)
  } else if (inherits(value, "data.frame")) {
    if (nrow(value) != 1L) stop("data-frame object input must have exactly one row")
    source_fields <- colnames(value)
    value <- as.list(value[1L, , drop = FALSE])
  } else if (isS4(value)) {
    source_fields <- slotNames(value)
    if (length(source_fields) == 0L) stop("S4 object input must have at least one slot")
    value <- as.list(slot(value, source_fields))
  } else {
    stop("object mapping input must be list-like, data-frame row, environment, or S4 object")
  }

  if (length(source_fields) != length(value)) {
    stop("invalid object mapping input shape")
  }
  if (!allow_empty && length(source_fields) == 0L) {
    stop("empty object input is invalid by default; set allow_empty=TRUE")
  }

  schema_fields <- names(schema)
  unknown_fields <- setdiff(source_fields, schema_fields)
  if (!allow_unknown && length(unknown_fields) > 0L) {
    stop(sprintf("unknown fields: %s", paste(unknown_fields, collapse = ", ")))
  }

  output <- list()
  for (field_name in schema_fields) {
    if (is.null(value[[field_name]])) {
      if (!has_missing_value) {
        stop(sprintf("missing required field: %s", field_name))
      }
      output[[field_name]] <- missing_value
      next
    }
    output[[field_name]] <- map_with_mapper(schema[[field_name]], value[[field_name]])
  }

  for (field_name in unknown_fields) {
    output[[field_name]] <- value[[field_name]]
  }

  names(output) <- c(schema_fields, unknown_fields)
  output
}

create_sequence_mapper <- function(element_mapper, allow_empty = FALSE) {
  if (!is.function(element_mapper)) stop("element_mapper must be a function")
  if (!is.logical(allow_empty) || length(allow_empty) != 1L || is.na(allow_empty)) stop("allow_empty must be a single boolean")
  structure(
    list(
      element_mapper = element_mapper,
      allow_empty = allow_empty
    ),
    class = "librangemap_sequence_mapper"
  )
}

map_sequence <- function(mapper, value) {
  map_sequence_value(value, mapper$element_mapper, mapper$allow_empty)
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

create_bytes_mapper <- function(output_range = c(-1.0, 1.0), clip = FALSE, allow_empty = FALSE) {
  if (length(output_range) != 2L) stop("output_range must contain exactly two numbers")
  if (output_range[1] >= output_range[2]) stop("output_range must be strictly increasing")
  structure(
    list(
      output_range = as.numeric(output_range),
      clip = as.logical(clip),
      allow_empty = as.logical(allow_empty)
    ),
    class = "librangemap_bytes_mapper"
  )
}

create_object_mapper <- function(schema, allow_unknown = FALSE, allow_empty = FALSE, has_missing_value = FALSE, missing_value = NULL, name = NULL) {
  if (!is.list(schema) || is.null(names(schema))) stop("schema must be a named list")
  if (!is.logical(allow_unknown) || length(allow_unknown) != 1L || is.na(allow_unknown)) stop("allow_unknown must be a single boolean")
  if (!is.logical(allow_empty) || length(allow_empty) != 1L || is.na(allow_empty)) stop("allow_empty must be a single boolean")
  if (!is.logical(has_missing_value) || length(has_missing_value) != 1L || is.na(has_missing_value)) stop("has_missing_value must be a single boolean")
  structure(
    list(
      schema = schema,
      allow_unknown = allow_unknown,
      allow_empty = allow_empty,
      has_missing_value = has_missing_value,
      missing_value = missing_value,
      name = name
    ),
    class = "librangemap_object_mapper"
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

map_bytes <- function(mapper, value) {
  map_bytes_value(
    value = value,
    output_min = mapper$output_range[1],
    output_max = mapper$output_range[2],
    clip = mapper$clip,
    allow_empty = mapper$allow_empty
  )
}

map_temporal_value <- function(value, input_min, input_max, output_min = -1.0, output_max = 1.0, clip = FALSE) {
  if (length(input_min) != 1L || length(input_max) != 1L) {
    stop("input_min and input_max must be single values")
  }
  if (!is.numeric(input_min) || !is.numeric(input_max) || !is.finite(input_min) || !is.finite(input_max)) {
    stop("input_min and input_max must be finite numbers")
  }
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }
  if (!is.logical(clip) || length(clip) != 1L || is.na(clip)) {
    stop("clip must be a single boolean")
  }
  if (input_min >= input_max) stop("input_min must be less than input_max")
  if (output_min >= output_max) stop("output_min must be less than output_max")

  if (inherits(value, "Date") || inherits(value, "POSIXct") || inherits(value, "POSIXlt")) {
    current <- as.numeric(as.POSIXct(value, tz = "UTC"))
  } else if (is.numeric(value) && length(value) == 1L && is.finite(value)) {
    current <- as.double(value)
  } else {
    stop("value must be a Date, POSIXct, POSIXlt, or numeric timestamp")
  }

  if (clip) {
    if (current < input_min) current <- input_min
    if (current > input_max) current <- input_max
  } else if (current < input_min || current > input_max) {
    stop("value is out of range")
  }

  output_span <- output_max - output_min
  input_span <- as.double(input_max - input_min)
  output_min + ((current - input_min) / input_span) * output_span
}

create_temporal_mapper <- function(input_range, output_range = c(-1.0, 1.0), clip = FALSE) {
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
    class = "librangemap_temporal_mapper"
  )
}

map_temporal <- function(mapper, value) {
  map_temporal_value(
    value = value,
    input_min = mapper$input_range[1],
    input_max = mapper$input_range[2],
    output_min = mapper$output_range[1],
    output_max = mapper$output_range[2],
    clip = mapper$clip
  )
}

map_object <- function(mapper, value) {
  map_object_value(
    value = value,
    schema = mapper$schema,
    allow_unknown = mapper$allow_unknown,
    allow_empty = mapper$allow_empty,
    has_missing_value = mapper$has_missing_value,
    missing_value = mapper$missing_value
  )
}

map_image_value <- function(value, output_min = -1.0, output_max = 1.0, clip = FALSE, allow_empty = FALSE) {
  if (!is.numeric(output_min) || !is.numeric(output_max) || !is.finite(output_min) || !is.finite(output_max)) {
    stop("output_min and output_max must be finite numbers")
  }
  if (output_min >= output_max) stop("output_min must be less than output_max")
  if (!is.logical(clip) || length(clip) != 1L || is.na(clip)) stop("clip must be a single boolean")
  if (!is.logical(allow_empty) || length(allow_empty) != 1L || is.na(allow_empty)) stop("allow_empty must be a single boolean")

  map_scalar <- function(byte) {
    if (!is.numeric(byte) || length(byte) != 1L || !is.finite(byte)) {
      stop("image values must be numeric scalars")
    }
    if (byte != as.integer(byte)) stop("image values must be integers")
    byte <- as.integer(byte)
    if (byte < 0L || byte > 255L) {
      if (!clip) stop("image value out of range")
      if (byte < 0L) byte <- 0L
      if (byte > 255L) byte <- 255L
    }
    output_span <- output_max - output_min
    output_min + ((as.double(byte) / 255.0) * output_span)
  }

  if (is.raw(value)) {
    if (length(value) == 0L) {
      if (allow_empty) return(numeric(0))
      stop("empty image input is invalid by default; set allow_empty=TRUE")
    }
    return(vapply(as.integer(value), map_scalar, numeric(1)))
  }

  if (is.character(value) && length(value) == 1L) {
    return(map_image_value(as.raw(charToRaw(value)), output_min, output_max, clip, allow_empty))
  }

  if (is.list(value)) {
    if (length(value) == 0L) {
      if (allow_empty) return(list())
      stop("empty image input is invalid by default; set allow_empty=TRUE")
    }
    return(lapply(value, function(item) map_image_value(item, output_min, output_max, clip, allow_empty)))
  }

  if (is.numeric(value)) {
    if (length(value) == 0L) {
      if (allow_empty) return(numeric(0))
      stop("empty image input is invalid by default; set allow_empty=TRUE")
    }
    if (length(value) > 1L) {
      return(vapply(value, map_scalar, numeric(1)))
    }
    return(map_scalar(value))
  }

  stop("value must be a raw vector, string, numeric vector, or nested list")
}

if (identical(environment(), globalenv())) {
  # Self-check when sourced directly.
  m <- create_mapper(c(0, 100), clip = FALSE)
  stopifnot(identical(map_value(m, 0), -1.0))
  stopifnot(identical(map_value(m, 50), 0.0))
  stopifnot(identical(map_value(m, 100), 1.0))
  stopifnot(identical(map_value(m, 50), map_value(m, 50)))

  fm <- create_float_mapper(c(0.0, 1.0), c(-1.0, 1.0), clip = FALSE)
  stopifnot(isTRUE(all.equal(map_float(fm, 0.0), -1.0)))
  stopifnot(isTRUE(all.equal(map_float(fm, 0.5), 0.0)))
  stopifnot(isTRUE(all.equal(map_float(fm, 1.0), 1.0)))

  bm <- create_boolean_mapper(c(-1.0, 1.0), false_value = -1.0, true_value = 1.0)
  stopifnot(identical(map_boolean(bm, TRUE), 1.0))
  stopifnot(identical(map_boolean(bm, FALSE), -1.0))

  cm <- c("cat", "dog")
  stopifnot(isTRUE(all.equal(map_categorical_value("cat", cm), -1.0)))
  stopifnot(isTRUE(all.equal(map_categorical_value("dog", cm), 1.0)))

  bym <- create_bytes_mapper(c(-1.0, 1.0), clip = FALSE, allow_empty = FALSE)
  stopifnot(identical(map_bytes(bym, as.raw(c(0, 255))), c(-1.0, 1.0)))
  stopifnot(identical(map_bytes(bym, "A"), c(-0.6784313725490196)))

  stopifnot(isTRUE(all.equal(map_text_value("AB"), c(-0.9998833150377296, -0.9998815198844639))))
  stopifnot(isTRUE(all.equal(map_text_value("A", mode = "byte"), c(-0.4901960784313726))))

  seq_mapper <- create_sequence_mapper(function(x) map_integer_value(x, 0, 100))
  seq_mapped <- map_sequence(seq_mapper, list(0, list(25, 50, list(75, 100))))
  stopifnot(isTRUE(all.equal(seq_mapped[[1]], -1.0)))
  stopifnot(isTRUE(all.equal(seq_mapped[[2]][[1]], -0.5)))
  stopifnot(isTRUE(all.equal(seq_mapped[[2]][[3]][[2]], 1.0)))

  object_mapper <- create_object_mapper(
    schema = list(
      tag = function(value) map_categorical_value(value, c("ok", "warn", "err")),
      id = function(value) map_integer_value(value, 0L, 1000L),
      active = function(value) map_boolean_value(value),
      payload = function(value) map_bytes_value(value),
      score = function(value) map_float_value(value, 0.0, 1.0)
    ),
    allow_unknown = FALSE,
    allow_empty = FALSE
  )
  object_input <- list(
    tag = "warn",
    id = 10L,
    active = TRUE,
    payload = as.raw(c(65, 66)),
    score = 0.25
  )
  object_mapped <- map_object(object_mapper, object_input)
  stopifnot(length(object_mapped) == length(object_input))
  stopifnot(isTRUE(all.equal(object_mapped$tag, 0.0)))

  object_repeat <- map_object(object_mapper, object_input)
  stopifnot(identical(object_repeat$score, object_mapped$score))
  object_unknown <- FALSE
  tryCatch(
    map_object(object_mapper, c(object_input, list(extra = "disallowed")),
    error = function(e) {
      object_unknown <<- TRUE
    }
  )
  stopifnot(object_unknown)

  object_missing <- FALSE
  tryCatch(
    map_object(
      object_mapper,
      list(tag = "warn", id = 1L, active = FALSE, payload = as.raw(c(65)), score = NULL)
    ),
    error = function(e) {
      object_missing <<- TRUE
    }
  )
  stopifnot(object_missing)

  tm <- create_temporal_mapper(c(-10.0, 10.0), c(-1.0, 1.0), clip = FALSE)
  stopifnot(isTRUE(all.equal(map_temporal(tm, as.POSIXct("1970-01-01 00:00:00", tz = "UTC")), 0.0)))
  stopifnot(isTRUE(all.equal(map_temporal(tm, 0.0), 0.0)))
  stopifnot(isTRUE(all.equal(map_temporal(tm, as.POSIXct("1970-01-01 00:00:00", tz = "UTC")), map_temporal(tm, 0.0))))
  stopifnot(isTRUE(all.equal(map_categorical_value("dog", cm), map_categorical_value("dog", cm))))

  image_raw <- map_image_value(as.raw(c(0, 127, 255)))
  stopifnot(isTRUE(all.equal(image_raw, c(-1.0, -0.0039215686274509665, 1.0))))
  image_nested <- map_image_value(list(c(0, 127, 255), list(c(64, 192, 32))))
  stopifnot(isTRUE(all.equal(image_nested[[1]], c(-1.0, -0.0039215686274509665, 1.0))))
  stopifnot(isTRUE(all.equal(image_nested[[2]][[1]], c(-0.4980392156862745, 0.5058823529411764, -0.7490196078431373))))
}
