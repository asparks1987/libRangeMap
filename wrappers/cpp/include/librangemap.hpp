#pragma once

#include <array>
#include <any>
#include <chrono>
#include <cctype>
#include <iomanip>
#include <cstdint>
#include <cmath>
#include <climits>
#include <map>
#include <sstream>
#include <stdexcept>
#include <memory>
#include <string>
#include <type_traits>
#include <variant>
#include <vector>
#include <utility>

extern "C" {
#include "../../../csrc/librangemap_core.h"
}

namespace librangemap {

inline constexpr const char* spec_version = "1.0-alpha";
inline constexpr const char* mapper_type_integer_range = "integer_range";
inline constexpr const char* mapper_type_float_range = "float_range";
inline constexpr const char* mapper_type_boolean_range = "boolean_range";
inline constexpr const char* mapper_type_text_range = "text_range";
inline constexpr const char* mapper_type_bytes_range = "bytes_range";
inline constexpr const char* mapper_type_categorical_range = "categorical_range";
inline constexpr const char* mapper_type_temporal_range = "temporal_range";
inline constexpr const char* mapper_type_image_range = "image_range";
inline constexpr const char* mapper_type_sequence_range = "sequence_range";
inline constexpr const char* mapper_type_map_range = "map_range";

struct MapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<std::int64_t, 2> input_range;
    std::array<double, 2> output_range;
    bool clip;
};

struct FloatMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<double, 2> input_range;
    std::array<double, 2> output_range;
    bool clip;
};

struct BooleanMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<double, 2> output_range;
    double false_value;
    double true_value;
};

struct TextMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::string mode;
    std::string alphabet;
    std::array<double, 2> output_range;
};

struct BytesMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<std::int64_t, 2> input_range;
    std::array<double, 2> output_range;
    bool clip;
    bool allow_empty;
};

struct TemporalMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<double, 2> input_range;
    std::array<double, 2> output_range;
    bool clip;
    std::string input_unit;
};

struct CategoricalMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::vector<std::string> vocabulary;
    std::array<double, 2> output_range;
    std::string name;
};

struct ImageMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    std::array<std::int64_t, 2> input_range;
    std::array<double, 2> output_range;
    bool clip;
    bool allow_empty;
};

struct SequenceMapperSpec {
    std::string spec_version;
    std::string mapper_type;
    bool allow_empty;
};

class MapRangeMapper;

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

