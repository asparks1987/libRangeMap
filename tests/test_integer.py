import unittest

from librangemap import IntegerRangeMapper, OutOfRangeError


class IntegerRangeMapperTests(unittest.TestCase):
    def test_zero_based_range(self):
        mapper = IntegerRangeMapper(input_range=(0, 100))
        self.assertEqual(mapper.map_value(0), -1.0)
        self.assertEqual(mapper.map_value(50), 0.0)
        self.assertEqual(mapper.map_value(100), 1.0)

    def test_non_zero_positive_range(self):
        mapper = IntegerRangeMapper(input_range=(5, 15))
        self.assertEqual(mapper.map_value(5), -1.0)
        self.assertEqual(mapper.map_value(10), 0.0)
        self.assertEqual(mapper.map_value(15), 1.0)

    def test_negative_range(self):
        mapper = IntegerRangeMapper(input_range=(-100, -50))
        self.assertEqual(mapper.map_value(-100), -1.0)
        self.assertEqual(mapper.map_value(-75), 0.0)
        self.assertEqual(mapper.map_value(-50), 1.0)

    def test_mixed_range(self):
        mapper = IntegerRangeMapper(input_range=(-10, 10))
        self.assertEqual(mapper.map_value(-10), -1.0)
        self.assertEqual(mapper.map_value(0), 0.0)
        self.assertEqual(mapper.map_value(10), 1.0)

    def test_large_integer_range(self):
        mapper = IntegerRangeMapper(input_range=(-1_000_000_000, 1_000_000_000))
        self.assertEqual(mapper.map_value(-1_000_000_000), -1.0)
        self.assertEqual(mapper.map_value(0), 0.0)
        self.assertEqual(mapper.map_value(1_000_000_000), 1.0)

    def test_custom_output_range_is_explicit(self):
        mapper = IntegerRangeMapper(input_range=(0, 100), output_range=(0.0, 1.0))
        self.assertEqual(mapper.map_value(50), 0.5)

    def test_transform_and_map_aliases(self):
        mapper = IntegerRangeMapper(input_range=(0, 10))
        self.assertEqual(mapper.transform(5), 0.0)
        self.assertEqual(mapper.map(5), 0.0)

    def test_strict_mode_raises_below_and_above(self):
        mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)
        with self.assertRaises(OutOfRangeError):
            mapper.map_value(-1)
        with self.assertRaises(OutOfRangeError):
            mapper.map_value(101)

    def test_clipping_mode_clamps_below_and_above(self):
        mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
        self.assertEqual(mapper.map_value(-50), -1.0)
        self.assertEqual(mapper.map_value(150), 1.0)


if __name__ == "__main__":
    unittest.main()
