import unittest

from librangemap import MapRangeMapper, SequenceRangeMapper, UnsupportedTypeError, IntegerRangeMapper


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

    def test_element_mapper_without_to_dict_is_rejected(self):
        class _MapperWithoutToDict:
            def map_value(self, value):
                return value

        with self.assertRaises(UnsupportedTypeError):
            SequenceRangeMapper(_MapperWithoutToDict())

    def test_nested_aliases_are_deterministic_and_reproducible(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest(), preserve_tuples=True)
        first = mapper.map_value([0, (25, [50, 75])])
        second = mapper.map_value([0, (25, [50, 75])])
        self.assertEqual(first, second)
        self.assertEqual(first, [-1.0, (-0.5, [0.0, 0.5])])

    def test_disable_tuple_preservation_flattens_tuple_to_list(self):
        mapper = SequenceRangeMapper(IntegerRangeMapperForTest(), preserve_tuples=False)
        mapped = mapper.map_value((0, (25, 50)))
        self.assertIsInstance(mapped, list)
        self.assertIsInstance(mapped[1], list)

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

    def test_spec_dispatches_map_mapper(self):
        record_mapper = SequenceRangeMapper(
            MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 100))})
        )
        data = record_mapper.to_dict()
        restored = SequenceRangeMapper.from_dict(data)
        mapped = restored.map_value([{"age": 50}, {"age": 100}])
        self.assertEqual(mapped[0]["age"], 0.0)
        self.assertEqual(mapped[1]["age"], 1.0)

    def test_nested_map_and_sequence_mapping_is_deterministic(self):
        record_mapper = SequenceRangeMapper(
            MapRangeMapper(
                {
                    "age": IntegerRangeMapper(input_range=(0, 100), clip=True),
                    "scores": SequenceRangeMapper(IntegerRangeMapperForTest(), allow_empty=True),
                }
            )
        )
        input_value = [
            {"age": 25, "scores": [0, 50, 100]},
            {"age": 75, "scores": [100, 50, 0]},
        ]

        first = record_mapper.map_value(input_value)
        second = record_mapper.map_value(input_value)

        self.assertEqual(first, second)
        self.assertEqual(first[0]["age"], -0.5)
        self.assertEqual(first[0]["scores"], [-1.0, 0.0, 1.0])
        self.assertEqual(first[1]["age"], 0.5)
        self.assertEqual(first[1]["scores"], [1.0, 0.0, -1.0])


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