class FloatRangeMapper {
public:
    FloatRangeMapper(double input_min, double input_max, double output_min = -1.0, double output_max = 1.0, bool clip = false)
        : input_min_(input_min), input_max_(input_max), output_min_(output_min), output_max_(output_max), clip_(clip) {
        if (!std::isfinite(input_min_) || !std::isfinite(input_max_) || !std::isfinite(output_min_) || !std::isfinite(output_max_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (input_min_ >= input_max_ || output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
    }

    double map_value(double value) const {
        if (!std::isfinite(value)) {
            throw map_status("map_value", LRM_ERROR_INVALID_VALUE);
        }
        double bounded_value = value;
        if (value < input_min_) {
            if (!clip_) {
                throw map_status("map_value", LRM_ERROR_OUT_OF_RANGE);
            }
            bounded_value = input_min_;
        } else if (value > input_max_) {
            if (!clip_) {
                throw map_status("map_value", LRM_ERROR_OUT_OF_RANGE);
            }
            bounded_value = input_max_;
        }
        return output_min_ + ((bounded_value - input_min_) / (input_max_ - input_min_)) * (output_max_ - output_min_);
    }

    double map(double value) const {
        return map_value(value);
    }

    FloatMapperSpec spec() const {
        return FloatMapperSpec{
            spec_version,
            mapper_type_float_range,
            {input_min_, input_max_},
            {output_min_, output_max_},
            clip_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\","
            "\"mapper_type\":\"" + current.mapper_type + "\","
            "\"input_range\":[" + std::to_string(current.input_range[0]) + "," + std::to_string(current.input_range[1]) + "],"
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "],"
            "\"clip\":" + std::string(current.clip ? "true" : "false") +
            "}";
    }

private:
    double input_min_;
    double input_max_;
    double output_min_;
    double output_max_;
    bool clip_;

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

class BooleanRangeMapper {
public:
    BooleanRangeMapper(double output_min = -1.0, double output_max = 1.0, double false_value = -1.0, double true_value = 1.0)
        : output_min_(output_min), output_max_(output_max), false_value_(false_value), true_value_(true_value) {
        if (!std::isfinite(output_min_) || !std::isfinite(output_max_) || !std::isfinite(false_value_) || !std::isfinite(true_value_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
        if (false_value_ < output_min_ || false_value_ > output_max_ || true_value_ < output_min_ || true_value_ > output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
        if (false_value_ == true_value_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
    }

    double map_value(bool value) const {
        return value ? true_value_ : false_value_;
    }

    double map(bool value) const {
        return map_value(value);
    }

    BooleanMapperSpec spec() const {
        return BooleanMapperSpec{
            spec_version,
            mapper_type_boolean_range,
            {output_min_, output_max_},
            false_value_,
            true_value_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\","
            "\"mapper_type\":\"" + current.mapper_type + "\","
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "],"
            "\"false_value\":" + std::to_string(current.false_value) + ","
            "\"true_value\":" + std::to_string(current.true_value) +
            "}";
    }

private:
    double output_min_;
    double output_max_;
    double false_value_;
    double true_value_;

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

class TextRangeMapper {
public:
    enum class Mode {
        Codepoint,
        Byte,
        Alphabet,
    };

    TextRangeMapper(Mode mode = Mode::Codepoint, std::string alphabet = "", double output_min = -1.0, double output_max = 1.0)
        : mode_(mode), alphabet_(std::move(alphabet)), output_min_(output_min), output_max_(output_max) {
        if (!std::isfinite(output_min_) || !std::isfinite(output_max_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
        if (mode_ == Mode::Alphabet) {
            if (alphabet_.empty()) {
                throw map_status("init", LRM_ERROR_INVALID_VALUE);
            }
            for (std::size_t i = 0; i < alphabet_.size(); ++i) {
                for (std::size_t j = i + 1; j < alphabet_.size(); ++j) {
                    if (alphabet_[i] == alphabet_[j]) {
                        throw map_status("init", LRM_ERROR_INVALID_VALUE);
                    }
                }
            }
        }
    }

    std::vector<double> map_value(const std::string& value) const {
        if (value.empty()) {
            throw std::invalid_argument("empty text input is invalid by default");
        }

        std::vector<double> output;
        output.reserve(value.size());

        switch (mode_) {
        case Mode::Codepoint:
        case Mode::Byte:
            for (unsigned char ch : value) {
                output.push_back(output_min_ + ((static_cast<double>(ch) / 255.0) * (output_max_ - output_min_)));
            }
            break;
        case Mode::Alphabet:
            for (char ch : value) {
                const auto position = alphabet_.find(ch);
                if (position == std::string::npos) {
                    throw std::invalid_argument("unknown text token");
                }
                if (alphabet_.size() == 1) {
                    output.push_back((output_min_ + output_max_) / 2.0);
                } else {
                    output.push_back(output_min_ + ((static_cast<double>(position) / static_cast<double>(alphabet_.size() - 1)) * (output_max_ - output_min_)));
                }
            }
            break;
        }

        return output;
    }

    std::vector<double> map(const std::string& value) const {
        return map_value(value);
    }

    TextMapperSpec spec() const {
        return TextMapperSpec{
            spec_version,
            mapper_type_text_range,
            mode_name(),
            alphabet_,
            {output_min_, output_max_},
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\","
            "\"mapper_type\":\"" + current.mapper_type + "\","
            "\"mode\":\"" + current.mode + "\","
            "\"alphabet\":\"" + escape(current.alphabet) + "\","
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "]"
            "}";
    }

private:
    Mode mode_;
    std::string alphabet_;
    double output_min_;
    double output_max_;

    std::string mode_name() const {
        switch (mode_) {
        case Mode::Codepoint:
            return "codepoint";
        case Mode::Byte:
            return "byte";
        case Mode::Alphabet:
            return "alphabet";
        }
        return "codepoint";
    }

    static std::string escape(const std::string& value) {
        std::string output;
        output.reserve(value.size() + 4);
        for (char ch : value) {
            if (ch == '\\') {
                output += "\\\\";
            } else if (ch == '"') {
                output += "\\\"";
            } else {
                output.push_back(ch);
            }
        }
        return output;
    }

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

class BytesRangeMapper {
public:
    BytesRangeMapper(double output_min = -1.0, double output_max = 1.0, bool clip = false, bool allow_empty = false)
        : output_min_(output_min), output_max_(output_max), clip_(clip), allow_empty_(allow_empty) {
        if (!std::isfinite(output_min_) || !std::isfinite(output_max_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
    }

    BytesMapperSpec spec() const {
        return BytesMapperSpec{
            spec_version,
            mapper_type_bytes_range,
            {0, 255},
            {output_min_, output_max_},
            clip_,
            allow_empty_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\","
            "\"mapper_type\":\"" + current.mapper_type + "\","
            "\"input_range\":[" + std::to_string(current.input_range[0]) + "," + std::to_string(current.input_range[1]) + "],"
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "],"
            "\"clip\":" + (current.clip ? "true" : "false") + ","
            "\"allow_empty\":" + (current.allow_empty ? "true" : "false") +
            "}";
    }

    std::vector<double> map_value(const std::string& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty bytes value is invalid by default; set allow_empty=true to map empty bytes.");
        }
        std::vector<double> output;
        output.reserve(value.size());
        for (std::size_t index = 0; index < value.size(); ++index) {
            const unsigned int byte_value = static_cast<unsigned char>(value[index]);
            output.push_back(map_byte(byte_value, static_cast<int>(index)));
        }
        return output;
    }

    std::vector<double> map_value(const std::vector<int>& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty bytes value is invalid by default; set allow_empty=true to map empty bytes.");
        }
        std::vector<double> output;
        output.reserve(value.size());
        for (std::size_t index = 0; index < value.size(); ++index) {
            const int current = value[index];
            output.push_back(map_byte(current, static_cast<int>(index)));
        }
        return output;
    }

    std::vector<double> map_value(const std::vector<unsigned char>& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty bytes value is invalid by default; set allow_empty=true to map empty bytes.");
        }
        std::vector<double> output;
        output.reserve(value.size());
        for (std::size_t index = 0; index < value.size(); ++index) {
            output.push_back(map_byte(value[index], static_cast<int>(index)));
        }
        return output;
    }

    std::vector<double> map(const std::string& value) const {
        return map_value(value);
    }

    static BytesRangeMapper from_json(const std::string& json) {
        if (json.empty()) {
            throw std::invalid_argument("mapper json must not be empty.");
        }
        if (extract_string(json, "spec_version") != spec_version) {
            throw std::invalid_argument("unsupported spec_version");
        }
        if (extract_string(json, "mapper_type") != mapper_type_bytes_range) {
            throw std::invalid_argument("unsupported mapper_type");
        }
        const bool clip = extract_bool(json, "clip");
        const bool allow_empty = extract_bool(json, "allow_empty");
        const auto output_range = extract_double_pair(json, "output_range");
        return BytesRangeMapper(output_range[0], output_range[1], clip, allow_empty);
    }

private:
    static std::string extract_string(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":\"";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        auto value_start = start + needle.size();
        const auto end = text.find('"', value_start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated string for ") + key);
        }
        return text.substr(value_start, end - value_start);
    }

    static std::array<double, 2> extract_double_pair(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string body = text.substr(start, end - start);
        const auto delimiter = body.find(',');
        if (delimiter == std::string::npos) {
            throw std::invalid_argument(std::string(key) + " must contain two values");
        }
        const auto first = body.substr(0, delimiter);
        const auto second = body.substr(delimiter + 1);
        return {
            std::stod(first),
            std::stod(second),
        };
    }

    static bool extract_bool(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            return false;
        }
        start += needle.size();
        if (text.compare(start, 4, "true") == 0) {
            return true;
        }
        if (text.compare(start, 5, "false") == 0) {
            return false;
        }
        throw std::invalid_argument(std::string("invalid boolean for ") + key);
    }

    double map_byte(int value, int index) const {
        int mapped_value = value;
        if (mapped_value < 0) {
            if (!clip_) {
                std::ostringstream message;
                message << "byte value " << value << " at index " << index
                        << " is below input_range lower bound 0; enable clip to clamp.";
                throw std::runtime_error(message.str());
            }
            mapped_value = 0;
        } else if (mapped_value > 255) {
            if (!clip_) {
                std::ostringstream message;
                message << "byte value " << value << " at index " << index
                        << " is above input_range upper bound 255; enable clip to clamp.";
                throw std::runtime_error(message.str());
            }
            mapped_value = 255;
        }
        return output_min_ + ((static_cast<double>(mapped_value) / 255.0) * (output_max_ - output_min_));
    }

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

    double output_min_;
    double output_max_;
    bool clip_;
    bool allow_empty_;
};

class TemporalRangeMapper {
public:
    TemporalRangeMapper(double input_min, double input_max, double output_min = -1.0, double output_max = 1.0, bool clip = false, std::string input_unit = "unix_seconds")
        : input_min_(input_min), input_max_(input_max), output_min_(output_min), output_max_(output_max), clip_(clip), input_unit_(std::move(input_unit)) {
        if (!std::isfinite(input_min_) || !std::isfinite(input_max_) || !std::isfinite(output_min_) || !std::isfinite(output_max_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (input_min_ >= input_max_ || output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
        if (input_unit_.empty()) {
            throw std::invalid_argument("temporal input_unit must not be empty.");
        }
    }

    double map_value(double value) const {
        if (!std::isfinite(value)) {
            throw map_status("map_value", LRM_ERROR_INVALID_VALUE);
        }
        double bounded_value = value;
        if (value < input_min_) {
            if (!clip_) {
                throw map_status("map_value", LRM_ERROR_OUT_OF_RANGE);
            }
            bounded_value = input_min_;
        } else if (value > input_max_) {
            if (!clip_) {
                throw map_status("map_value", LRM_ERROR_OUT_OF_RANGE);
            }
            bounded_value = input_max_;
        }
        return output_min_ + ((bounded_value - input_min_) / (input_max_ - input_min_)) * (output_max_ - output_min_);
    }

    double map_value(std::int64_t value) const {
        return map_value(static_cast<double>(value));
    }

    double map_value(std::chrono::system_clock::time_point value) const {
        const auto seconds = std::chrono::duration<double>(value.time_since_epoch()).count();
        return map_value(seconds);
    }

    double map(double value) const {
        return map_value(value);
    }

    TemporalMapperSpec spec() const {
        return TemporalMapperSpec{
            spec_version,
            mapper_type_temporal_range,
            {input_min_, input_max_},
            {output_min_, output_max_},
            clip_,
            input_unit_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\"," 
            "\"mapper_type\":\"" + current.mapper_type + "\"," 
            "\"input_range\":[" + std::to_string(current.input_range[0]) + "," + std::to_string(current.input_range[1]) + "],"
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "],"
            "\"clip\":" + std::string(current.clip ? "true" : "false") + ","
            "\"input_unit\":\"" + current.input_unit + "\"" 
            "}";
    }

    static TemporalRangeMapper from_json(const std::string& json) {
        if (json.empty()) {
            throw std::invalid_argument("mapper json must not be empty.");
        }
        if (extract_string(json, "spec_version") != spec_version) {
            throw std::invalid_argument("unsupported spec_version");
        }
        if (extract_string(json, "mapper_type") != mapper_type_temporal_range) {
            throw std::invalid_argument("unsupported mapper_type");
        }
        const bool clip = extract_bool(json, "clip");
        const auto input_range = extract_double_pair(json, "input_range");
        const auto output_range = extract_double_pair(json, "output_range");
        const std::string input_unit = extract_string(json, "input_unit");
        return TemporalRangeMapper(input_range[0], input_range[1], output_range[0], output_range[1], clip, input_unit);
    }

private:
    static std::string extract_string(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":\"";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        auto value_start = start + needle.size();
        const auto end = text.find('"', value_start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated string for ") + key);
        }
        return text.substr(value_start, end - value_start);
    }

    static std::array<double, 2> extract_double_pair(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string body = text.substr(start, end - start);
        const auto delimiter = body.find(',');
        if (delimiter == std::string::npos) {
            throw std::invalid_argument(std::string(key) + " must contain two values");
        }
        return {std::stod(body.substr(0, delimiter)), std::stod(body.substr(delimiter + 1))};
    }

    static bool extract_bool(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        if (text.compare(start, 4, "true") == 0) {
            return true;
        }
        if (text.compare(start, 5, "false") == 0) {
            return false;
        }
        throw std::invalid_argument(std::string("invalid boolean for ") + key);
    }

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

    double input_min_;
    double input_max_;
    double output_min_;
    double output_max_;
    bool clip_;
    std::string input_unit_;
};

class CategoricalRangeMapper {
public:
    explicit CategoricalRangeMapper(const std::vector<std::any>& vocabulary, double output_min = -1.0, double output_max = 1.0, std::string name = "")
        : output_min_(output_min), output_max_(output_max), name_(std::move(name)) {
        if (!std::isfinite(output_min_) || !std::isfinite(output_max_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
        if (vocabulary.empty()) {
            throw std::invalid_argument("vocabulary must not be empty.");
        }
        if (!name_.empty() && name_.find_first_not_of(" \t\r\n") == std::string::npos) {
            throw std::invalid_argument("name must not be empty.");
        }

        vocabulary_.reserve(vocabulary.size());
        for (const auto& token : vocabulary) {
            const auto encoded = encode_token(token);
            if (index_.find(encoded) != index_.end()) {
                throw std::invalid_argument("vocabulary contains duplicate token: " + encoded);
            }
            index_.emplace(encoded, vocabulary_.size());
            vocabulary_.push_back(encoded);
        }
    }

    double map_value(const std::any& value) const {
        const auto encoded = encode_token(value);
        const auto it = index_.find(encoded);
        if (it == index_.end()) {
            throw std::invalid_argument("unknown token: " + encoded);
        }
        if (vocabulary_.size() == 1) {
            return output_min_;
        }
        return output_min_ + ((static_cast<double>(it->second) / static_cast<double>(vocabulary_.size() - 1)) * (output_max_ - output_min_));
    }

    double map(const std::any& value) const {
        return map_value(value);
    }

    double map_value(const std::string& value) const {
        return map_value(std::any(value));
    }

    double map_value(const char* value) const {
        return map_value(std::any(std::string(value)));
    }

    double map_value(bool value) const {
        return map_value(std::any(value));
    }

    double map_value(char value) const {
        return map_value(std::any(value));
    }

    template <typename Integer, typename = std::enable_if_t<std::is_integral_v<Integer> && !std::is_same_v<std::remove_cv_t<Integer>, bool> && !std::is_same_v<std::remove_cv_t<Integer>, char>>>
    double map_value(Integer value) const {
        return map_value(std::any(static_cast<std::int64_t>(value)));
    }

    template <typename Floating, typename = std::enable_if_t<std::is_floating_point_v<Floating>>>
    double map_value(Floating value) const {
        return map_value(std::any(static_cast<double>(value)));
    }

    double map_value(std::nullptr_t) const {
        return map_value(std::any(nullptr));
    }

    CategoricalMapperSpec spec() const {
        return CategoricalMapperSpec{
            spec_version,
            mapper_type_categorical_range,
            vocabulary_,
            {output_min_, output_max_},
            name_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        std::string vocabulary_json = "[";
        for (std::size_t i = 0; i < current.vocabulary.size(); ++i) {
            if (i > 0) {
                vocabulary_json += ",";
            }
            vocabulary_json += "\"" + escape(current.vocabulary[i]) + "\"";
        }
        vocabulary_json += "]";
        std::string output = "{";
        output += "\"spec_version\":\"" + current.spec_version + "\",";
        output += "\"mapper_type\":\"" + current.mapper_type + "\",";
        output += "\"vocabulary\":" + vocabulary_json + ",";
        output += "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "]";
        if (!current.name.empty()) {
            output += ",\"name\":\"" + escape(current.name) + "\"";
        }
        output += "}";
        return output;
    }

    static CategoricalRangeMapper from_json(const std::string& json) {
        if (json.empty()) {
            throw std::invalid_argument("mapper json must not be empty.");
        }
        if (extract_string(json, "spec_version") != spec_version) {
            throw std::invalid_argument("unsupported spec_version");
        }
        if (extract_string(json, "mapper_type") != mapper_type_categorical_range) {
            throw std::invalid_argument("unsupported mapper_type");
        }
        const auto vocab = extract_string_array(json, "vocabulary");
        const auto output_range = extract_double_pair(json, "output_range");
        const std::string name = extract_string(json, "name", "");
        std::vector<std::any> decoded;
        decoded.reserve(vocab.size());
        for (const auto& token : vocab) {
            decoded.push_back(decode_token(token));
        }
        return CategoricalRangeMapper(decoded, output_range[0], output_range[1], name);
    }

    static std::any decode_spec_token(const std::string& encoded) {
        return decode_token(encoded);
    }

private:
    static std::string encode_token(const std::any& token) {
        if (!token.has_value()) {
            return "null";
        }
        if (token.type() == typeid(std::string)) {
            return "str:" + std::any_cast<const std::string&>(token);
        }
        if (token.type() == typeid(const char*)) {
            return "str:" + std::string(std::any_cast<const char*>(token));
        }
        if (token.type() == typeid(bool)) {
            return std::string("bool:") + (std::any_cast<bool>(token) ? "true" : "false");
        }
        if (token.type() == typeid(char)) {
            return "char:" + std::to_string(static_cast<int>(std::any_cast<char>(token)));
        }
        if (token.type() == typeid(std::int64_t)) {
            return "num:" + std::to_string(std::any_cast<std::int64_t>(token));
        }
        if (token.type() == typeid(std::int32_t)) {
            return "num:" + std::to_string(std::any_cast<std::int32_t>(token));
        }
        if (token.type() == typeid(std::int16_t)) {
            return "num:" + std::to_string(std::any_cast<std::int16_t>(token));
        }
        if (token.type() == typeid(std::uint8_t)) {
            return "num:" + std::to_string(std::any_cast<std::uint8_t>(token));
        }
        if (token.type() == typeid(std::uint16_t)) {
            return "num:" + std::to_string(std::any_cast<std::uint16_t>(token));
        }
        if (token.type() == typeid(std::uint32_t)) {
            return "num:" + std::to_string(std::any_cast<std::uint32_t>(token));
        }
        if (token.type() == typeid(std::uint64_t)) {
            return "num:" + std::to_string(std::any_cast<std::uint64_t>(token));
        }
        if (token.type() == typeid(double)) {
            const double value = std::any_cast<double>(token);
            if (!std::isfinite(value)) {
                throw std::invalid_argument("vocabulary tokens must be finite numbers.");
            }
            return "num:" + format_number(value);
        }
        if (token.type() == typeid(float)) {
            const float value = std::any_cast<float>(token);
            if (!std::isfinite(value)) {
                throw std::invalid_argument("vocabulary tokens must be finite numbers.");
            }
            return "num:" + format_number(static_cast<double>(value));
        }
        throw std::invalid_argument("unsupported vocabulary token type.");
    }

    static std::string format_number(double value) {
        std::ostringstream out;
        out << std::setprecision(17) << value;
        return out.str();
    }

    static std::any decode_token(const std::string& encoded) {
        if (encoded == "null") {
            return std::any{};
        }
        const auto separator = encoded.find(':');
        if (separator == std::string::npos) {
            return encoded;
        }
        const std::string kind = encoded.substr(0, separator);
        const std::string raw = encoded.substr(separator + 1);
        if (kind == "str") {
            return raw;
        }
        if (kind == "bool") {
            if (raw == "true") {
                return true;
            }
            if (raw == "false") {
                return false;
            }
            throw std::invalid_argument("invalid boolean token encoding.");
        }
        if (kind == "char") {
            return static_cast<char>(std::stoi(raw));
        }
        if (kind == "num") {
            const double number = std::stod(raw);
            if (!std::isfinite(number)) {
                throw std::invalid_argument("vocabulary tokens must be finite numbers.");
            }
            const auto as_int = static_cast<std::int64_t>(number);
            if (number == static_cast<double>(as_int)) {
                return as_int;
            }
            return number;
        }
        throw std::invalid_argument("unsupported token encoding: " + encoded);
    }

    static std::string extract_string(const std::string& text, const char* key, const std::string& default_value = "") {
        const std::string needle = std::string("\"") + key + "\":\"";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            return default_value;
        }
        const auto value_start = start + needle.size();
        const auto end = text.find('"', value_start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated string for ") + key);
        }
        return text.substr(value_start, end - value_start);
    }

    static std::vector<std::string> extract_string_array(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string body = text.substr(start, end - start);
        std::vector<std::string> output;
        std::size_t index = 0;
        while (index < body.size()) {
            index = skip_whitespace(body, index);
            if (index >= body.size()) {
                break;
            }
            if (body[index] != '"') {
                throw std::invalid_argument(std::string(key) + " must contain quoted token strings");
            }
            const auto token_end = find_end_of_quoted(body, index + 1);
            output.push_back(unescape(body.substr(index + 1, token_end - index - 1)));
            index = token_end + 1;
            index = skip_whitespace(body, index);
            if (index < body.size() && body[index] == ',') {
                ++index;
            }
        }
        return output;
    }

    static std::array<double, 2> extract_double_pair(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string body = text.substr(start, end - start);
        const auto delimiter = body.find(',');
        if (delimiter == std::string::npos) {
            throw std::invalid_argument(std::string(key) + " must contain two values");
        }
        return {std::stod(body.substr(0, delimiter)), std::stod(body.substr(delimiter + 1))};
    }

    static std::size_t find_end_of_quoted(const std::string& text, std::size_t start) {
        bool escaped = false;
        for (std::size_t i = start; i < text.size(); ++i) {
            const char c = text[i];
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
                continue;
            }
            if (c == '"') {
                return i;
            }
        }
        throw std::invalid_argument("unterminated string");
    }

    static std::size_t skip_whitespace(const std::string& text, std::size_t index) {
        while (index < text.size() && std::isspace(static_cast<unsigned char>(text[index]))) {
            ++index;
        }
        return index;
    }

    static std::string unescape(const std::string& text) {
        std::string output;
        output.reserve(text.size());
        for (std::size_t i = 0; i < text.size(); ++i) {
            const char ch = text[i];
            if (ch == '\\' && i + 1 < text.size()) {
                const char next = text[i + 1];
                if (next == '\\' || next == '"') {
                    output += next;
                    ++i;
                    continue;
                }
            }
            output += ch;
        }
        return output;
    }

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

    static std::string escape(const std::string& value) {
        std::string output;
        output.reserve(value.size() + 4);
        for (char ch : value) {
            if (ch == '\\') {
                output += "\\\\";
            } else if (ch == '"') {
                output += "\\\"";
            } else {
                output += ch;
            }
        }
        return output;
    }

    std::vector<std::string> vocabulary_;
    std::map<std::string, std::size_t> index_;
    double output_min_;
    double output_max_;
    std::string name_;
};

class ImageRangeMapper {
public:
    ImageRangeMapper(double output_min = -1.0, double output_max = 1.0, bool clip = false, bool allow_empty = false)
        : output_min_(output_min), output_max_(output_max), clip_(clip), allow_empty_(allow_empty) {
        if (!std::isfinite(output_min_) || !std::isfinite(output_max_)) {
            throw map_status("init", LRM_ERROR_INVALID_VALUE);
        }
        if (output_min_ >= output_max_) {
            throw map_status("init", LRM_ERROR_INVALID_RANGE);
        }
    }

    ImageMapperSpec spec() const {
        return ImageMapperSpec{
            spec_version,
            mapper_type_image_range,
            {0, 255},
            {output_min_, output_max_},
            clip_,
            allow_empty_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\","
            "\"mapper_type\":\"" + current.mapper_type + "\","
            "\"input_range\":[" + std::to_string(current.input_range[0]) + "," + std::to_string(current.input_range[1]) + "],"
            "\"output_range\":[" + std::to_string(current.output_range[0]) + "," + std::to_string(current.output_range[1]) + "],"
            "\"clip\":" + std::string(current.clip ? "true" : "false") + ","
            "\"allow_empty\":" + std::string(current.allow_empty ? "true" : "false") +
            "}";
    }

    std::vector<double> map(const std::string& value) const {
        return map_value(value);
    }

    std::vector<double> map_value(const std::string& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty image value is invalid by default; set allow_empty=true to map empty images.");
        }
        std::vector<double> output;
        output.reserve(value.size());
        for (std::size_t index = 0; index < value.size(); ++index) {
            output.push_back(map_scalar(static_cast<unsigned char>(value[index]), static_cast<int>(index)));
        }
        return output;
    }

    std::vector<double> map_value(const std::vector<int>& value) const {
        return map_numeric(value);
    }

    std::vector<double> map_value(const std::vector<unsigned char>& value) const {
        return map_numeric(value);
    }

    std::vector<double> map_value(const std::vector<double>& value) const {
        return map_numeric(value);
    }

    std::vector<std::vector<double>> map_value(const std::vector<std::vector<int>>& value) const {
        return map_nested(value);
    }

    std::vector<std::vector<double>> map_value(const std::vector<std::vector<unsigned char>>& value) const {
        return map_nested(value);
    }

    std::vector<std::vector<double>> map_value(const std::vector<std::vector<double>>& value) const {
        return map_nested(value);
    }

    static ImageRangeMapper from_json(const std::string& json) {
        if (json.empty()) {
            throw std::invalid_argument("mapper json must not be empty.");
        }
        if (extract_string(json, "spec_version") != spec_version) {
            throw std::invalid_argument("unsupported spec_version");
        }
        if (extract_string(json, "mapper_type") != mapper_type_image_range) {
            throw std::invalid_argument("unsupported mapper_type");
        }
        const bool clip = extract_bool(json, "clip");
        const bool allow_empty = extract_bool(json, "allow_empty");
        const auto output_range = extract_double_pair(json, "output_range");
        return ImageRangeMapper(output_range[0], output_range[1], clip, allow_empty);
    }

private:
    template <typename Numeric, typename = std::enable_if_t<std::is_arithmetic_v<Numeric>>>
    std::vector<double> map_numeric(const std::vector<Numeric>& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty image value is invalid by default; set allow_empty=true to map empty images.");
        }
        std::vector<double> output;
        output.reserve(value.size());
        for (std::size_t index = 0; index < value.size(); ++index) {
            output.push_back(map_scalar(static_cast<double>(value[index]), static_cast<int>(index)));
        }
        return output;
    }

    template <typename InnerNumeric, typename = std::enable_if_t<std::is_arithmetic_v<InnerNumeric>>>
    std::vector<std::vector<double>> map_nested(const std::vector<std::vector<InnerNumeric>>& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty image value is invalid by default; set allow_empty=true to map empty images.");
        }
        std::vector<std::vector<double>> output;
        output.reserve(value.size());
        for (const auto& row : value) {
            output.push_back(map_numeric(row));
        }
        return output;
    }

    double map_scalar(double value, int index) const {
        if (!std::isfinite(value)) {
            throw std::invalid_argument("image pixel value must be finite.");
        }
        double mapped_value = value;
        if (mapped_value < 0.0) {
            if (!clip_) {
                std::ostringstream message;
                message << "image pixel value " << value << " at index " << index
                        << " is below input_range lower bound 0; enable clip to clamp.";
                throw std::runtime_error(message.str());
            }
            mapped_value = 0.0;
        } else if (mapped_value > 255.0) {
            if (!clip_) {
                std::ostringstream message;
                message << "image pixel value " << value << " at index " << index
                        << " is above input_range upper bound 255; enable clip to clamp.";
                throw std::runtime_error(message.str());
            }
            mapped_value = 255.0;
        }
        return output_min_ + ((mapped_value - 0.0) / 255.0) * (output_max_ - output_min_);
    }

    static std::string extract_string(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":\"";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        auto value_start = start + needle.size();
        const auto end = text.find('"', value_start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated string for ") + key);
        }
        return text.substr(value_start, end - value_start);
    }

    static std::array<double, 2> extract_double_pair(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string body = text.substr(start, end - start);
        const auto delimiter = body.find(',');
        if (delimiter == std::string::npos) {
            throw std::invalid_argument(std::string(key) + " must contain two values");
        }
        const auto first = body.substr(0, delimiter);
        const auto second = body.substr(delimiter + 1);
        return {std::stod(first), std::stod(second)};
    }

    static bool extract_bool(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            return false;
        }
        start += needle.size();
        if (text.compare(start, 4, "true") == 0) {
            return true;
        }
        if (text.compare(start, 5, "false") == 0) {
            return false;
        }
        throw std::invalid_argument(std::string("invalid boolean for ") + key);
    }

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

    double output_min_;
    double output_max_;
    bool clip_;
    bool allow_empty_;
};

template <typename ElementMapper>
class SequenceRangeMapper {
public:
    SequenceRangeMapper(ElementMapper element_mapper, bool allow_empty = false)
        : element_mapper_(std::move(element_mapper)), allow_empty_(allow_empty) {
    }

    SequenceMapperSpec spec() const {
        return SequenceMapperSpec{
            spec_version,
            mapper_type_sequence_range,
            allow_empty_,
        };
    }

    std::string to_json() const {
        const auto current = spec();
        return "{"
            "\"spec_version\":\"" + current.spec_version + "\"," 
            "\"mapper_type\":\"" + current.mapper_type + "\"," 
            "\"allow_empty\":" + std::string(current.allow_empty ? "true" : "false") +
            "}";
    }

    template <typename T>
    auto map_value(const std::vector<T>& value) const
        -> std::vector<std::decay_t<decltype(std::declval<const ElementMapper&>()(std::declval<const T&>()))>> {
        static_assert(std::is_invocable_v<const ElementMapper&, const T&>, "unsupported sequence element type.");
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty sequence input is invalid by default; set allow_empty=true to map empty sequences.");
        }
        using mapped_type = std::decay_t<decltype(std::declval<const ElementMapper&>()(std::declval<const T&>()))>;
        std::vector<mapped_type> output;
        output.reserve(value.size());
        for (const auto& item : value) {
            output.push_back(element_mapper_(item));
        }
        return output;
    }

    template <typename T>
    auto map(const std::vector<T>& value) const
        -> std::vector<std::decay_t<decltype(std::declval<const ElementMapper&>()(std::declval<const T&>()))>> {
        return map_value(value);
    }

private:
    ElementMapper element_mapper_;
    bool allow_empty_;
};

template <typename ElementMapper>
SequenceRangeMapper<ElementMapper> create_sequence_mapper(ElementMapper element_mapper, bool allow_empty = false) {
    return SequenceRangeMapper<ElementMapper>(std::move(element_mapper), allow_empty);
}

template <typename ElementMapper, typename T>
auto map_sequence(const SequenceRangeMapper<ElementMapper>& mapper, const std::vector<T>& value)
    -> std::vector<std::decay_t<decltype(std::declval<const ElementMapper&>()(std::declval<const T&>()))>> {
    return mapper.map_value(value);
}

using ObjectField = std::any;
using ObjectRecord = std::map<std::string, ObjectField>;

class MapRangeMapper {
public:
    using MapperRef = std::variant<
        IntegerRangeMapper,
        FloatRangeMapper,
        BooleanRangeMapper,
        BytesRangeMapper,
        CategoricalRangeMapper,
        TemporalRangeMapper,
        ImageRangeMapper,
        std::shared_ptr<MapRangeMapper>
    >;
    using ObjectSchema = std::map<std::string, MapperRef>;
    using MappedRecord = std::map<std::string, std::any>;

    MapRangeMapper(const ObjectSchema& schema, bool allow_unknown = false, bool allow_empty = false)
        : MapRangeMapper(schema, allow_unknown, allow_empty, false, std::any{}) {
    }

    MapRangeMapper(
        const ObjectSchema& schema,
        bool allow_unknown,
        bool allow_empty,
        bool has_missing_value,
        std::any missing_value)
        : schema_(validate_schema(schema, allow_empty)),
          allow_unknown_(allow_unknown),
          allow_empty_(allow_empty),
          has_missing_value_(has_missing_value),
          missing_value_(std::move(missing_value)) {
    }

    MappedRecord map_value(const ObjectRecord& value) const {
        return map(value);
    }

    MappedRecord map(const ObjectRecord& value) const {
        if (!allow_empty_ && value.empty()) {
            throw std::invalid_argument("empty object payload is invalid by default; set allow_empty=true to map empty objects.");
        }

        if (!allow_unknown_) {
            for (const auto& item : value) {
                if (schema_.find(item.first) == schema_.end()) {
                    throw std::invalid_argument(
                        "object map has unknown fields; set allow_unknown=true to accept keys not declared in schema."
                    );
                }
            }
        }

        MappedRecord output;
        for (const auto& schema_item : schema_) {
            const auto field_name = schema_item.first;
            const auto& mapper = schema_item.second;
            auto value_it = value.find(field_name);
            if (value_it != value.end()) {
                output[field_name] = map_field(mapper, field_name, value_it->second);
                continue;
            }
            if (has_missing_value_) {
                output[field_name] = missing_value_;
                continue;
            }
            throw std::invalid_argument("missing required field '" + field_name + "' in object input.");
        }

        return output;
    }

    std::string to_json() const {
        std::string schema_text = "{";
        bool first_schema = true;
        for (const auto& item : schema_) {
            if (!first_schema) {
                schema_text += ",";
            }
            first_schema = false;
            schema_text += "\"" + escape(item.first) + "\":" + map_to_json(item.second);
        }
        schema_text += "}";

        std::string missing_value = "null";
        if (has_missing_value_) {
            missing_value = serialize_any(missing_value_);
        }

        std::string output = "{";
        output += "\"spec_version\":\"" + std::string(spec_version) + "\",";
        output += "\"mapper_type\":\"" + std::string(mapper_type_map_range) + "\",";
        output += "\"schema\":" + schema_text + ",";
        output += "\"allow_unknown\":" + std::string(allow_unknown_ ? "true" : "false") + ",";
        output += "\"allow_empty\":" + std::string(allow_empty_ ? "true" : "false") + ",";
        output += "\"has_missing_value\":" + std::string(has_missing_value_ ? "true" : "false");
        if (has_missing_value_) {
            output += ",\"missing_value\":" + missing_value;
        }
        output += "}";
        return output;
    }

    static MapRangeMapper from_json(const std::string& json) {
        if (json.empty()) {
            throw std::invalid_argument("mapper json must not be empty.");
        }
        if (extract_string(json, "spec_version") != spec_version) {
            throw std::invalid_argument("unsupported spec_version");
        }
        if (extract_string(json, "mapper_type") != mapper_type_map_range) {
            throw std::invalid_argument("unsupported mapper_type");
        }
        bool allow_unknown = extract_bool(json, "allow_unknown", false);
        bool allow_empty = extract_bool(json, "allow_empty", false);
        bool has_missing_value = extract_bool(json, "has_missing_value", false);
        bool has_missing_value_key = has_key(json, "missing_value");
        std::any missing_value;
        if (has_missing_value) {
            if (!has_missing_value_key) {
                throw std::invalid_argument("missing_value is required when has_missing_value=true.");
            }
            const std::string raw_missing = extract_raw_value(json, "missing_value");
            missing_value = parse_missing_value(raw_missing);
        }

        const std::string schema_json = extract_object(json, "schema");
        ObjectSchema schema = parse_schema(schema_json);
        return MapRangeMapper(schema, allow_unknown, allow_empty, has_missing_value, missing_value);
    }

private:
    static ObjectSchema parse_schema(const std::string& text) {
        if (text.empty()) {
            throw std::invalid_argument("schema cannot be empty.");
        }
        const auto body = strip_outer_object(text);
        ObjectSchema schema;
        size_t index = 0;
        while (index < body.size()) {
            index = skip_whitespace(body, index);
            if (index >= body.size()) {
                break;
            }
            if (body[index] != '"') {
                throw std::invalid_argument("invalid schema json key.");
            }
            const auto key_start = index + 1;
            const auto key_end = find_end_of_quoted(body, key_start);
            if (key_end <= key_start) {
                throw std::invalid_argument("empty schema field name.");
            }
            const auto key = body.substr(key_start, key_end - key_start);
            index = key_end + 1;
            index = skip_whitespace(body, index);
            if (index >= body.size() || body[index] != ':') {
                throw std::invalid_argument("expected ':' after schema key '" + key + "'.");
            }
            ++index;
            index = skip_whitespace(body, index);
            if (index >= body.size() || body[index] != '{') {
                throw std::invalid_argument("schema value for '" + key + "' must be an object.");
            }
            const auto mapper_text = extract_object_from_index(body, index);
            schema.emplace(key, parse_mapper(mapper_text));
            index += mapper_text.size();
            index = skip_whitespace(body, index);
            if (index < body.size() && body[index] == ',') {
                ++index;
            }
        }
        return schema;
    }

    static MapperRef parse_mapper(const std::string& json) {
        const std::string mapper_type = extract_string(json, "mapper_type");
        if (mapper_type == mapper_type_integer_range) {
            return parse_integer_mapper(json);
        }
        if (mapper_type == mapper_type_float_range) {
            return parse_float_mapper(json);
        }
        if (mapper_type == mapper_type_boolean_range) {
            return parse_boolean_mapper(json);
        }
        if (mapper_type == mapper_type_bytes_range) {
            return parse_bytes_mapper(json);
        }
        if (mapper_type == mapper_type_categorical_range) {
            return parse_categorical_mapper(json);
        }
        if (mapper_type == mapper_type_temporal_range) {
            return parse_temporal_mapper(json);
        }
        if (mapper_type == mapper_type_image_range) {
            return parse_image_mapper(json);
        }
        if (mapper_type == mapper_type_map_range) {
            const bool allow_unknown = extract_bool(json, "allow_unknown", false);
            const bool allow_empty = extract_bool(json, "allow_empty", false);
            const bool has_missing_value = extract_bool(json, "has_missing_value", false);
            const bool has_missing = has_key(json, "missing_value");
            std::any missing_value;
            if (has_missing_value) {
                if (!has_missing) {
                    throw std::invalid_argument("missing_value is required when has_missing_value=true.");
                }
                missing_value = parse_missing_value(extract_raw_value(json, "missing_value"));
            }
            ObjectSchema schema = parse_schema(extract_object(json, "schema"));
            return std::make_shared<MapRangeMapper>(schema, allow_unknown, allow_empty, has_missing_value, missing_value);
        }
        throw std::invalid_argument("unsupported mapper_type " + mapper_type);
    }

    static IntegerRangeMapper parse_integer_mapper(const std::string& json) {
        const auto input_range = extract_int64_pair(json, "input_range");
        const auto output_range = extract_double_pair(json, "output_range");
        const bool clip = extract_bool(json, "clip", false);
        return IntegerRangeMapper(input_range[0], input_range[1], output_range[0], output_range[1], clip);
    }

    static FloatRangeMapper parse_float_mapper(const std::string& json) {
        const auto input_range = extract_double_pair(json, "input_range");
        const auto output_range = extract_double_pair(json, "output_range");
        const bool clip = extract_bool(json, "clip", false);
        return FloatRangeMapper(input_range[0], input_range[1], output_range[0], output_range[1], clip);
    }

    static BooleanRangeMapper parse_boolean_mapper(const std::string& json) {
        const auto output_range = extract_double_pair(json, "output_range");
        const double false_value = extract_double(json, "false_value", output_range[0]);
        const double true_value = extract_double(json, "true_value", output_range[1]);
        return BooleanRangeMapper(output_range[0], output_range[1], false_value, true_value);
    }

    static BytesRangeMapper parse_bytes_mapper(const std::string& json) {
        const auto output_range = extract_double_pair(json, "output_range");
        const bool clip = extract_bool(json, "clip", false);
        const bool allow_empty = extract_bool(json, "allow_empty", false);
        return BytesRangeMapper(output_range[0], output_range[1], clip, allow_empty);
    }

    static CategoricalRangeMapper parse_categorical_mapper(const std::string& json) {
        const auto vocabulary = extract_string_array(json, "vocabulary");
        const auto output_range = extract_double_pair(json, "output_range");
        const std::string name = extract_string(json, "name", "");
        std::vector<std::any> decoded;
        decoded.reserve(vocabulary.size());
        for (const auto& token : vocabulary) {
            decoded.push_back(CategoricalRangeMapper::decode_spec_token(token));
        }
        return CategoricalRangeMapper(decoded, output_range[0], output_range[1], name);
    }

    static TemporalRangeMapper parse_temporal_mapper(const std::string& json) {
        const auto input_range = extract_double_pair(json, "input_range");
        const auto output_range = extract_double_pair(json, "output_range");
        const bool clip = extract_bool(json, "clip", false);
        const std::string input_unit = extract_string(json, "input_unit");
        return TemporalRangeMapper(input_range[0], input_range[1], output_range[0], output_range[1], clip, input_unit);
    }

    static ImageRangeMapper parse_image_mapper(const std::string& json) {
        const auto output_range = extract_double_pair(json, "output_range");
        const bool clip = extract_bool(json, "clip", false);
        const bool allow_empty = extract_bool(json, "allow_empty", false);
        return ImageRangeMapper(output_range[0], output_range[1], clip, allow_empty);
    }

    static std::string extract_string(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":\"";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        const auto value_start = start + needle.size();
        const auto end = text.find('"', value_start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated string for ") + key);
        }
        return text.substr(value_start, end - value_start);
    }

    static bool extract_bool(const std::string& text, const char* key, bool default_value) {
        const std::string needle = std::string("\"") + key + "\":";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            return default_value;
        }
        const auto index = start + needle.size();
        if (text.compare(index, 4, "true") == 0) {
            return true;
        }
        if (text.compare(index, 5, "false") == 0) {
            return false;
        }
        throw std::invalid_argument(std::string("invalid boolean for ") + key);
    }

    static std::vector<std::string> extract_string_array(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string body = text.substr(start, end - start);
        std::vector<std::string> output;
        std::size_t index = 0;
        while (index < body.size()) {
            index = skip_whitespace(body, index);
            if (index >= body.size()) {
                break;
            }
            if (body[index] != '"') {
                throw std::invalid_argument(std::string(key) + " must contain quoted token strings");
            }
            const auto token_end = find_end_of_quoted(body, index + 1);
            output.push_back(body.substr(index + 1, token_end - index - 1));
            index = token_end + 1;
            index = skip_whitespace(body, index);
            if (index < body.size() && body[index] == ',') {
                ++index;
            }
        }
        return output;
    }

    static std::size_t find_end_of_quoted(const std::string& text, std::size_t start) {
        bool escaped = false;
        for (std::size_t i = start; i < text.size(); ++i) {
            const char c = text[i];
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
                continue;
            }
            if (c == '"') {
                return i;
            }
        }
        throw std::invalid_argument("unterminated string");
    }

    static std::size_t skip_whitespace(const std::string& text, std::size_t index) {
        while (index < text.size() && std::isspace(static_cast<unsigned char>(text[index]))) {
            ++index;
        }
        return index;
    }

    static bool has_key(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":";
        return text.find(needle) != std::string::npos;
    }

    static std::string extract_raw_value(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            return "";
        }
        start += needle.size();
        start = skip_whitespace(text, start);
        if (start >= text.size()) {
            return "";
        }
        std::size_t end = start;
        if (text[start] == '"') {
            end = find_end_of_quoted(text, start + 1) + 1;
        } else {
            while (end < text.size() && text[end] != ',' && text[end] != '}') {
                ++end;
            }
        }
        return text.substr(start, end - start);
    }

    static double extract_double(const std::string& text, const char* key, double default_value) {
        const std::string needle = std::string("\"") + key + "\":";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            return default_value;
        }
        start += needle.size();
        auto end = text.find(',', start);
        if (end == std::string::npos) {
            end = text.find('}', start);
        }
        return std::stod(text.substr(start, end - start));
    }

    static std::array<double, 2> extract_double_pair(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string values = text.substr(start, end - start);
        const auto delimiter = values.find(',');
        if (delimiter == std::string::npos) {
            throw std::invalid_argument(std::string(key) + " must contain two values");
        }
        return {
            std::stod(values.substr(0, delimiter)),
            std::stod(values.substr(delimiter + 1)),
        };
    }

    static std::array<std::int64_t, 2> extract_int64_pair(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":[";
        auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        start += needle.size();
        const auto end = text.find(']', start);
        if (end == std::string::npos) {
            throw std::invalid_argument(std::string("unterminated array for ") + key);
        }
        const std::string values = text.substr(start, end - start);
        const auto delimiter = values.find(',');
        if (delimiter == std::string::npos) {
            throw std::invalid_argument(std::string(key) + " must contain two values");
        }
        return {
            std::stoll(values.substr(0, delimiter)),
            std::stoll(values.substr(delimiter + 1)),
        };
    }

    static std::string extract_object(const std::string& text, const char* key) {
        const std::string needle = std::string("\"") + key + "\":";
        const auto start = text.find(needle);
        if (start == std::string::npos) {
            throw std::invalid_argument(std::string("missing key ") + key);
        }
        auto index = start + needle.size();
        index = skip_whitespace(text, index);
        if (index >= text.size() || text[index] != '{') {
            throw std::invalid_argument(std::string("expected object for ") + key);
        }
        return extract_object_from_index(text, index);
    }

    static std::string extract_object_from_index(const std::string& text, std::size_t start) {
        bool in_string = false;
        bool escape = false;
        int depth = 0;
        for (std::size_t i = start; i < text.size(); ++i) {
            const char c = text[i];
            if (escape) {
                escape = false;
                continue;
            }
            if (c == '\\') {
                escape = true;
                continue;
            }
            if (c == '"') {
                in_string = !in_string;
                continue;
            }
            if (in_string) {
                continue;
            }
            if (c == '{') {
                ++depth;
                continue;
            }
            if (c == '}') {
                --depth;
                if (depth == 0) {
                    return text.substr(start, i - start + 1);
                }
            }
        }
        throw std::invalid_argument("unterminated object");
    }

    static std::size_t find_end_of_quoted(const std::string& text, std::size_t start) {
        bool escape = false;
        for (std::size_t i = start; i < text.size(); ++i) {
            if (escape) {
                escape = false;
                continue;
            }
            if (text[i] == '\\') {
                escape = true;
                continue;
            }
            if (text[i] == '"') {
                return i;
            }
        }
        throw std::invalid_argument("unterminated quoted value");
    }

    static std::string strip_outer_object(const std::string& text) {
        if (text.empty()) {
            return "";
        }
        if (text.front() != '{' || text.back() != '}') {
            throw std::invalid_argument("expected object.");
        }
        if (text.size() <= 2) {
            return "";
        }
        return text.substr(1, text.size() - 2);
    }

    static std::size_t skip_whitespace(const std::string& text, std::size_t index) {
        while (index < text.size() && std::isspace(static_cast<unsigned char>(text[index]))) {
            ++index;
        }
        return index;
    }

    std::string map_to_json(const MapperRef& mapper) const {
        return std::visit(
            [](const auto& value) {
                return value.to_json();
            },
            mapper
        );
    }

    static std::any parse_missing_value(const std::string& text) {
        const std::string value = normalize(text);
        if (value.empty()) {
            throw std::invalid_argument("missing_value cannot be empty.");
        }
        if (value == "null") {
            return std::any{};
        }
        if (value == "true") {
            return true;
        }
        if (value == "false") {
            return false;
        }
        if (value.front() == '"') {
            if (value.back() != '"') {
                throw std::invalid_argument("invalid missing_value json string.");
            }
            return unescape(value.substr(1, value.size() - 2));
        }
        if (value.find('.') != std::string::npos || value.find('e') != std::string::npos || value.find('E') != std::string::npos) {
            return std::stod(value);
        }
        return std::stoll(value);
    }

    static std::string serialize_any(const std::any& value) {
        if (!value.has_value()) {
            return "null";
        }
        if (value.type() == typeid(std::string)) {
            return "\"" + escape(std::any_cast<const std::string&>(value)) + "\"";
        }
        if (value.type() == typeid(double)) {
            return std::to_string(std::any_cast<double>(value));
        }
        if (value.type() == typeid(float)) {
            return std::to_string(static_cast<double>(std::any_cast<float>(value)));
        }
        if (value.type() == typeid(std::int64_t)) {
            return std::to_string(std::any_cast<std::int64_t>(value));
        }
        if (value.type() == typeid(std::int32_t)) {
            return std::to_string(std::any_cast<std::int32_t>(value));
        }
        if (value.type() == typeid(std::uint64_t)) {
            return std::to_string(std::any_cast<std::uint64_t>(value));
        }
        if (value.type() == typeid(std::uint32_t)) {
            return std::to_string(std::any_cast<std::uint32_t>(value));
        }
        if (value.type() == typeid(bool)) {
            return std::any_cast<bool>(value) ? "true" : "false";
        }
        throw std::invalid_argument("unsupported missing_value type.");
    }

    std::any map_field(const MapperRef& mapper, const std::string& field_name, const ObjectField& value) const {
        if (std::holds_alternative<IntegerRangeMapper>(mapper)) {
            const IntegerRangeMapper& integer_mapper = std::get<IntegerRangeMapper>(mapper);
            if (value.type() == typeid(std::int64_t)) {
                return integer_mapper.map_value(std::any_cast<std::int64_t>(value));
            }
            if (value.type() == typeid(std::int32_t)) {
                return integer_mapper.map_value(std::any_cast<std::int32_t>(value));
            }
            if (value.type() == typeid(std::int16_t)) {
                return integer_mapper.map_value(std::any_cast<std::int16_t>(value));
            }
            if (value.type() == typeid(std::uint8_t)) {
                return integer_mapper.map_value(std::any_cast<std::uint8_t>(value));
            }
            if (value.type() == typeid(std::uint16_t)) {
                return integer_mapper.map_value(std::any_cast<std::uint16_t>(value));
            }
            if (value.type() == typeid(std::uint32_t)) {
                return integer_mapper.map_value(std::any_cast<std::uint32_t>(value));
            }
            if (value.type() == typeid(std::uint64_t)) {
                if (std::any_cast<std::uint64_t>(value) > static_cast<std::uint64_t>(LLONG_MAX)) {
                    throw std::invalid_argument("field '" + field_name + "' integer value is out of int64_t range.");
                }
                return integer_mapper.map_value(static_cast<std::int64_t>(std::any_cast<std::uint64_t>(value)));
            }
            if (value.type() == typeid(std::size_t)) {
                if (std::any_cast<std::size_t>(value) > static_cast<std::size_t>(LLONG_MAX)) {
                    throw std::invalid_argument("field '" + field_name + "' integer value is out of int64_t range.");
                }
                return integer_mapper.map_value(static_cast<std::int64_t>(std::any_cast<std::size_t>(value)));
            }
            if (value.type() == typeid(bool)) {
                throw std::invalid_argument("field '" + field_name + "' expects integer values.");
            }
            throw std::invalid_argument("field '" + field_name + "' expects integer values.");
        }

        if (std::holds_alternative<FloatRangeMapper>(mapper)) {
            const FloatRangeMapper& float_mapper = std::get<FloatRangeMapper>(mapper);
            if (value.type() == typeid(double)) {
                return float_mapper.map_value(std::any_cast<double>(value));
            }
            if (value.type() == typeid(float)) {
                return float_mapper.map_value(static_cast<double>(std::any_cast<float>(value)));
            }
            if (value.type() == typeid(std::int64_t)) {
                return float_mapper.map_value(static_cast<double>(std::any_cast<std::int64_t>(value)));
            }
            if (value.type() == typeid(std::int32_t)) {
                return float_mapper.map_value(static_cast<double>(std::any_cast<std::int32_t>(value)));
            }
            throw std::invalid_argument("field '" + field_name + "' expects float values.");
        }

        if (std::holds_alternative<BooleanRangeMapper>(mapper)) {
            const BooleanRangeMapper& bool_mapper = std::get<BooleanRangeMapper>(mapper);
            if (value.type() != typeid(bool)) {
                throw std::invalid_argument("field '" + field_name + "' expects boolean values.");
            }
            return bool_mapper.map_value(std::any_cast<bool>(value));
        }

        if (std::holds_alternative<BytesRangeMapper>(mapper)) {
            const BytesRangeMapper& bytes_mapper = std::get<BytesRangeMapper>(mapper);
            if (value.type() == typeid(std::string)) {
                return bytes_mapper.map(std::any_cast<std::string>(value));
            }
            if (value.type() == typeid(std::vector<unsigned char>)) {
                return bytes_mapper.map_value(std::any_cast<std::vector<unsigned char>>(value));
            }
            if (value.type() == typeid(std::vector<int>)) {
                return bytes_mapper.map_value(std::any_cast<std::vector<int>>(value));
            }
            throw std::invalid_argument(
                "field '" + field_name + "' expects bytes-compatible values (string, vector<int>, vector<unsigned char>)."
            );
        }

        if (std::holds_alternative<CategoricalRangeMapper>(mapper)) {
            const CategoricalRangeMapper& categorical_mapper = std::get<CategoricalRangeMapper>(mapper);
            return categorical_mapper.map(value);
        }

        if (std::holds_alternative<TemporalRangeMapper>(mapper)) {
            const TemporalRangeMapper& temporal_mapper = std::get<TemporalRangeMapper>(mapper);
            if (value.type() == typeid(double)) {
                return temporal_mapper.map_value(std::any_cast<double>(value));
            }
            if (value.type() == typeid(float)) {
                return temporal_mapper.map_value(static_cast<double>(std::any_cast<float>(value)));
            }
            if (value.type() == typeid(std::int64_t)) {
                return temporal_mapper.map_value(std::any_cast<std::int64_t>(value));
            }
            if (value.type() == typeid(std::chrono::system_clock::time_point)) {
                return temporal_mapper.map_value(std::any_cast<std::chrono::system_clock::time_point>(value));
            }
            throw std::invalid_argument(
                "field '" + field_name + "' expects temporal values (double, float, int64_t, or std::chrono::system_clock::time_point)."
            );
        }

        if (std::holds_alternative<ImageRangeMapper>(mapper)) {
            const ImageRangeMapper& image_mapper = std::get<ImageRangeMapper>(mapper);
            if (value.type() == typeid(std::string)) {
                return image_mapper.map(std::any_cast<std::string>(value));
            }
            if (value.type() == typeid(std::vector<int>)) {
                return image_mapper.map_value(std::any_cast<std::vector<int>>(value));
            }
            if (value.type() == typeid(std::vector<unsigned char>)) {
                return image_mapper.map_value(std::any_cast<std::vector<unsigned char>>(value));
            }
            if (value.type() == typeid(std::vector<double>)) {
                return image_mapper.map_value(std::any_cast<std::vector<double>>(value));
            }
            if (value.type() == typeid(std::vector<std::vector<int>>)) {
                return image_mapper.map_value(std::any_cast<std::vector<std::vector<int>>>(value));
            }
            if (value.type() == typeid(std::vector<std::vector<unsigned char>>)) {
                return image_mapper.map_value(std::any_cast<std::vector<std::vector<unsigned char>>>(value));
            }
            if (value.type() == typeid(std::vector<std::vector<double>>)) {
                return image_mapper.map_value(std::any_cast<std::vector<std::vector<double>>>(value));
            }
            throw std::invalid_argument(
                "field '" + field_name + "' expects image-compatible values (string, vector<int>, vector<unsigned char>, vector<double>, or nested vector containers)."
            );
        }

        if (std::holds_alternative<std::shared_ptr<MapRangeMapper>>(mapper)) {
            const auto mapper_ptr = std::get<std::shared_ptr<MapRangeMapper>>(mapper);
            if (!mapper_ptr) {
                throw std::invalid_argument("field '" + field_name + "' has invalid nested map mapper.");
            }
            if (value.type() != typeid(ObjectRecord)) {
                throw std::invalid_argument("field '" + field_name + "' expects a nested object record.");
            }
            return mapper_ptr->map(std::any_cast<const ObjectRecord&>(value));
        }

        throw std::invalid_argument("unsupported mapper in map schema for field '" + field_name + "'.");
    }

    static std::string escape(const std::string& value) {
        std::string output;
        output.reserve(value.size() + 4);
        for (char ch : value) {
            if (ch == '\\') {
                output += "\\\\";
            } else if (ch == '"') {
                output += "\\\"";
            } else {
                output.push_back(ch);
            }
        }
        return output;
    }

    static std::string unescape(const std::string& value) {
        std::string output;
        output.reserve(value.size());
        bool escape = false;
        for (char ch : value) {
            if (escape) {
                if (ch == '\\') {
                    output.push_back('\\');
                } else if (ch == '"') {
                    output.push_back('"');
                } else {
                    output.push_back(ch);
                }
                escape = false;
            } else if (ch == '\\') {
                escape = true;
            } else {
                output.push_back(ch);
            }
        }
        if (escape) {
            output.push_back('\\');
        }
        return output;
    }

    static std::string normalize(const std::string& text) {
        auto begin = text.find_first_not_of(" \t\r\n");
        if (begin == std::string::npos) {
            return "";
        }
        auto end = text.find_last_not_of(" \t\r\n");
        return text.substr(begin, end - begin + 1);
    }

    static ObjectSchema validate_schema(const ObjectSchema& schema, bool allow_empty) {
        if (!allow_empty && schema.empty()) {
            throw std::invalid_argument("schema is empty by default; set allow_empty=true to allow empty schema.");
        }
        for (const auto& item : schema) {
            if (item.first.empty()) {
                throw std::invalid_argument("schema field names must be non-empty.");
            }
            if (std::holds_alternative<std::shared_ptr<MapRangeMapper>>(item.second) &&
                std::get<std::shared_ptr<MapRangeMapper>>(item.second) == nullptr) {
                throw std::invalid_argument("schema field '" + item.first + "' mapper pointer is null.");
            }
        }
        return schema;
    }

    static std::string serialize_mapped(const std::any& value) {
        if (value.type() == typeid(double)) {
            return std::to_string(std::any_cast<double>(value));
        }
        if (value.type() == typeid(float)) {
            return std::to_string(std::any_cast<float>(value));
        }
        if (value.type() == typeid(std::vector<double>)) {
            const auto mapped_vector = std::any_cast<const std::vector<double>&>(value);
            std::string text = "[";
            bool first = true;
            for (double item : mapped_vector) {
                if (!first) {
                    text += ",";
                }
                first = false;
                text += std::to_string(item);
            }
            text += "]";
            return text;
        }
        if (value.type() == typeid(MappedRecord)) {
            return serialize_record(std::any_cast<const MappedRecord&>(value));
        }
        return serialize_any(value);
    }

    static std::string serialize_record(const MappedRecord& record) {
        std::string text = "{";
        bool first = true;
        for (const auto& item : record) {
            if (!first) {
                text += ",";
            }
            first = false;
            text += "\"" + escape(item.first) + "\":";
            text += serialize_mapped(item.second);
        }
        text += "}";
        return text;
    }

    ObjectSchema schema_;
    bool allow_unknown_;
    bool allow_empty_;
    bool has_missing_value_;
    std::any missing_value_;
};

} // namespace librangemap
