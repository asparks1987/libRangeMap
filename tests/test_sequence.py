import unittest

from librangemap import SequenceRangeMapper, UnsupportedTypeError


class SequenceRangeMapperTests(unittest.TestCase):
    def test_nested_sequence_maps_preserve_shape(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest())
        input_value = [0, [25, 50, [75, 100]]]
        mapped = mapper.map_value(input_value)
        self.assertIsInstance(mapped, list)
        self.assertIsInstance(mapped[1], list)
        self.assertIsInstance(mapped[1][2], list)
        self.assertEqual(mapped[0], -1.0)
        self.assertEqual(mapped[1][0], -0.5)
        self.assertEqual(mapped[1][2][1], 1.0)

    def test_tuple_input_preserved_by_default(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest(), preserve_tuples=True)
        mapped = mapper.map_value((10, [20, 30], (40,)))
        self.assertIsInstance(mapped, tuple)
        self.assertIsInstance(mapped[1], list)
        self.assertIsInstance(mapped[2], tuple)

    def test_empty_sequence_rejected_by_default(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest())
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value([])

    def test_empty_sequence_allowed_when_configured(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest(), allow_empty=True)
        self.assertEqual(mapper.map_value([],), [])

    def test_nested_unknown_type_fails_explicitly(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest())
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(["text"])

    def test_round_trip_serialization(self):
        mapper = SequenceRangeMapper(
            IntegerRangeMapperForTest(),
            allow_empty=True,
            preserve_tuples=False,
            name="nested_flags",
        )
        loaded = SequenceRangeMapper.from_dict(mapper.to_dict())
        self.assertEqual(loaded.allow_empty, mapper.allow_empty)
        self.assertEqual(loaded.preserve_tuples, mapper.preserve_tuples)
        self.assertEqual(loaded.name, "nested_flags")


class IntegerRangeMapperForTest:
    """Small test double that maps integers with the canonical integer policy."""

    def map_value(self, value):
        if not isinstance(value, int):
            raise UnsupportedTypeError("test mapper requires integers only")
        if not 0 <= value <= 100:
            raise UnsupportedTypeError("value out of test range")
        return -1.0 + (value / 100.0) * 2.0

    def to_dict(self):
        return {
            "spec_version": "1.0-alpha",
            "mapper_type": "integer_range",
            "input_range": [0, 100],
            "output_range": [-1.0, 1.0],
            "clip": False,
        }


if __name__ == "__main__":
    unittest.main()
