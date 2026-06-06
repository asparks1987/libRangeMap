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

puts "Ruby wrapper verification passed."
