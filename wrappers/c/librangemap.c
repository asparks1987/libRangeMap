#include "librangemap.h"
#include <math.h>
#include <stdint.h>
#include <stddef.h>

static int validate_nonfinite_double(double value) {
    return (isfinite(value)) ? LRM_OK : LRM_ERROR_INVALID_VALUE;
}

int lrm_map_integer(
    int64_t input_min,
    int64_t input_max,
    double output_min,
    double output_max,
    int clip,
    int64_t value,
    double* out_value
) {
    lrm_integer_range_mapper_t mapper;
    int status = lrm_integer_range_mapper_init(
        &mapper,
        input_min,
        input_max,
        output_min,
        output_max,
        clip
    );
    if (status != LRM_OK) {
        return status;
    }
    return lrm_integer_range_mapper_map_value(&mapper, value, out_value);
}

int lrm_map_float(
    double input_min,
    double input_max,
    double output_min,
    double output_max,
    int clip,
    double value,
    double* out_value
) {
    int status = validate_nonfinite_double(input_min);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(input_max);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(output_min);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(output_max);
    if (status != LRM_OK) {
        return status;
    }

    if (input_min >= input_max || output_min >= output_max) {
        return LRM_ERROR_INVALID_RANGE;
    }
    if (out_value == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }

    if (validate_nonfinite_double(value) != LRM_OK) {
        return LRM_ERROR_INVALID_VALUE;
    }

    const double value_span = input_max - input_min;
    const double output_span = output_max - output_min;
    double bounded_value = value;

    if (value < input_min) {
        if (!clip) {
            return LRM_ERROR_OUT_OF_RANGE;
        }
        bounded_value = input_min;
    } else if (value > input_max) {
        if (!clip) {
            return LRM_ERROR_OUT_OF_RANGE;
        }
        bounded_value = input_max;
    }

    *out_value = output_min + ((bounded_value - input_min) / value_span) * output_span;
    return LRM_OK;
}

int lrm_map_boolean(
    double output_min,
    double output_max,
    double false_value,
    double true_value,
    int value,
    double* out_value
) {
    int status = validate_nonfinite_double(output_min);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(output_max);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(false_value);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(true_value);
    if (status != LRM_OK) {
        return status;
    }

    if (out_value == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }

    if (output_min >= output_max) {
        return LRM_ERROR_INVALID_RANGE;
    }

    if (false_value < output_min || false_value > output_max || true_value < output_min || true_value > output_max || false_value == true_value) {
        return LRM_ERROR_INVALID_RANGE;
    }

    if (value == 0) {
        *out_value = false_value;
        return LRM_OK;
    }
    if (value == 1) {
        *out_value = true_value;
        return LRM_OK;
    }

    return LRM_ERROR_INVALID_VALUE;
}
