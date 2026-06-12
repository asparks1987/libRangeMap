#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/librangemap"

def assert_equal(actual, expected, label)
  unless actual == expected
    raise "#{label}: #{actual.inspect}, expected #{expected.inspect}"
  end
end

mapper = LibrangeMap::IntegerRangeMapper.new(0, 100)
assert_equal(mapper.map_value(0), -1.0, "map_value(0)")
assert_equal(mapper.map_value(50), 0.0, "map_value(50)")
assert_equal(mapper.map_value(100), 1.0, "map_value(100)")

spec = mapper.spec
raise "unexpected spec_version #{spec["spec_version"]}" unless spec["spec_version"] == LibrangeMap::IntegerRangeMapper::SPEC_VERSION

roundtrip = LibrangeMap::IntegerRangeMapper.from_json(mapper.to_json)
assert_equal(roundtrip.map_value(50), 0.0, "roundtrip.map_value(50)")

clipped = LibrangeMap::IntegerRangeMapper.new(0, 10, -1.0, 1.0, true)
assert_equal(clipped.map_value(-5), -1.0, "clipped.map_value(-5)")

strict_failed = false
begin
  strict = LibrangeMap::IntegerRangeMapper.new(0, 10, -1.0, 1.0, false)
  strict.map_value(11)
rescue RangeError
  strict_failed = true
end
raise "strict out-of-range mapping should fail" unless strict_failed

float_mapper = LibrangeMap::FloatRangeMapper.new(0.0, 10.0)
assert_equal(float_mapper.map_value(0.0), -1.0, "float_mapper.map_value(0.0)")
assert_equal(float_mapper.map_value(5.0), 0.0, "float_mapper.map_value(5.0)")
assert_equal(float_mapper.map_value(10.0), 1.0, "float_mapper.map_value(10.0)")

float_roundtrip = LibrangeMap::FloatRangeMapper.from_json(float_mapper.to_json)
assert_equal(float_roundtrip.map_value(5.0), 0.0, "float_roundtrip.map_value(5.0)")

float_strict_failed = false
begin
  LibrangeMap::FloatRangeMapper.new(0.0, 1.0, -1.0, 1.0, false).map_value(1.5)
rescue RangeError
  float_strict_failed = true
end
raise "strict float out-of-range mapping should fail" unless float_strict_failed

float_invalid_failed = false
begin
  float_mapper.map_value(Float::NAN)
rescue TypeError
  float_invalid_failed = true
end
raise "float NaN should fail" unless float_invalid_failed

bool_mapper = LibrangeMap::BooleanRangeMapper.new(-1.0, 1.0)
assert_equal(bool_mapper.map_value(false), -1.0, "bool_mapper.map_value(false)")
assert_equal(bool_mapper.map_value(true), 1.0, "bool_mapper.map_value(true)")

bool_roundtrip = LibrangeMap::BooleanRangeMapper.from_json(bool_mapper.to_json)
assert_equal(bool_roundtrip.map_value(true), 1.0, "bool_roundtrip.map_value(true)")

bool_invalid_failed = false
begin
  bool_mapper.map_value(1)
rescue TypeError
  bool_invalid_failed = true
end
raise "boolean unknown-type mapping should fail" unless bool_invalid_failed

text_mapper = LibrangeMap::TextRangeMapper.new(-1.0, 1.0, "alphabet", "ABC")
assert_equal(text_mapper.map_value("CA"), [1.0, -1.0], "text_mapper.map_value(\"CA\")")

text_roundtrip = LibrangeMap::TextRangeMapper.from_json(text_mapper.to_json)
assert_equal(text_roundtrip.map_value("B"), [0.0], "text_roundtrip.map_value(\"B\")")

text_byte_mapper = LibrangeMap::TextRangeMapper.new(-1.0, 1.0, "byte")
mid_text_byte = ((127.0 / 255.0) * 2.0) - 1.0
assert_equal(text_byte_mapper.map_value("\x00\x7F\xFF"), [-1.0, mid_text_byte, 1.0], "text_byte_mapper.map_value(\"\\x00\\x7F\\xFF\")")

text_unknown_failed = false
begin
  text_mapper.map_value("Z")
rescue KeyError
  text_unknown_failed = true
end
raise "text unknown-token mapping should fail" unless text_unknown_failed

text_type_failed = false
begin
  text_mapper.map_value([])
rescue TypeError
  text_type_failed = true
