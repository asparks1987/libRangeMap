#include "librangemap_core.h"

#include <math.h>
#include <stddef.h>

static int lrm_is_finite_double(double value) {
    return isfinite(value) ? 1 : 0;
}

static int lrm_validate_ordered_range(int64_t low, int64_t high) {
    return high > low;
}

static int lrm_validate_ordered_output(double low, double high) {
    return lrm_is_finite_double(low) && lrm_is_finite_double(high) && high > low;
}

static double lrm_linear_map(int64_t value, int64_t input_min, int64_t input_max, double output_min, double output_max) {
    const double input_span = (double)(input_max - input_min);
    const double output_span = output_max - output_min;
    return output_min + (((double)value - (double)input_min) / input_span) * output_span;
}

int lrm_integer_range_mapper_init(
    lrm_integer_range_mapper_t* mapper,
    int64_t input_min,
    int64_t input_max,
    double output_min,
    double output_max,
    int clip
) {
    if (mapper == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (!lrm_validate_ordered_range(input_min, input_max)) {
        return LRM_ERROR_INVALID_RANGE;
    }
    if (!lrm_validate_ordered_output(output_min, output_max)) {
        return LRM_ERROR_INVALID_RANGE;
    }

    mapper->input_min = input_min;
    mapper->input_max = input_max;
    mapper->output_min = output_min;
    mapper->output_max = output_max;
    mapper->clip = clip ? 1 : 0;
    return LRM_OK;
}

int lrm_integer_range_mapper_map_value(
    const lrm_integer_range_mapper_t* mapper,
    int64_t value,
    double* out_value
) {
    double mapped;

    if (mapper == NULL || out_value == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }

    if (value < mapper->input_min) {
        if (!mapper->clip) {
            return LRM_ERROR_OUT_OF_RANGE;
        }
        value = mapper->input_min;
    } else if (value > mapper->input_max) {
        if (!mapper->clip) {
            return LRM_ERROR_OUT_OF_RANGE;
        }
        value = mapper->input_max;
    }

    mapped = lrm_linear_map(value, mapper->input_min, mapper->input_max, mapper->output_min, mapper->output_max);
    if (!lrm_is_finite_double(mapped)) {
        return LRM_ERROR_INVALID_VALUE;
    }

    if (mapped < mapper->output_min) {
        mapped = mapper->output_min;
    } else if (mapped > mapper->output_max) {
        mapped = mapper->output_max;
    }

    *out_value = mapped;
    return LRM_OK;
}

int lrm_integer_range_mapper_get_spec(
    const lrm_integer_range_mapper_t* mapper,
    lrm_integer_range_mapper_spec_t* out_spec
) {
    if (mapper == NULL || out_spec == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }

    out_spec->spec_version_major = 1;
    out_spec->spec_version_minor = 0;
    out_spec->input_min = mapper->input_min;
    out_spec->input_max = mapper->input_max;
    out_spec->output_min = mapper->output_min;
    out_spec->output_max = mapper->output_max;
    out_spec->clip = mapper->clip;
    return LRM_OK;
}
