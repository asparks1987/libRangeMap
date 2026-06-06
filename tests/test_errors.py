import math
import unittest

from librangemap import IntegerRangeMapper, InvalidRangeError, NotFiniteError, UnsupportedTypeError


class ErrorHandlingTests(unittest.TestCase):
    def test_rejects_equal_input_range(self):
        with self.assertRaises(InvalidRangeError):
            IntegerRangeMapper(input_range=(1, 1))

    def test_rejects_reversed_input_range(self):
        with self.assertRaises(InvalidRangeError):
            IntegerRangeMapper(input_range=(10, 0))

    def test_rejects_non_integer_input_range(self):
        with self.assertRaises(UnsupportedTypeError):
            IntegerRangeMapper(input_range=(0.0, 10))

    def test_rejects_bool_input_range(self):
        with self.assertRaises(UnsupportedTypeError):
            IntegerRangeMapper(input_range=(False, 10))

    def test_rejects_bad_output_range(self):
        with self.assertRaises(InvalidRangeError):
            IntegerRangeMapper(input_range=(0, 10), output_range=(1.0, -1.0))

    def test_rejects_nan_output_range(self):
        with self.assertRaises(NotFiniteError):
            IntegerRangeMapper(input_range=(0, 10), output_range=(-1.0, math.nan))

    def test_rejects_infinite_output_range(self):
        with self.assertRaises(NotFiniteError):
            IntegerRangeMapper(input_range=(0, 10), output_range=(-1.0, math.inf))

    def test_rejects_non_integer_value(self):
        mapper = IntegerRangeMapper(input_range=(0, 10))
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(1.5)

    def test_rejects_bool_value(self):
        mapper = IntegerRangeMapper(input_range=(0, 10))
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(True)

    def test_rejects_non_bool_clip(self):
        with self.assertRaises(UnsupportedTypeError):
            IntegerRangeMapper(input_range=(0, 10), clip="yes")


if __name__ == "__main__":
    unittest.main()
