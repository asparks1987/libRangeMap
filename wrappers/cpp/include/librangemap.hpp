#pragma once

#include <array>
#include <cstdint>
#include <stdexcept>
#include <string>

extern "C" {
#include "../../../csrc/librangemap_core.h"
}

namespace librangemap {

inline constexpr const char* spec_version = "1.0-alpha";
inline constexpr const char* mapper_type_integer_range = "integer_range";

struct MapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<std::int64_t, 2> input_range;
    std::array<double, 2> output_range;
    bool clip;
};

class IntegerRangeMapper {
public:
    IntegerRangeMapper(std::int64_t input_min, std::int64_t input_max, double output_min = -1.0, double output_max = 1.0, bool clip = false)
        : native_{} {
        const int status = lrm_integer_range_mapper_init(&native_, input_min, input_max, output_min, output_max, clip ? 1 : 0);
        if (status != LRM_OK) {
            throw map_status("init", status);
        }
    }

    double map_value(std::int64_t value) const {
        double mapped = 0.0;
        const int status = lrm_integer_range_mapper_map_value(&native_, value, &mapped);
        if (status != LRM_OK) {
            throw map_status("map_value", status);
        }
        return mapped;
    }

    double map(std::int64_t value) const {
        return map_value(value);
    }

    MapperSpec spec() const {
        lrm_integer_range_mapper_spec_t native_spec{};
        const int status = lrm_integer_range_mapper_get_spec(&native_, &native_spec);
        if (status != LRM_OK) {
            throw map_status("get_spec", status);
        }
        return MapperSpec{
            spec_version,
            mapper_type_integer_range,
            {native_spec.input_min, native_spec.input_max},
            {native_spec.output_min, native_spec.output_max},
            native_spec.clip != 0,
        };
    }

    std::string to_json() const {
        const MapperSpec current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\","
            "\"mapper_type\":\"" + current.mapper_type + "\","
            "\"input_range\":[" + std::to_string(current.input_range[0]) + "," + std::to_string(current.input_range[1]) + "],"
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "],"
            "\"clip\":" + std::string(current.clip ? "true" : "false") +
            "}";
    }

private:
    lrm_integer_range_mapper_t native_;

    static std::runtime_error map_status(const char* operation, int status) {
        switch (status) {
        case LRM_ERROR_INVALID_RANGE:
            return std::runtime_error(std::string("librangemap ") + operation + " failed: invalid range");
        case LRM_ERROR_INVALID_VALUE:
            return std::runtime_error(std::string("librangemap ") + operation + " failed: invalid value");
        case LRM_ERROR_OUT_OF_RANGE:
            return std::runtime_error(std::string("librangemap ") + operation + " failed: out of range");
        case LRM_ERROR_NULL_POINTER:
            return std::runtime_error(std::string("librangemap ") + operation + " failed: null pointer");
        default:
            return std::runtime_error(std::string("librangemap ") + operation + " failed with status " + std::to_string(status));
        }
    }
};

} // namespace librangemap
