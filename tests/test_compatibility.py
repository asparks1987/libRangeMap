import unittest

from libRangeMap import CharRangeMapper, RangeMapper
from librangemap import UnsupportedTypeError


class CompatibilityTests(unittest.TestCase):
    def test_legacy_range_mapper_wraps_integer_mapper(self):
        mapper = RangeMapper(0, 100)
        self.assertEqual(mapper.map(0), -1.0)
        self.assertEqual(mapper.map(50), 0.0)
        self.assertEqual(mapper.map(100), 1.0)
        self.assertEqual(mapper.get_input_range(), [0, 100])
        self.assertEqual(mapper.get_output_range(), [-1.0, 1.0])

    def test_legacy_char_mapper_fails_clearly(self):
        with self.assertRaises(UnsupportedTypeError):
            CharRangeMapper("A", "Z")


if __name__ == "__main__":
    unittest.main()
