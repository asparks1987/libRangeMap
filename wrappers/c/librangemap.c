#include "librangemap.h"
#include <math.h>
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

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

int lrm_map_temporal(
    double input_min,
    double input_max,
    double output_min,
    double output_max,
    int clip,
    double value,
    double* out_value
) {
    /*
     * Temporal mapping is explicit timestamp mapping in the configured domain.
     * It reuses the same linear contract as float mapping while keeping a family-typed
     * entrypoint for explicit wrapper-level policy and documentation.
     */
    return lrm_map_float(input_min, input_max, output_min, output_max, clip, value, out_value);
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

int lrm_map_bytes(
    const unsigned char* values,
    size_t length,
    double output_min,
    double output_max,
    int clip,
    double* out_values
) {
    int status = validate_nonfinite_double(output_min);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(output_max);
    if (status != LRM_OK) {
        return status;
    }

    if (values == NULL || out_values == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (output_min >= output_max) {
        return LRM_ERROR_INVALID_RANGE;
    }
    if (length == 0) {
        return LRM_ERROR_INVALID_VALUE;
    }

    for (size_t i = 0; i < length; ++i) {
        unsigned char bounded = values[i];
        if (!clip && bounded > 255U) {
            return LRM_ERROR_OUT_OF_RANGE;
        }
        out_values[i] = output_min + (((double)bounded - 0.0) / 255.0) * (output_max - output_min);
    }

    return LRM_OK;
}

int lrm_map_image_bytes(
    const unsigned char* values,
    size_t length,
    double output_min,
    double output_max,
    int clip,
    double* out_values
) {
    return lrm_map_bytes(values, length, output_min, output_max, clip, out_values);
}

int lrm_map_text(
    const char* value,
    const char* alphabet,
    double output_min,
    double output_max,
    int* out_length,
    double* out_values
) {
    int status = validate_nonfinite_double(output_min);
    if (status != LRM_OK) {
        return status;
    }
    status = validate_nonfinite_double(output_max);
    if (status != LRM_OK) {
        return status;
    }

    if (value == NULL || out_length == NULL || out_values == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (output_min >= output_max) {
        return LRM_ERROR_INVALID_RANGE;
    }
    if (value[0] == '\0') {
        return LRM_ERROR_INVALID_VALUE;
    }

    const size_t length = strlen(value);
    if (length == 0) {
        return LRM_ERROR_INVALID_VALUE;
    }

    if (alphabet != NULL) {
        const size_t alphabet_len = strlen(alphabet);
        if (alphabet_len == 0) {
            return LRM_ERROR_INVALID_VALUE;
        }
        for (size_t i = 0; i < alphabet_len; ++i) {
            for (size_t j = i + 1; j < alphabet_len; ++j) {
                if (alphabet[i] == alphabet[j]) {
                    return LRM_ERROR_INVALID_VALUE;
                }
            }
        }

        for (size_t i = 0; i < length; ++i) {
            const char* found = strchr(alphabet, value[i]);
            if (found == NULL) {
                return LRM_ERROR_INVALID_VALUE;
            }
            const size_t index = (size_t)(found - alphabet);
            if (alphabet_len == 1) {
                out_values[i] = (output_min + output_max) / 2.0;
            } else {
                out_values[i] = output_min + ((double)index / (double)(alphabet_len - 1)) * (output_max - output_min);
            }
        }
    } else {
        for (size_t i = 0; i < length; ++i) {
            const unsigned char code = (unsigned char)value[i];
            out_values[i] = output_min + (((double)code) / 255.0) * (output_max - output_min);
        }
    }

    *out_length = (int)length;
    return LRM_OK;
}

int lrm_map_categorical(
    const char* value,
    const char* const* tokens,
    size_t token_count,
    double output_min,
    double output_max,
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

    if (value == NULL || tokens == NULL || out_value == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (output_min >= output_max) {
        return LRM_ERROR_INVALID_RANGE;
    }
    if (token_count == 0) {
        return LRM_ERROR_INVALID_VALUE;
    }

    for (size_t i = 0; i < token_count; ++i) {
        if (tokens[i] == NULL) {
            return LRM_ERROR_INVALID_VALUE;
        }
        for (size_t j = i + 1; j < token_count; ++j) {
            if (strcmp(tokens[i], tokens[j]) == 0) {
                return LRM_ERROR_INVALID_VALUE;
            }
        }
    }

    size_t index = token_count;
    for (size_t i = 0; i < token_count; ++i) {
        if (strcmp(tokens[i], value) == 0) {
            index = i;
            break;
        }
    }

    if (index == token_count) {
        return LRM_ERROR_INVALID_VALUE;
    }

    if (token_count == 1) {
        *out_value = (output_min + output_max) / 2.0;
        return LRM_OK;
    }

    *out_value = output_min + ((double)index / (double)(token_count - 1)) * (output_max - output_min);
    return LRM_OK;
}

int lrm_map_integer_sequence(
    int64_t input_min,
    int64_t input_max,
    double output_min,
    double output_max,
    int clip,
    const int64_t* values,
    size_t length,
    double* out_values
) {
    if (values == NULL || out_values == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (length == 0) {
        return LRM_ERROR_INVALID_VALUE;
    }

    lrm_integer_range_mapper_t mapper;
    int status = lrm_integer_range_mapper_init(&mapper, input_min, input_max, output_min, output_max, clip);
    if (status != LRM_OK) {
        return status;
    }

    for (size_t i = 0; i < length; ++i) {
        status = lrm_integer_range_mapper_map_value(&mapper, values[i], &out_values[i]);
        if (status != LRM_OK) {
            return status;
        }
    }

    return LRM_OK;
}

int lrm_map_float_sequence(
    double input_min,
    double input_max,
    double output_min,
    double output_max,
    int clip,
    const double* values,
    size_t length,
    double* out_values
) {
    if (values == NULL || out_values == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (length == 0) {
        return LRM_ERROR_INVALID_VALUE;
    }

    for (size_t i = 0; i < length; ++i) {
        int status = lrm_map_float(input_min, input_max, output_min, output_max, clip, values[i], &out_values[i]);
        if (status != LRM_OK) {
            return status;
        }
    }

    return LRM_OK;
}

typedef struct {
    const lrm_map_object_schema_field_t* field;
    size_t index;
} map_object_schema_entry_t;

typedef struct {
    const lrm_map_object_input_field_t* field;
    size_t index;
} map_object_input_entry_t;

static int map_object_schema_name_compare(const void* left, const void* right) {
    const map_object_schema_entry_t* a = (const map_object_schema_entry_t*)left;
    const map_object_schema_entry_t* b = (const map_object_schema_entry_t*)right;
    return strcmp(a->field->name, b->field->name);
}

static int map_object_input_name_compare(const void* left, const void* right) {
    const map_object_input_entry_t* a = (const map_object_input_entry_t*)left;
    const map_object_input_entry_t* b = (const map_object_input_entry_t*)right;
    return strcmp(a->field->name, b->field->name);
}

static int map_object_find_input_by_name(
    const map_object_input_entry_t* entries,
    size_t input_count,
    const char* name
) {
    size_t lo = 0;
    size_t hi = input_count;

    while (lo < hi) {
        const size_t mid = (lo + hi) / 2;
        const int compare = strcmp(entries[mid].field->name, name);
        if (compare == 0) {
            return (int)entries[mid].index;
        }
        if (compare < 0) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return -1;
}

static int map_object_has_nonnull_name(const char* name) {
    return name != NULL && name[0] != '\0';
}

int lrm_map_object(
    const lrm_map_object_schema_field_t* schema_fields,
    size_t schema_count,
    const lrm_map_object_input_field_t* input_fields,
    size_t input_count,
    int allow_unknown,
    double* out_values
) {
    size_t i;
    if (schema_fields == NULL || out_values == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }
    if (schema_count == 0) {
        return LRM_ERROR_INVALID_VALUE;
    }
    if (input_count > 0 && input_fields == NULL) {
        return LRM_ERROR_NULL_POINTER;
    }

    map_object_schema_entry_t* ordered_schema = (map_object_schema_entry_t*)malloc(
        schema_count * sizeof(map_object_schema_entry_t));
    if (ordered_schema == NULL) {
        return LRM_ERROR_INVALID_VALUE;
    }

    for (i = 0; i < schema_count; ++i) {
        if (!map_object_has_nonnull_name(schema_fields[i].name)) {
            free(ordered_schema);
            return LRM_ERROR_INVALID_VALUE;
        }
        ordered_schema[i].field = &schema_fields[i];
        ordered_schema[i].index = i;
    }
    qsort(ordered_schema, schema_count, sizeof(map_object_schema_entry_t), map_object_schema_name_compare);

    for (i = 0; i + 1 < schema_count; ++i) {
        if (strcmp(ordered_schema[i].field->name, ordered_schema[i + 1].field->name) == 0) {
            free(ordered_schema);
            return LRM_ERROR_INVALID_VALUE;
        }
    }

    map_object_input_entry_t* ordered_input = NULL;
    if (input_count > 0) {
        ordered_input = (map_object_input_entry_t*)malloc(
            input_count * sizeof(map_object_input_entry_t));
        if (ordered_input == NULL) {
            free(ordered_schema);
            return LRM_ERROR_INVALID_VALUE;
        }
        for (i = 0; i < input_count; ++i) {
            if (!map_object_has_nonnull_name(input_fields[i].name)) {
                free(ordered_schema);
                free(ordered_input);
                return LRM_ERROR_INVALID_VALUE;
            }
            ordered_input[i].field = &input_fields[i];
            ordered_input[i].index = i;
        }
        qsort(ordered_input, input_count, sizeof(map_object_input_entry_t), map_object_input_name_compare);
        for (i = 0; i + 1 < input_count; ++i) {
            if (strcmp(ordered_input[i].field->name, ordered_input[i + 1].field->name) == 0) {
                free(ordered_schema);
                free(ordered_input);
                return LRM_ERROR_INVALID_VALUE;
            }
        }
    }

    for (i = 0; i < schema_count; ++i) {
        const map_object_schema_entry_t* field_entry = &ordered_schema[i];
        const lrm_map_object_schema_field_t* schema = field_entry->field;
        const int matching_input_index = (input_count > 0)
            ? map_object_find_input_by_name(ordered_input, input_count, schema->name)
            : -1;

        if (matching_input_index < 0) {
            if (schema->allow_missing) {
                out_values[i] = schema->missing_value;
                continue;
            }
            free(ordered_schema);
            free(ordered_input);
            return LRM_ERROR_INVALID_VALUE;
        }

        const lrm_map_object_input_field_t* input = &input_fields[matching_input_index];
        if (!input->has_value && schema->allow_missing) {
            out_values[i] = schema->missing_value;
            continue;
        }
        if (!input->has_value || input->family != schema->family) {
            free(ordered_schema);
            free(ordered_input);
            return LRM_ERROR_INVALID_VALUE;
        }

        if (schema->mapper_spec == NULL) {
            free(ordered_schema);
            free(ordered_input);
            return LRM_ERROR_INVALID_VALUE;
        }

        int status = LRM_OK;
        double mapped = 0.0;
        switch (schema->family) {
            case LRM_OBJECT_FIELD_INTEGER: {
                const lrm_map_object_integer_spec_t* mapper = (const lrm_map_object_integer_spec_t*)schema->mapper_spec;
                status = lrm_map_integer(
                    mapper->input_min,
                    mapper->input_max,
                    mapper->output_min,
                    mapper->output_max,
                    mapper->clip,
                    input->value.integer,
                    &mapped
                );
                break;
            }
            case LRM_OBJECT_FIELD_FLOAT: {
                const lrm_map_object_float_spec_t* mapper = (const lrm_map_object_float_spec_t*)schema->mapper_spec;
                status = lrm_map_float(
                    mapper->input_min,
                    mapper->input_max,
                    mapper->output_min,
                    mapper->output_max,
                    mapper->clip,
                    input->value.floating,
                    &mapped
                );
                break;
            }
            case LRM_OBJECT_FIELD_BOOLEAN: {
                const lrm_map_object_boolean_spec_t* mapper = (const lrm_map_object_boolean_spec_t*)schema->mapper_spec;
                status = lrm_map_boolean(
                    mapper->output_min,
                    mapper->output_max,
                    mapper->false_value,
                    mapper->true_value,
                    input->value.boolean,
                    &mapped
                );
                break;
            }
            case LRM_OBJECT_FIELD_TEXT: {
                const lrm_map_object_text_spec_t* mapper = (const lrm_map_object_text_spec_t*)schema->mapper_spec;
                int out_length = 0;
                const size_t text_length = strlen(input->value.text);
                if (text_length == 0) {
                    status = LRM_ERROR_INVALID_VALUE;
                    break;
                }
                double* values = (double*)malloc(text_length * sizeof(double));
                if (values == NULL) {
                    free(ordered_schema);
                    free(ordered_input);
                    return LRM_ERROR_INVALID_VALUE;
                }
                status = lrm_map_text(
                    input->value.text,
                    mapper->alphabet,
                    mapper->output_min,
                    mapper->output_max,
                    &out_length,
                    values
                );
                if (status == LRM_OK && out_length > 0) {
                    size_t total = (size_t)out_length;
                    size_t j;
                    mapped = 0.0;
                    for (j = 0; j < total; ++j) {
                        mapped += values[j];
                    }
                    mapped = mapped / (double)total;
                }
                free(values);
                break;
            }
            case LRM_OBJECT_FIELD_BYTES: {
                const lrm_map_object_bytes_spec_t* mapper = (const lrm_map_object_bytes_spec_t*)schema->mapper_spec;
                double values = 0.0;
                if (input->value.bytes.length == 0) {
                    status = LRM_ERROR_INVALID_VALUE;
                    break;
                }
                double* local = (double*)malloc(input->value.bytes.length * sizeof(double));
                if (local == NULL) {
                    free(ordered_schema);
                    free(ordered_input);
                    return LRM_ERROR_INVALID_VALUE;
                }
                status = lrm_map_bytes(
                    input->value.bytes.values,
                    input->value.bytes.length,
                    mapper->output_min,
                    mapper->output_max,
                    mapper->clip,
                    local
                );
                if (status == LRM_OK) {
                    size_t j;
                    for (j = 0; j < input->value.bytes.length; ++j) {
                        values += local[j];
                    }
                    mapped = values / (double)input->value.bytes.length;
                }
                free(local);
                break;
            }
            case LRM_OBJECT_FIELD_SEQUENCE_INTEGER: {
                const lrm_map_object_integer_sequence_spec_t* mapper = (const lrm_map_object_integer_sequence_spec_t*)schema->mapper_spec;
                if (mapper == NULL || input->value.integer_sequence.length == 0) {
                    status = LRM_ERROR_INVALID_VALUE;
                    break;
                }
                double* local = (double*)malloc(input->value.integer_sequence.length * sizeof(double));
                if (local == NULL) {
                    free(ordered_schema);
                    free(ordered_input);
                    return LRM_ERROR_INVALID_VALUE;
                }
                status = lrm_map_integer_sequence(
                    mapper->base.input_min,
                    mapper->base.input_max,
                    mapper->base.output_min,
                    mapper->base.output_max,
                    mapper->base.clip,
                    input->value.integer_sequence.values,
                    input->value.integer_sequence.length,
                    local
                );
                if (status == LRM_OK) {
                    size_t j;
                    for (j = 0; j < input->value.integer_sequence.length; ++j) {
                        mapped += local[j];
                    }
                    mapped = mapped / (double)input->value.integer_sequence.length;
                }
                free(local);
                break;
            }
            case LRM_OBJECT_FIELD_SEQUENCE_FLOAT: {
                const lrm_map_object_float_sequence_spec_t* mapper = (const lrm_map_object_float_sequence_spec_t*)schema->mapper_spec;
                if (mapper == NULL || input->value.float_sequence.length == 0) {
                    status = LRM_ERROR_INVALID_VALUE;
                    break;
                }
                double* local = (double*)malloc(input->value.float_sequence.length * sizeof(double));
                if (local == NULL) {
                    free(ordered_schema);
                    free(ordered_input);
                    return LRM_ERROR_INVALID_VALUE;
                }
                status = lrm_map_float_sequence(
                    mapper->base.input_min,
                    mapper->base.input_max,
                    mapper->base.output_min,
                    mapper->base.output_max,
                    mapper->base.clip,
                    input->value.float_sequence.values,
                    input->value.float_sequence.length,
                    local
                );
                if (status == LRM_OK) {
                    size_t j;
                    for (j = 0; j < input->value.float_sequence.length; ++j) {
                        mapped += local[j];
                    }
                    mapped = mapped / (double)input->value.float_sequence.length;
                }
                free(local);
                break;
            }
            default:
                status = LRM_ERROR_INVALID_VALUE;
                break;
        }

        if (status != LRM_OK) {
            free(ordered_schema);
            free(ordered_input);
            return status;
        }

        out_values[i] = mapped;
    }

    if (!allow_unknown && input_count > 0) {
        for (i = 0; i < input_count; ++i) {
            if (map_object_find_input_by_name(ordered_schema, schema_count, input_fields[i].name) < 0) {
                free(ordered_schema);
                free(ordered_input);
                return LRM_ERROR_INVALID_VALUE;
            }
        }
    }

    if (ordered_input != NULL) {
        free(ordered_input);
    }
    free(ordered_schema);
    return LRM_OK;
}
