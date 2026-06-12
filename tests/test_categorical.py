import unittest

from librangemap import CategoricalRangeMapper, SerializationError, UnsupportedTypeError


class CategoricalRangeMapperTests(unittest.TestCase):
    def test_vocabulary_maps_known_tokens(self):
        mapper = CategoricalRangeMapper(vocabulary=("red", "green", "blue"), output_range=(-1.0, 1.0))
        self.assertEqual(mapper.map_value("red"), -1.0)
        self.assertEqual(mapper.map_value("green"), 0.0)
        self.assertEqual(mapper.map_value("blue"), 1.0)

    def test_unknown_token_fails_explicitly(self):
        mapper = CategoricalRangeMapper(vocabulary=(1, 2, 3), output_range=(-1.0, 1.0))
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(9)

    def test_duplicate_tokens_are_rejected(self):
        with self.assertRaises(UnsupportedTypeError):
            CategoricalRangeMapper(vocabulary=("a", "b", "a"))

    def test_non_hashable_token_is_rejected(self):
        with self.assertRaises(UnsupportedTypeError):
            CategoricalRangeMapper(vocabulary=([1], [2], [3]))

    def test_non_scalar_token_is_rejected(self):
        with self.assertRaises(UnsupportedTypeError):
            CategoricalRangeMapper(vocabulary=(("a",), ("b",)))

    def test_empty_vocabulary_is_invalid(self):
        with self.assertRaises(UnsupportedTypeError):
            CategoricalRangeMapper(vocabulary=())

    def test_non_sequence_vocabulary_rejected(self):
        with self.assertRaises(UnsupportedTypeError):
            CategoricalRangeMapper(vocabulary="ab")

    def test_singleton_vocabulary_is_mapped_to_lower_bound(self):
        mapper = CategoricalRangeMapper(vocabulary=("only",), output_range=(0.0, 2.0))
        self.assertEqual(mapper.map_value("only"), 0.0)

    def test_serialization_roundtrip(self):
        mapper = CategoricalRangeMapper(vocabulary=("A", "B"), output_range=(0.0, 4.0), name="labels")
        loaded = CategoricalRangeMapper.from_json(mapper.to_json())
        self.assertEqual(loaded.map_value("B"), 4.0)
        self.assertEqual(loaded.name, "labels")

    def test_boolean_tokens_do_not_collide_with_numeric_tokens(self):
        mapper = CategoricalRangeMapper(vocabulary=(True, 1, False), output_range=(-1.0, 1.0))
        self.assertEqual(mapper.map_value(True), -1.0)
        self.assertEqual(mapper.map_value(1), 0.0)
        self.assertEqual(mapper.map_value(False), 1.0)

    def test_integer_and_float_tokens_stay_distinct(self):
        mapper = CategoricalRangeMapper(vocabulary=(1, 1.0), output_range=(-1.0, 1.0))
        self.assertEqual(mapper.map_value(1), -1.0)
        self.assertEqual(mapper.map_value(1.0), 1.0)

    def test_wrong_mapper_type_fails(self):
        with self.assertRaises(SerializationError):
            CategoricalRangeMapper.from_dict({"spec_version": "1.0-alpha", "mapper_type": "text_range"})


if __name__ == "__main__":
    unittest.main()