end
raise "text unknown-type mapping should fail" unless text_type_failed

text_duplicate_failed = false
begin
  LibrangeMap::TextRangeMapper.new(-1.0, 1.0, "alphabet", "AAB")
rescue ArgumentError
  text_duplicate_failed = true
end
raise "text duplicate alphabet should fail" unless text_duplicate_failed

text_empty_failed = false
begin
  LibrangeMap::TextRangeMapper.new.map_value("")
rescue RangeError
  text_empty_failed = true
end
raise "text empty-string mapping should fail by default" unless text_empty_failed

temporal_mapper = LibrangeMap::TemporalRangeMapper.new(-10.0, 10.0)
assert_equal(temporal_mapper.map_value(Time.at(0).utc), 0.0, "temporal_mapper.map_value(Time.at(0).utc)")
assert_equal(temporal_mapper.map_value(0.0), 0.0, "temporal_mapper.map_value(0.0)")

temporal_roundtrip = LibrangeMap::TemporalRangeMapper.from_json(temporal_mapper.to_json)
assert_equal(temporal_roundtrip.map_value(Time.at(0).utc), 0.0, "temporal_roundtrip.map_value(Time.at(0).utc)")

temporal_invalid_failed = false
begin
  temporal_mapper.map_value("not a time")
rescue TypeError
  temporal_invalid_failed = true
end
raise "temporal unknown-type mapping should fail" unless temporal_invalid_failed

bytes_mapper = LibrangeMap::BytesRangeMapper.new
mid = ((127.0 / 255.0) * 2.0) - 1.0
assert_equal(bytes_mapper.map_value("\x00\x7F"), [-1.0, mid], "bytes_mapper.map_value(\"\\x00\\x7F\")")
assert_equal(bytes_mapper.map_value([0, 127, 255]), [-1.0, mid, 1.0])

bytes_spec = bytes_mapper.to_json
bytes_roundtrip = LibrangeMap::BytesRangeMapper.from_json(bytes_spec)
assert_equal(bytes_roundtrip.map_value("\x00"), [-1.0], "bytes_roundtrip.map_value(\"\\x00\")")

invalid_bytes_failed = false
begin
  invalid_bytes = LibrangeMap::BytesRangeMapper.new
  invalid_bytes.map_value([256])
rescue RangeError
  invalid_bytes_failed = true
end
raise "bytes out-of-range mapping should fail in strict mode" unless invalid_bytes_failed

empty_bytes_failed = false
begin
  LibrangeMap::BytesRangeMapper.new.map_value([])
rescue RangeError
  empty_bytes_failed = true
end
raise "empty bytes should fail by default" unless empty_bytes_failed

allowed_empty = LibrangeMap::BytesRangeMapper.new(-1.0, 1.0, false, true)
assert_equal(allowed_empty.map_value([]), [])

clipped = LibrangeMap::BytesRangeMapper.new(-1.0, 1.0, true, true)
assert_equal(clipped.map_value([-1, 300]), [-1.0, 1.0])

bytes_repeat = bytes_mapper.map_value([0, 127, 255])
assert_equal(bytes_repeat, [-1.0, mid, 1.0], "bytes repeated mapping")

sequence_mapper = LibrangeMap::SequenceRangeMapper.new(
  ->(value) { LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(value) }
)
assert_equal(sequence_mapper.map_value([0, 50, 100]), [-1.0, 0.0, 1.0], "sequence_mapper.map_value([0, 50, 100])")
assert_equal(sequence_mapper.map_value([0, 50, 100]), sequence_mapper.map_value([0, 50, 100]), "sequence repeated mapping")

nested_sequence_mapper = LibrangeMap::SequenceRangeMapper.new(
  ->(row) { sequence_mapper.map_value(row) }
)
assert_equal(nested_sequence_mapper.map_value([[0, 50], [100]]), [[-1.0, 0.0], [1.0]], "nested sequence mapping")

sequence_empty_failed = false
begin
  sequence_mapper.map_value([])
rescue RangeError
  sequence_empty_failed = true
end
raise "empty sequence should fail by default" unless sequence_empty_failed

