#include <stdio.h>
#include <stdlib.h>

#include "librangemap.h"

static void assert_equal(double actual, double expected, const char* label) {
    if (actual != expected) {
        fprintf(stderr, "%s: %.17g, expected %.17g\n", label, actual, expected);
        fflush(stderr);
        exit(1);
    }
}

int main(void) {
    double mapped = 0.0;
    int status = lrm_map_integer(0, 100, -1.0, 1.0, 0, 0, &mapped);
    if (status != LRM_OK) {
        fprintf(stderr, "map 0 failed with status=%d\n", status);
        return 1;
    }
    assert_equal(mapped, -1.0, "map(0)");

    status = lrm_map_integer(0, 100, -1.0, 1.0, 0, 50, &mapped);
    if (status != LRM_OK) {
        fprintf(stderr, "map 50 failed with status=%d\n", status);
        return 1;
    }
    assert_equal(mapped, 0.0, "map(50)");

    status = lrm_map_integer(0, 100, -1.0, 1.0, 0, 100, &mapped);
    if (status != LRM_OK) {
        fprintf(stderr, "map 100 failed with status=%d\n", status);
        return 1;
    }
    assert_equal(mapped, 1.0, "map(100)");
    status = lrm_map_integer(0, 100, -1.0, 1.0, 0, 50, &mapped);
    if (status != LRM_OK) {
        fprintf(stderr, "repeat map 50 failed with status=%d\n", status);
        return 1;
    }
    assert_equal(mapped, 0.0, "repeat map(50)");

    status = lrm_map_integer(0, 10, -1.0, 1.0, 1, -5, &mapped);
    if (status != LRM_OK || mapped != -1.0) {
        fprintf(stderr, "clipped low failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_integer(0, 10, -1.0, 1.0, 0, 11, &mapped);
    if (status == LRM_OK) {
        fprintf(stderr, "strict out-of-range unexpectedly succeeded with %.17g\n", mapped);
        return 1;
    }

    status = lrm_map_float(-1.0, 10.0, -1.0, 1.0, 0, 5.0, &mapped);
    if (status != LRM_OK) {
        fprintf(stderr, "float map 5.0 failed status=%d\n", status);
        return 1;
    }
    assert_equal(mapped, 0.0, "float(5.0)");

    status = lrm_map_float(-1.0, 10.0, -1.0, 1.0, 1, -5.0, &mapped);
    if (status != LRM_OK || mapped != -1.0) {
        fprintf(stderr, "float clip failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_float(-1.0, 10.0, -1.0, 1.0, 0, 20.0, &mapped);
    if (status != LRM_ERROR_OUT_OF_RANGE) {
        fprintf(stderr, "float strict out-of-range expected fail, got status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_temporal(0.0, 10.0, -1.0, 1.0, 0, 5.0, &mapped);
    if (status != LRM_OK) {
        fprintf(stderr, "temporal map 5.0 failed status=%d\n", status);
        return 1;
    }
    assert_equal(mapped, 0.0, "temporal(5.0)");

    status = lrm_map_temporal(0.0, 10.0, -1.0, 1.0, 1, -5.0, &mapped);
    if (status != LRM_OK || mapped != -1.0) {
        fprintf(stderr, "temporal clip failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_temporal(0.0, 10.0, -1.0, 1.0, 0, 20.0, &mapped);
    if (status != LRM_ERROR_OUT_OF_RANGE) {
        fprintf(stderr, "temporal strict out-of-range expected fail, got status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_temporal(0.0, 10.0, -1.0, 1.0, 0, 5.0, &mapped);
    if (status != LRM_OK || mapped != 0.0) {
        fprintf(stderr, "temporal repeated map failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_boolean(-1.0, 1.0, -1.0, 1.0, 0, &mapped);
    if (status != LRM_OK || mapped != -1.0) {
        fprintf(stderr, "bool false failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_boolean(-1.0, 1.0, -1.0, 1.0, 1, &mapped);
    if (status != LRM_OK || mapped != 1.0) {
        fprintf(stderr, "bool true failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_boolean(-1.0, 1.0, -1.0, 1.0, 2, &mapped);
    if (status != LRM_ERROR_INVALID_VALUE) {
        fprintf(stderr, "bool unknown expected invalid value, got status=%d\n", status);
        return 1;
    }

    unsigned char bytes[] = {0, 127, 255};
    double byte_outputs[3] = {0.0, 0.0, 0.0};
    status = lrm_map_bytes(bytes, 3, -1.0, 1.0, 0, byte_outputs);
    if (status != LRM_OK) {
        fprintf(stderr, "bytes map failed status=%d\n", status);
        return 1;
    }
    assert_equal(byte_outputs[0], -1.0, "bytes[0]");
    assert_equal(byte_outputs[1], ((127.0 / 255.0) * 2.0) - 1.0, "bytes[1]");
    assert_equal(byte_outputs[2], 1.0, "bytes[2]");

    status = lrm_map_bytes(bytes, 3, -1.0, 1.0, 0, byte_outputs);
    if (status != LRM_OK) {
        fprintf(stderr, "bytes repeated map failed status=%d\n", status);
        return 1;
    }

    status = lrm_map_image_bytes(bytes, 3, -1.0, 1.0, 0, byte_outputs);
    if (status != LRM_OK) {
        fprintf(stderr, "image-like bytes map failed status=%d\n", status);
        return 1;
    }
    assert_equal(byte_outputs[0], -1.0, "image-like bytes[0]");
    assert_equal(byte_outputs[2], 1.0, "image-like bytes[2]");

    double text_outputs[3] = {0.0, 0.0, 0.0};
    int text_length = 0;
    status = lrm_map_text("Ada", NULL, -1.0, 1.0, &text_length, text_outputs);
    if (status != LRM_OK || text_length != 3) {
        fprintf(stderr, "text codepoint map failed status=%d length=%d\n", status, text_length);
        return 1;
    }
    status = lrm_map_text("abc", "abc", -1.0, 1.0, &text_length, text_outputs);
    if (status != LRM_OK || text_length != 3) {
        fprintf(stderr, "text alphabet map failed status=%d length=%d\n", status, text_length);
        return 1;
    }
    status = lrm_map_text("abd", "abc", -1.0, 1.0, &text_length, text_outputs);
    if (status != LRM_ERROR_INVALID_VALUE) {
        fprintf(stderr, "text unknown expected invalid value, got status=%d\n", status);
        return 1;
    }
    status = lrm_map_text("abc", "abca", -1.0, 1.0, &text_length, text_outputs);
    if (status != LRM_ERROR_INVALID_VALUE) {
        fprintf(stderr, "text duplicate alphabet expected invalid value, got status=%d\n", status);
        return 1;
    }

    const char* categorical_tokens[] = {"red", "green", "blue"};
    status = lrm_map_categorical("green", categorical_tokens, 3, -1.0, 1.0, &mapped);
    if (status != LRM_OK || mapped != 0.0) {
        fprintf(stderr, "categorical map failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_categorical("green", categorical_tokens, 3, -1.0, 1.0, &mapped);
    if (status != LRM_OK || mapped != 0.0) {
        fprintf(stderr, "categorical repeated map failed status=%d value=%.17g\n", status, mapped);
        return 1;
    }

    status = lrm_map_categorical("purple", categorical_tokens, 3, -1.0, 1.0, &mapped);
    if (status != LRM_ERROR_INVALID_VALUE) {
        fprintf(stderr, "categorical unknown expected invalid value, got status=%d\n", status);
        return 1;
    }

    int64_t integer_values[] = {0, 50, 100};
    double integer_sequence_outputs[3] = {0.0, 0.0, 0.0};
    status = lrm_map_integer_sequence(0, 100, -1.0, 1.0, 0, integer_values, 3, integer_sequence_outputs);
    if (status != LRM_OK) {
        fprintf(stderr, "integer sequence map failed status=%d\n", status);
        return 1;
    }
    assert_equal(integer_sequence_outputs[0], -1.0, "integer sequence[0]");
    assert_equal(integer_sequence_outputs[1], 0.0, "integer sequence[1]");
    assert_equal(integer_sequence_outputs[2], 1.0, "integer sequence[2]");
    status = lrm_map_integer_sequence(0, 100, -1.0, 1.0, 0, integer_values, 3, integer_sequence_outputs);
    if (status != LRM_OK) {
        fprintf(stderr, "integer sequence repeated map failed status=%d\n", status);
        return 1;
    }

    double float_sequence_values[] = {0.0, 5.0, 10.0};
    double float_sequence_outputs[3] = {0.0, 0.0, 0.0};
    status = lrm_map_float_sequence(0.0, 10.0, -1.0, 1.0, 0, float_sequence_values, 3, float_sequence_outputs);
    if (status != LRM_OK) {
        fprintf(stderr, "float sequence map failed status=%d\n", status);
        return 1;
    }
    assert_equal(float_sequence_outputs[0], -1.0, "float sequence[0]");
    assert_equal(float_sequence_outputs[1], 0.0, "float sequence[1]");
    assert_equal(float_sequence_outputs[2], 1.0, "float sequence[2]");

    const lrm_map_object_integer_spec_t score_spec = {
        .input_min = 0,
        .input_max = 100,
        .output_min = -1.0,
        .output_max = 1.0,
        .clip = 0,
    };

    const lrm_map_object_text_spec_t label_spec = {
        .alphabet = "AB",
        .output_min = -1.0,
        .output_max = 1.0,
    };

    const lrm_map_object_boolean_spec_t active_spec = {
        .output_min = -1.0,
        .output_max = 1.0,
        .false_value = -1.0,
        .true_value = 1.0,
    };

    const lrm_map_object_bytes_spec_t payload_spec = {
        .output_min = -1.0,
        .output_max = 1.0,
        .clip = 0,
    };

    const lrm_map_object_integer_sequence_spec_t samples_spec = {
        .base = {
            .input_min = 0,
            .input_max = 100,
            .output_min = -1.0,
            .output_max = 1.0,
            .clip = 0,
        },
        .length = 2,
        .values = NULL,
    };

    const lrm_map_object_schema_field_t schema_fields[] = {
        { .name = "active", .family = LRM_OBJECT_FIELD_BOOLEAN, .allow_missing = 0, .missing_value = 0.0, .mapper_spec = &active_spec },
        { .name = "label", .family = LRM_OBJECT_FIELD_TEXT, .allow_missing = 0, .missing_value = 0.0, .mapper_spec = &label_spec },
        { .name = "payload", .family = LRM_OBJECT_FIELD_BYTES, .allow_missing = 0, .missing_value = 0.0, .mapper_spec = &payload_spec },
        { .name = "score", .family = LRM_OBJECT_FIELD_INTEGER, .allow_missing = 0, .missing_value = 0.0, .mapper_spec = &score_spec },
        { .name = "samples", .family = LRM_OBJECT_FIELD_SEQUENCE_INTEGER, .allow_missing = 0, .missing_value = 0.0, .mapper_spec = &samples_spec },
    };

    const unsigned char payload[] = {255};
    const int64_t sample_values[] = {0, 50, 100};
    const lrm_map_object_input_field_t object_input_fields[] = {
        { .name = "score", .has_value = 1, .family = LRM_OBJECT_FIELD_INTEGER, .value.integer = 100 },
        { .name = "label", .has_value = 1, .family = LRM_OBJECT_FIELD_TEXT, .value.text = "A" },
        { .name = "active", .has_value = 1, .family = LRM_OBJECT_FIELD_BOOLEAN, .value.boolean = 1 },
        { .name = "payload", .has_value = 1, .family = LRM_OBJECT_FIELD_BYTES, .value.bytes = { .values = payload, .length = sizeof(payload) } },
        { .name = "samples", .has_value = 1, .family = LRM_OBJECT_FIELD_SEQUENCE_INTEGER, .value.integer_sequence = { .values = sample_values, .length = sizeof(sample_values) / sizeof(sample_values[0]) } },
    };

    double mapped_object[5] = {0.0, 0.0, 0.0, 0.0, 0.0};
    status = lrm_map_object(schema_fields, 5, object_input_fields, 5, 0, mapped_object);
    if (status != LRM_OK) {
        fprintf(stderr, "map object failed status=%d\n", status);
        return 1;
    }
    if (mapped_object[0] != 1.0 || mapped_object[1] != -1.0 || mapped_object[2] != 1.0 || mapped_object[3] != 0.0 || mapped_object[4] != 1.0) {
        fprintf(stderr, "map object deterministic values unexpected: [%.17g, %.17g, %.17g, %.17g, %.17g]\n",
            mapped_object[0], mapped_object[1], mapped_object[2], mapped_object[3], mapped_object[4]);
        return 1;
    }

    status = lrm_map_object(schema_fields, 5, object_input_fields, 5, 0, mapped_object);
    if (status != LRM_OK) {
        fprintf(stderr, "map object repeated failed status=%d\n", status);
        return 1;
    }

    const lrm_map_object_input_field_t object_unknown_fields[] = {
        { .name = "score", .has_value = 1, .family = LRM_OBJECT_FIELD_INTEGER, .value.integer = 100 },
        { .name = "label", .has_value = 1, .family = LRM_OBJECT_FIELD_TEXT, .value.text = "A" },
        { .name = "payload", .has_value = 1, .family = LRM_OBJECT_FIELD_BYTES, .value.bytes = { .values = payload, .length = sizeof(payload) } },
        { .name = "samples", .has_value = 1, .family = LRM_OBJECT_FIELD_SEQUENCE_INTEGER, .value.integer_sequence = { .values = sample_values, .length = sizeof(sample_values) / sizeof(sample_values[0]) } },
        { .name = "active", .has_value = 1, .family = LRM_OBJECT_FIELD_BOOLEAN, .value.boolean = 1 },
        { .name = "rogue", .has_value = 1, .family = LRM_OBJECT_FIELD_INTEGER, .value.integer = 1 },
    };
    status = lrm_map_object(schema_fields, 5, object_unknown_fields, 6, 0, mapped_object);
    if (status != LRM_ERROR_INVALID_VALUE) {
        fprintf(stderr, "map object unknown field expected invalid, got status=%d\n", status);
        return 1;
    }

    status = lrm_map_object(schema_fields, 5, object_unknown_fields, 6, 1, mapped_object);
    if (status != LRM_OK) {
        fprintf(stderr, "map object allow-unknown failed status=%d\n", status);
        return 1;
    }

    const lrm_map_object_input_field_t object_missing_fields[] = {
        { .name = "score", .has_value = 1, .family = LRM_OBJECT_FIELD_INTEGER, .value.integer = 100 },
        { .name = "label", .has_value = 1, .family = LRM_OBJECT_FIELD_TEXT, .value.text = "A" },
        { .name = "payload", .has_value = 1, .family = LRM_OBJECT_FIELD_BYTES, .value.bytes = { .values = payload, .length = sizeof(payload) } },
        { .name = "samples", .has_value = 1, .family = LRM_OBJECT_FIELD_SEQUENCE_INTEGER, .value.integer_sequence = { .values = sample_values, .length = sizeof(sample_values) / sizeof(sample_values[0]) } },
    };
    status = lrm_map_object(schema_fields, 5, object_missing_fields, 4, 0, mapped_object);
    if (status != LRM_ERROR_INVALID_VALUE) {
        fprintf(stderr, "map object missing field expected invalid, got status=%d\n", status);
        return 1;
    }

    printf("C wrapper verification passed.\n");
    return 0;
}
