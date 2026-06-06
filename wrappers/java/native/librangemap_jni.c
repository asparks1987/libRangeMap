#include <jni.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#include "librangemap_core.h"

static void lrm_throw(JNIEnv* env, const char* class_name, const char* message) {
    jclass error_class = (*env)->FindClass(env, class_name);
    if (error_class != NULL) {
        (*env)->ThrowNew(env, error_class, message);
    }
}

static void lrm_throw_status(JNIEnv* env, const char* operation, int status) {
    switch (status) {
        case LRM_ERROR_INVALID_RANGE:
            lrm_throw(env, "java/lang/IllegalArgumentException", operation);
            return;
        case LRM_ERROR_INVALID_VALUE:
            lrm_throw(env, "java/lang/IllegalStateException", operation);
            return;
        case LRM_ERROR_OUT_OF_RANGE:
            lrm_throw(env, "java/lang/IllegalArgumentException", operation);
            return;
        case LRM_ERROR_NULL_POINTER:
            lrm_throw(env, "java/lang/NullPointerException", operation);
            return;
        default:
            lrm_throw(env, "java/lang/IllegalStateException", operation);
            return;
    }
}

JNIEXPORT jlong JNICALL Java_librangemap_IntegerRangeMapper_nativeCreate(
    JNIEnv* env,
    jclass cls,
    jlong input_min,
    jlong input_max,
    jdouble output_min,
    jdouble output_max,
    jboolean clip
) {
    lrm_integer_range_mapper_t* mapper = (lrm_integer_range_mapper_t*)malloc(sizeof(*mapper));
    int status;

    (void)cls;

    if (mapper == NULL) {
        lrm_throw(env, "java/lang/OutOfMemoryError", "native allocation failed");
        return 0;
    }

    status = lrm_integer_range_mapper_init(
        mapper,
        (int64_t)input_min,
        (int64_t)input_max,
        (double)output_min,
        (double)output_max,
        clip ? 1 : 0
    );
    if (status != LRM_OK) {
        free(mapper);
        lrm_throw_status(env, "nativeCreate failed", status);
        return 0;
    }

    return (jlong)(intptr_t)mapper;
}

JNIEXPORT void JNICALL Java_librangemap_IntegerRangeMapper_nativeDestroy(
    JNIEnv* env,
    jclass cls,
    jlong handle
) {
    lrm_integer_range_mapper_t* mapper;

    (void)env;
    (void)cls;

    if (handle == 0) {
        return;
    }

    mapper = (lrm_integer_range_mapper_t*)(intptr_t)handle;
    free(mapper);
}

JNIEXPORT jdouble JNICALL Java_librangemap_IntegerRangeMapper_nativeMapValue(
    JNIEnv* env,
    jclass cls,
    jlong handle,
    jlong value
) {
    lrm_integer_range_mapper_t* mapper;
    double out_value;
    int status;

    (void)cls;

    if (handle == 0) {
        lrm_throw(env, "java/lang/NullPointerException", "native mapper is closed");
        return 0.0;
    }

    mapper = (lrm_integer_range_mapper_t*)(intptr_t)handle;
    status = lrm_integer_range_mapper_map_value(mapper, (int64_t)value, &out_value);
    if (status != LRM_OK) {
        lrm_throw_status(env, "nativeMapValue failed", status);
        return 0.0;
    }

    return (jdouble)out_value;
}