object_mapper = LibrangeMap::ObjectRangeMapper.new(
  {
    "id" => LibrangeMap::IntegerRangeMapper.new(0, 10),
    "active" => LibrangeMap::BooleanRangeMapper.new(-1.0, 1.0),
  },
  true,
  false,
  nil,
  "profile"
)
assert_equal(object_mapper.map_value({ "id" => 5, "active" => true }), { "id" => -0.0, "active" => 1.0 }, "object_mapper.map_value")
assert_equal(object_mapper.map_value({ "id" => 10, "active" => false, "extra" => "skip" }), { "id" => 1.0, "active" => -1.0 }, "object_mapper allows unknown fields when allow_unknown")

missing_failed = false
begin
  object_mapper_missing = LibrangeMap::ObjectRangeMapper.new(
    { "id" => LibrangeMap::IntegerRangeMapper.new(0, 10) },
    false,
    false
  )
  object_mapper_missing.map_value({})
rescue KeyError
  missing_failed = true
end
raise "object missing required fields should fail" unless missing_failed

object_unknown_failed = false
begin
  strict_object_mapper = LibrangeMap::ObjectRangeMapper.new(
    {
      "id" => LibrangeMap::IntegerRangeMapper.new(0, 10),
      "active" => LibrangeMap::BooleanRangeMapper.new(-1.0, 1.0),
    },
    false
  )
  strict_object_mapper.map_value({ "id" => 1, "active" => true, "extra" => false })
rescue TypeError
  object_unknown_failed = true
end
raise "object unknown field should fail" unless object_unknown_failed

object_roundtrip = LibrangeMap::ObjectRangeMapper.from_json(object_mapper.to_json)
assert_equal(object_roundtrip.map_value({ "id" => 5, "active" => false }), { "id" => -0.0, "active" => -1.0 }, "object_roundtrip.map_value")

image_mapper = LibrangeMap::ImageRangeMapper.new
assert_equal(image_mapper.map_value([[0, 127, 255], [64, 192, 32]]), [[-1.0, 0.0, 1.0], [-0.4980392156862745, 0.5058823529411764, -0.7490196078431373]])

image_roundtrip = LibrangeMap::ImageRangeMapper.from_json(image_mapper.to_json)
assert_equal(image_roundtrip.map_value([[0, 127, 255], [64, 192, 32]]), [[-1.0, 0.0, 1.0], [-0.4980392156862745, 0.5058823529411764, -0.7490196078431373]], "image_roundtrip.map_value")

empty_image_failed = false
begin
  image_mapper.map_value([])
rescue TypeError
  empty_image_failed = true
end
raise "empty image should fail by default" unless empty_image_failed

image_repeated = image_mapper.map_value([[0, 127, 255], [64, 192, 32]])
assert_equal(image_repeated, image_mapper.map_value([[0, 127, 255], [64, 192, 32]]), "image mapping repeated determinism")

image_unknown_failed = false
begin
  image_mapper.map_value("not image")
rescue TypeError
  image_unknown_failed = true
end
raise "non-image input should fail" unless image_unknown_failed

categorical_mapper = LibrangeMap::CategoricalRangeMapper.new(["cat", 1, 1.0, true, nil])
assert_equal(categorical_mapper.map_value("cat"), -1.0, "categorical_mapper.map_value(\"cat\")")
assert_equal(categorical_mapper.map_value(1), -0.5, "categorical_mapper.map_value(1)")
assert_equal(categorical_mapper.map_value(1.0), 0.0, "categorical_mapper.map_value(1.0)")
assert_equal(categorical_mapper.map_value(true), 0.5, "categorical_mapper.map_value(true)")
assert_equal(categorical_mapper.map_value(nil), 1.0, "categorical_mapper.map_value(nil)")

categorical_roundtrip = LibrangeMap::CategoricalRangeMapper.from_json(categorical_mapper.to_json)
assert_equal(categorical_roundtrip.map_value(true), 0.5, "categorical_roundtrip.map_value(true)")

categorical_unknown_failed = false
begin
  categorical_mapper.map_value("missing")
rescue KeyError
  categorical_unknown_failed = true
end
raise "categorical unknown-token mapping should fail" unless categorical_unknown_failed

categorical_type_failed = false
begin
  categorical_mapper.map_value([])
rescue TypeError
  categorical_type_failed = true
end
raise "categorical unknown-type mapping should fail" unless categorical_type_failed

categorical_duplicate_failed = false
begin
  LibrangeMap::CategoricalRangeMapper.new(["cat", "cat"])
rescue ArgumentError
  categorical_duplicate_failed = true
end
raise "categorical duplicate vocabulary should fail" unless categorical_duplicate_failed

puts "Ruby wrapper verification passed."
