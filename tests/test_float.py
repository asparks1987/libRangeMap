import unittest

from librangemap import FloatRangeMapper, NotFiniteError, OutOfRangeError


class FloatRangeMapperTests(unittest.TestCase):
    def test_zero_based_float_range(self):
        mapper = FloatRangeMapper(input_range=(0.0, 100.0))
        self.assertEqual(mapper.map_value(0.0), -1.0)
        self.assertEqual(mapper.map_value(50.0), 0.0)
        self.assertEqual(mapper.map_value(100.0), 1.0)

    def test_negative_and_decimal_range(self):
        mapper = FloatRangeMapper(input_range=(-2.5, 2.5))
        self.assertEqual(mapper.map_value(-2.5), -1.0)
        self.assertEqual(mapper.map_value(0.0), 0.0)
        self.assertEqual(mapper.map_value(2.5), 1.0)

    def test_strict_mode_raises_out_of_range(self):
        mapper = FloatRangeMapper(input_range=(0.0, 1.0), clip=False)
        with self.assertRaises(OutOfRangeError):
            mapper.map_value(-1e-6)

        with self.assertRaises(OutOfRangeError):
            mapper.map_value(1.1)

    def test_clipping_mode_clamps(self):
        mapper = FloatRangeMapper(input_range=(0.0, 1.0), clip=True)
        self.assertEqual(mapper.map_value(-1.0), -1.0)
        self.assertEqual(mapper.map_value(2.0), 1.0)

    def test_rejects_nan_and_infinity_values(self):
        mapper = FloatRangeMapper(input_range=(0.0, 1.0))
        with self.assertRaises(NotFiniteError):
            mapper.map_value(float("nan"))
        with self.assertRaises(NotFiniteError):
            mapper.map_value(float("inf"))


if __name__ == "__main__":
    unittest.main()
