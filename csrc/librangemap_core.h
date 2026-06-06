#ifndef LIBRANGEMAP_CORE_H
#define LIBRANGEMAP_CORE_H

#include <stdint.h>

#if defined(_WIN32)
#  if defined(LRM_BUILD_DLL)
#    define LRM_API __declspec(dllexport)
#  else
#    define LRM_API __declspec(dllimport)
#  endif
#else
#  define LRM_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define LRM_OK 0
#define LRM_ERROR_INVALID_RANGE 1
#define LRM_ERROR_INVALID_VALUE 2
#define LRM_ERROR_OUT_OF_RANGE 3
#define LRM_ERROR_NULL_POINTER 4

typedef struct lrm_integer_range_mapper {
    int64_t input_min;
    int64_t input_max;
    double output_min;
    double output_max;
    int clip;
} lrm_integer_range_mapper_t;

typedef struct lrm_integer_range_mapper_spec {
    int spec_version_major;
    int spec_version_minor;
    int64_t input_min;
    int64_t input_max;
    double output_min;
    double output_max;
    int clip;
} lrm_integer_range_mapper_spec_t;

LRM_API int lrm_integer_range_mapper_init(
    lrm_integer_range_mapper_t* mapper,
    int64_t input_min,
    int64_t input_max,
    double output_min,
    double output_max,
    int clip
);

LRM_API int lrm_integer_range_mapper_map_value(
    const lrm_integer_range_mapper_t* mapper,
    int64_t value,
    double* out_value
);

LRM_API int lrm_integer_range_mapper_get_spec(
    const lrm_integer_range_mapper_t* mapper,
    lrm_integer_range_mapper_spec_t* out_spec
);

#ifdef __cplusplus
}
#endif

#endif
