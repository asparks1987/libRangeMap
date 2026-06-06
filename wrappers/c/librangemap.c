#include "librangemap.h"

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
