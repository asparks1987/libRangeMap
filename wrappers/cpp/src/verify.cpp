#include <cassert>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <string>

#include "../include/librangemap.hpp"

using librangemap::BooleanRangeMapper;
using librangemap::FloatRangeMapper;
using librangemap::IntegerRangeMapper;

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

    BooleanRangeMapper custom_boolean(-1.0, 1.0, 0.2, 0.8);
    assert_equal(custom_boolean.map_value(false), 0.2, "bool false custom");
    assert_equal(custom_boolean.map_value(true), 0.8, "bool true custom");

    std::cout << "C++ wrapper verification passed.\n";
    return 0;
}
