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

    printf("C wrapper verification passed.\n");
    return 0;
}
