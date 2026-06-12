#include <cassert>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>

#include "../include/librangemap.hpp"

using librangemap::BooleanRangeMapper;
using librangemap::FloatRangeMapper;
using librangemap::IntegerRangeMapper;
using librangemap::MapRangeMapper;
using librangemap::BytesRangeMapper;
using librangemap::CategoricalRangeMapper;
using librangemap::TemporalRangeMapper;
using librangemap::ImageRangeMapper;

static void assert_equal(double actual, double expected, const char* label) {
    if (actual != expected) {
        std::cerr << label << " = " << actual << ", expected " << expected << '\n';
        std::exit(1);
    }
}

int main() {
    IntegerRangeMapper mapper(0, 100);
    assert_equal(mapper.map_value(0), -1.0, "map_value(0)");
    assert_equal(mapper.map_value(50), 0.0, "map_value(50)");
    assert_equal(mapper.map_value(100), 1.0, "map_value(100)");

    const auto spec = mapper.spec();
    if (spec.spec_version != librangemap::spec_version) {
        std::cerr << "unexpected spec version\n";
        return 1;
    }

    const auto repeated_first = mapper.map_value(50);
    const auto repeated_second = mapper.map_value(50);
    assert_equal(repeated_first, repeated_second, "repeated.map_value(50)");

    IntegerRangeMapper clipped(0, 10, -1.0, 1.0, true);
    assert_equal(clipped.map_value(-5), -1.0, "clipped.map_value(-5)");

    bool threw = false;
    try {
        IntegerRangeMapper strict(0, 10, -1.0, 1.0, false);
        (void)strict.map_value(11);
    } catch (const std::runtime_error&) {
        threw = true;
    }

    if (!threw) {
        std::cerr << "expected strict mode to reject out-of-range input\n";
        return 1;
    }

    FloatRangeMapper float_mapper(0.0, 10.0, -1.0, 1.0);
    assert_equal(float_mapper.map_value(0.0), -1.0, "float.map_value(0)");
    assert_equal(float_mapper.map_value(5.0), 0.0, "float.map_value(5)");
    assert_equal(float_mapper.map_value(10.0), 1.0, "float.map_value(10)");

    bool float_threw = false;
    try {
        FloatRangeMapper strict_float_mapper(0.0, 10.0, -1.0, 1.0, false);
        (void)strict_float_mapper.map_value(11.0);
    } catch (const std::runtime_error&) {
        float_threw = true;
    }
    if (!float_threw) {
        std::cerr << "expected strict float mode to reject out-of-range input\n";
        return 1;
    }

    FloatRangeMapper clipped_float(0.0, 10.0, -1.0, 1.0, true);
    assert_equal(clipped_float.map_value(-5.0), -1.0, "clipped float.map_value(-5)");
    assert_equal(clipped_float.map_value(15.0), 1.0, "clipped float.map_value(15)");

    BooleanRangeMapper boolean_mapper;
    assert_equal(boolean_mapper.map_value(false), -1.0, "bool false");
    assert_equal(boolean_mapper.map_value(true), 1.0, "bool true");

    TextRangeMapper text_mapper;
    const auto text_codepoint = text_mapper.map_value("Ada");
    if (text_codepoint.size() != 3u) {
        std::cerr << "text codepoint size = " << text_codepoint.size() << ", expected 3\n";
        return 1;
    }
    const auto text_repeat = text_mapper.map_value("Ada");
    if (text_repeat != text_codepoint) {
        std::cerr << "text repeated mapping changed output\n";
        return 1;
    }
    const auto alphabet_text = TextRangeMapper(TextRangeMapper::Mode::Alphabet, "abc");
    const auto alphabet_result = alphabet_text.map_value("abc");
    if (alphabet_result.size() != 3u || alphabet_result[1] != 0.0) {
        std::cerr << "alphabet text mapping unexpected\n";
        return 1;
    }
    bool text_unknown = false;
    try {
        (void)alphabet_text.map_value("abd");
    } catch (const std::invalid_argument&) {
        text_unknown = true;
    }
    if (!text_unknown) {
        std::cerr << "expected text unknown token to fail\n";
        return 1;
    }
    bool text_duplicate = false;
    try {
        TextRangeMapper duplicate_text(TextRangeMapper::Mode::Alphabet, "abca");
        (void)duplicate_text;
    } catch (const std::runtime_error&) {
        text_duplicate = true;
    }
    if (!text_duplicate) {
        std::cerr << "expected duplicate text alphabet to fail\n";
        return 1;
    }

    BooleanRangeMapper custom_boolean(-1.0, 1.0, 0.2, 0.8);
    assert_equal(custom_boolean.map_value(false), 0.2, "bool false custom");
    assert_equal(custom_boolean.map_value(true), 0.8, "bool true custom");

    BytesRangeMapper bytes_mapper;
    const auto bytes_result = bytes_mapper.map(std::string("\x00\x7f", 2));
    if (bytes_result.size() != 2u) {
        std::cerr << "bytes_result size = " << bytes_result.size() << ", expected 2\n";
        return 1;
    }
    assert_equal(bytes_result[0], -1.0, "bytes_mapper map from std::string byte 0");
    assert_equal(bytes_result[1], ((127.0 / 255.0) * 2.0 - 1.0), "bytes_mapper map from std::string byte 127");
    assert_equal(bytes_mapper.map_value(std::vector<int>{0, 255})[1], 1.0, "bytes_mapper map from int vector");
    const auto bytes_repeat = bytes_mapper.map(std::string("\x00\x7f", 2));
    if (bytes_repeat.size() != bytes_result.size() || bytes_repeat[0] != bytes_result[0] || bytes_repeat[1] != bytes_result[1]) {
        std::cerr << "bytes repeated mapping changed output\n";
        return 1;
    }

    const auto bytes_roundtrip = BytesRangeMapper::from_json(bytes_mapper.to_json());
    assert_equal(bytes_roundtrip.map(std::string("\x00", 1))[0], -1.0, "bytes mapper roundtrip map");

    CategoricalRangeMapper categorical_mapper(std::vector<std::any>{
        std::string("cat"),
        std::int64_t{1},
        true,
        'x',
        2.5,
    });
    assert_equal(categorical_mapper.map_value(std::string("cat")), -1.0, "categorical map string");
    assert_equal(categorical_mapper.map_value(std::int64_t{1}), -0.5, "categorical map integer");
    assert_equal(categorical_mapper.map_value(true), 0.0, "categorical map bool");
    assert_equal(categorical_mapper.map_value('x'), 0.5, "categorical map char");
    assert_equal(categorical_mapper.map_value(2.5), 1.0, "categorical map float");
    assert_equal(categorical_mapper.map_value(std::string("cat")), categorical_mapper.map_value(std::string("cat")), "categorical repeated mapping");

    const auto categorical_roundtrip = CategoricalRangeMapper::from_json(categorical_mapper.to_json());
    assert_equal(categorical_roundtrip.map_value(true), 0.0, "categorical roundtrip map");

    bool categorical_unknown = false;
    try {
        (void)categorical_mapper.map_value(std::string("wolf"));
    } catch (const std::invalid_argument&) {
        categorical_unknown = true;
    }
    if (!categorical_unknown) {
        std::cerr << "expected categorical unknown token to fail\n";
        return 1;
    }

    bool categorical_duplicate = false;
    try {
        CategoricalRangeMapper duplicate_mapper(std::vector<std::any>{std::string("cat"), std::string("cat")});
        (void)duplicate_mapper;
    } catch (const std::invalid_argument&) {
        categorical_duplicate = true;
    }
    if (!categorical_duplicate) {
        std::cerr << "expected categorical duplicate token to fail\n";
        return 1;
    }

    TemporalRangeMapper temporal_mapper(0.0, 100.0);
    assert_equal(temporal_mapper.map_value(0.0), -1.0, "temporal map value 0");
    assert_equal(temporal_mapper.map_value(50.0), 0.0, "temporal map value 50");
    assert_equal(temporal_mapper.map_value(100.0), 1.0, "temporal map value 100");
    const auto temporal_repeat = temporal_mapper.map_value(50.0);
    assert_equal(temporal_repeat, temporal_mapper.map_value(50.0), "temporal repeated mapping");
    const auto temporal_roundtrip = TemporalRangeMapper::from_json(temporal_mapper.to_json());
    assert_equal(temporal_roundtrip.map_value(50.0), 0.0, "temporal mapper roundtrip map");

    ImageRangeMapper image_mapper;
    const auto image_bytes = image_mapper.map(std::string("\x00\x80\xff", 3));
    if (image_bytes.size() != 3u) {
        std::cerr << "image_bytes size = " << image_bytes.size() << ", expected 3\n";
        return 1;
    }
    assert_equal(image_bytes[0], -1.0, "image bytes byte 0");
    assert_equal(image_bytes[1], (128.0 / 255.0) * 2.0 - 1.0, "image bytes byte 128");
    assert_equal(image_bytes[2], 1.0, "image bytes byte 255");

    const auto image_rows = image_mapper.map_value(std::vector<std::vector<int>>{
        {0, 128, 255},
        {64, 192, 32},
    });
    const auto image_rows_repeat = image_mapper.map_value(std::vector<std::vector<int>>{
        {0, 128, 255},
        {64, 192, 32},
    });
    if (image_rows.size() != 2u || image_rows[0].size() != 3u || image_rows[1].size() != 3u) {
        std::cerr << "image nested mapping size unexpected\n";
        return 1;
    }
    if (image_rows[0][0] != -1.0 || image_rows[0][2] != 1.0 || image_rows[1][1] != (192.0 / 255.0) * 2.0 - 1.0) {
        std::cerr << "image nested mapping values unexpected\n";
        return 1;
    }
    if (image_rows_repeat != image_rows) {
        std::cerr << "image repeated mapping changed output\n";
        return 1;
    }

    const auto image_roundtrip = ImageRangeMapper::from_json(image_mapper.to_json());
    const auto image_roundtrip_rows = image_roundtrip.map_value(std::vector<std::vector<int>>{
        {0, 128, 255},
        {64, 192, 32},
    });
    if (image_roundtrip_rows != image_rows) {
        std::cerr << "image mapper roundtrip changed output\n";
        return 1;
    }

    bool image_strict = false;
    try {
        image_mapper.map_value(std::vector<int>{256});
    } catch (const std::runtime_error&) {
        image_strict = true;
    }
    if (!image_strict) {
        std::cerr << "expected image strict mode to reject out of range values\n";
        return 1;
    }

    bool bytes_strict = false;
    try {
        bytes_mapper.map_value(std::vector<int>{256});
    } catch (const std::runtime_error&) {
        bytes_strict = true;
    }
    if (!bytes_strict) {
        std::cerr << "expected bytes strict mode to reject out of range values\n";
        return 1;
    }

    struct IntegerSequenceElementMapper {
        IntegerRangeMapper integer_mapper{0, 100};

        double operator()(const std::int64_t& value) const {
            return integer_mapper.map_value(value);
        }

        std::vector<double> operator()(const std::vector<std::int64_t>& value) const {
            std::vector<double> output;
            output.reserve(value.size());
            for (const auto& item : value) {
                output.push_back(integer_mapper.map_value(item));
            }
            return output;
        }
    };

    const auto sequence_mapper = librangemap::create_sequence_mapper(IntegerSequenceElementMapper{});
    const auto sequence_values = sequence_mapper.map_value(std::vector<std::int64_t>{0, 50, 100});
    if (sequence_values.size() != 3u || sequence_values[0] != -1.0 || sequence_values[1] != 0.0 || sequence_values[2] != 1.0) {
        std::cerr << "sequence scalar mapping unexpected\n";
        return 1;
    }
    const auto sequence_repeat = sequence_mapper.map_value(std::vector<std::int64_t>{0, 50, 100});
    if (sequence_repeat != sequence_values) {
        std::cerr << "sequence repeated mapping changed output\n";
        return 1;
    }
    const auto nested_sequence_values = sequence_mapper.map_value(std::vector<std::vector<std::int64_t>>{
        {0, 50},
        {100},
    });
    if (nested_sequence_values.size() != 2u || nested_sequence_values[0].size() != 2u || nested_sequence_values[0][1] != 0.0 || nested_sequence_values[1][0] != 1.0) {
        std::cerr << "nested sequence mapping unexpected\n";
        return 1;
    }
    const auto nested_sequence_repeat = sequence_mapper.map_value(std::vector<std::vector<std::int64_t>>{
        {0, 50},
        {100},
    });
    if (nested_sequence_repeat != nested_sequence_values) {
        std::cerr << "nested sequence repeated mapping changed output\n";
        return 1;
    }
    bool empty_sequence = false;
    try {
        sequence_mapper.map_value(std::vector<std::int64_t>{});
    } catch (const std::invalid_argument&) {
        empty_sequence = true;
    }
    if (!empty_sequence) {
        std::cerr << "expected empty sequence to fail by default\n";
        return 1;
    }

    bool bytes_empty = false;
    try {
        BytesRangeMapper strict_bytes;
        strict_bytes.map_value(std::string("", 0));
    } catch (const std::invalid_argument&) {
        bytes_empty = true;
    } catch (const std::runtime_error&) {
        bytes_empty = true;
    }
    if (!bytes_empty) {
        std::cerr << "expected empty bytes payload to fail by default\n";
        return 1;
    }

    const auto nested_schema = MapRangeMapper::ObjectSchema{
        {"score", IntegerRangeMapper(0, 100, -1.0, 1.0, false)},
    };
    const auto nested_mapper = std::make_shared<MapRangeMapper>(nested_schema, true, false, false, std::any{});
    const auto object_schema = MapRangeMapper::ObjectSchema{
        {"age", IntegerRangeMapper(0, 120, -1.0, 1.0, false)},
        {"active", BooleanRangeMapper()},
        {"kind", categorical_mapper},
        {"payload", BytesRangeMapper()},
        {"image", ImageRangeMapper()},
        {"details", nested_mapper},
    };
    const auto object_mapper = MapRangeMapper(object_schema, false, false);
    const auto sample_object = MapRangeMapper::ObjectRecord{
        {"age", std::int64_t{42}},
        {"active", true},
        {"kind", std::string("cat")},
        {"payload", std::vector<int>{0, 128, 255}},
        {"image", std::vector<std::vector<int>>{{0, 128, 255}, {64, 192, 32}}},
        {"details", MapRangeMapper::ObjectRecord{{"score", std::int64_t{10}}}},
    };
    const auto mapped_object = object_mapper.map(sample_object);
    const auto mapped_object_second = object_mapper.map(sample_object);
    const auto payload = std::any_cast<const std::vector<double>&>(mapped_object.at("payload"));
    const double expected_payload_mid = (128.0 / 255.0) * 2.0 - 1.0;
    if (payload.size() != 3u || payload[1] != expected_payload_mid) {
        std::cerr << "object payload mapping unexpected " << payload.size() << "\n";
        return 1;
    }
    if (std::any_cast<double>(mapped_object.at("kind")) != -1.0) {
        std::cerr << "object categorical mapping unexpected\n";
        return 1;
    }
    const auto& image_payload = std::any_cast<const std::vector<std::vector<double>>&>(mapped_object.at("image"));
    if (image_payload.size() != 2u || image_payload[0].size() != 3u || image_payload[0][0] != -1.0 || image_payload[0][2] != 1.0) {
        std::cerr << "object image mapping unexpected\n";
        return 1;
    }
    const auto payload_second = std::any_cast<const std::vector<double>&>(mapped_object_second.at("payload"));
    if (payload_second.size() != payload.size() || payload_second[0] != payload[0] || payload_second[1] != payload[1] || payload_second[2] != payload[2]) {
        std::cerr << "object payload repeated mapping changed output\n";
        return 1;
    }
    const auto& image_payload_second = std::any_cast<const std::vector<std::vector<double>>&>(mapped_object_second.at("image"));
    if (image_payload_second != image_payload) {
        std::cerr << "object image repeated mapping changed output\n";
        return 1;
    }
    const auto& details = std::any_cast<const MapRangeMapper::MappedRecord&>(mapped_object.at("details"));
    assert_equal(std::any_cast<double>(details.at("score")), 0.0, "nested score map");

    const auto object_json = object_mapper.to_json();
    const auto object_roundtrip = MapRangeMapper::from_json(object_json);
    const auto mapped_roundtrip = object_roundtrip.map(sample_object);
    const auto mapped_roundtrip_second = object_roundtrip.map(sample_object);
    const auto& roundtrip_payload = std::any_cast<const std::vector<double>&>(mapped_roundtrip.at("payload"));
    if (roundtrip_payload.size() != payload.size() || roundtrip_payload[0] != payload[0] || roundtrip_payload[2] != payload[2]) {
        std::cerr << "map range serialization roundtrip changed output\n";
        return 1;
    }
    const auto& roundtrip_payload_second = std::any_cast<const std::vector<double>&>(mapped_roundtrip_second.at("payload"));
    if (roundtrip_payload_second.size() != roundtrip_payload.size() ||
        roundtrip_payload_second[0] != roundtrip_payload[0] ||
        roundtrip_payload_second[1] != roundtrip_payload[1] ||
        roundtrip_payload_second[2] != roundtrip_payload[2]) {
        std::cerr << "map range repeated roundtrip mapping changed output\n";
        return 1;
    }
    const auto& roundtrip_details = std::any_cast<const MapRangeMapper::MappedRecord&>(mapped_roundtrip.at("details"));
    assert_equal(std::any_cast<double>(roundtrip_details.at("score")), 0.0, "nested score roundtrip map");

    bool object_missing_field = false;
    try {
        auto missing_field_object = sample_object;
        missing_field_object.erase("active");
        object_mapper.map(missing_field_object);
    } catch (const std::invalid_argument&) {
        object_missing_field = true;
    }
    if (!object_missing_field) {
        std::cerr << "expected object mapper to reject missing fields\n";
        return 1;
    }

    bool object_type_error = false;
    try {
        const auto wrong_type_object = MapRangeMapper::ObjectRecord{
            {"age", true},
            {"active", true},
            {"payload", std::vector<int>{0}},
            {"details", MapRangeMapper::ObjectRecord{{"score", std::int64_t{10}}}},
        };
        object_mapper.map(wrong_type_object);
    } catch (const std::invalid_argument&) {
        object_type_error = true;
    }
    if (!object_type_error) {
        std::cerr << "expected object mapper to reject incorrect field types\n";
        return 1;
    }

    bool object_unknown_field = false;
    try {
        auto unknown_field_object = sample_object;
        unknown_field_object["unexpected"] = std::int64_t{1};
        object_mapper.map(unknown_field_object);
    } catch (const std::invalid_argument&) {
        object_unknown_field = true;
    }
    if (!object_unknown_field) {
        std::cerr << "expected object mapper to reject unknown fields\n";
        return 1;
    }

    const auto allow_missing_mapper = MapRangeMapper(MapRangeMapper::ObjectSchema{
        {"score", IntegerRangeMapper(0, 100)},
    }, false, false, true, std::any{0.0});
    const auto with_missing = allow_missing_mapper.map(MapRangeMapper::ObjectRecord{});
    if (std::any_cast<double>(with_missing.at("score")) != 0.0) {
        std::cerr << "expected missing-value policy to apply numeric fallback\n";
        return 1;
    }

    std::cout << "C++ wrapper verification passed.\n";
    return 0;
}


