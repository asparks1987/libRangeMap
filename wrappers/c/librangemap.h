#ifndef LIBRANGEMAP_H
#define LIBRANGEMAP_H

#include "../csrc/librangemap_core.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Lightweight first-party C helper API for common one-shot family mapping.
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

int lrm_map_float(
    double input_min,
    double input_max,
    double output_min,
    double output_max,
    int clip,
    double value,
    double* out_value
);

int lrm_map_temporal(
    double input_min,
    double input_max,
    double output_min,
    double output_max,
    int clip,
    double value,
    double* out_value
);

int lrm_map_boolean(
    double output_min,
    double output_max,
    double false_value,
    double true_value,
    int value,
    double* out_value
);

int lrm_map_bytes(
    const unsigned char* values,
    size_t length,
    double output_min,
    double output_max,
    int clip,
    double* out_values
);

int lrm_map_image_bytes(
    const unsigned char* values,
    size_t length,
    double output_min,
    double output_max,
    int clip,
    double* out_values
);

int lrm_map_text(
    const char* value,
    const char* alphabet,
    double output_min,
    double output_max,
    int* out_length,
    double* out_values
);

int lrm_map_categorical(
    const char* value,
    const char* const* tokens,
    size_t token_count,
    double output_min,
    double output_max,
    double* out_value
);

int lrm_map_integer_sequence(
    int64_t input_min,
    int64_t input_max,
    double output_min,
    double output_max,
    int clip,
    const int64_t* values,
    size_t length,
    double* out_values
);

int lrm_map_float_sequence(
    double input_min,
    double input_max,
    double output_min,
    double output_max,
    int clip,
    const double* values,
    size_t length,
    double* out_values
);

typedef enum {
    LRM_OBJECT_FIELD_INTEGER = 0,
    LRM_OBJECT_FIELD_FLOAT = 1,
    LRM_OBJECT_FIELD_BOOLEAN = 2,
    LRM_OBJECT_FIELD_TEXT = 3,
    LRM_OBJECT_FIELD_BYTES = 4,
    LRM_OBJECT_FIELD_SEQUENCE_INTEGER = 5,
    LRM_OBJECT_FIELD_SEQUENCE_FLOAT = 6,
} lrm_map_object_field_family_t;

typedef struct {
    int64_t input_min;
    int64_t input_max;
    double output_min;
    double output_max;
    int clip;
} lrm_map_object_integer_spec_t;

typedef struct {
    double input_min;
    double input_max;
    double output_min;
    double output_max;
    int clip;
} lrm_map_object_float_spec_t;

typedef struct {
    double output_min;
    double output_max;
    double false_value;
    double true_value;
} lrm_map_object_boolean_spec_t;

typedef struct {
    const char* alphabet;
    double output_min;
    double output_max;
} lrm_map_object_text_spec_t;

typedef struct {
    double output_min;
    double output_max;
    int clip;
} lrm_map_object_bytes_spec_t;

typedef struct {
    lrm_map_object_integer_spec_t base;
    size_t length;
    const int64_t* values;
} lrm_map_object_integer_sequence_spec_t;

typedef struct {
    lrm_map_object_float_spec_t base;
    size_t length;
    const double* values;
} lrm_map_object_float_sequence_spec_t;

typedef struct {
    const char* name;
    lrm_map_object_field_family_t family;
    int allow_missing;
    double missing_value;
    const void* mapper_spec;
} lrm_map_object_schema_field_t;

typedef struct {
    const char* name;
    int has_value;
    lrm_map_object_field_family_t family;
    union {
        int64_t integer;
        double floating;
        int boolean;
        const char* text;
        struct {
            const unsigned char* values;
            size_t length;
        } bytes;
        struct {
            const int64_t* values;
            size_t length;
        } integer_sequence;
        struct {
            const double* values;
            size_t length;
        } float_sequence;
    } value;
} lrm_map_object_input_field_t;

int lrm_map_object(
    const lrm_map_object_schema_field_t* schema_fields,
    size_t schema_count,
    const lrm_map_object_input_field_t* input_fields,
    size_t input_count,
    int allow_unknown,
    double* out_values
);

#ifdef __cplusplus
}
#endif

#endif
