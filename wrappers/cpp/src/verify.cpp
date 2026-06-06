#include <cassert>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <string>

#include "../include/librangemap.hpp"

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

    std::cout << "C++ wrapper verification passed.\n";
    return 0;
}
