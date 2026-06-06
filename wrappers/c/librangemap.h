#ifndef LIBRANGEMAP_H
#define LIBRANGEMAP_H

#include "../csrc/librangemap_core.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Lightweight first-party C helper API for common one-shot integer mapping.
 *
 * The core ABI types and behavior are in csrc/librangemap_core.h.
 * This wrapper keeps the public usage concise for direct C callers while
 * preserving all core error codes and validation.
 */

int lrm_map_integer(
    int64_t input_min,
    int64_t input_max,
    double output_min,
    double output_max,
    int clip,
    int64_t value,
    double* out_value
);

#ifdef __cplusplus
}
#endif

#endif
