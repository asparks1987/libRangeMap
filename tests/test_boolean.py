import unittest

from librangemap import BooleanRangeMapper, SerializationError, UnsupportedTypeError


class BooleanRangeMapperTests(unittest.TestCase):
    def test_default_false_true_mapping(self):
        mapper = BooleanRangeMapper()
        self.assertEqual(mapper.map_value(False), -1.0)
        self.assertEqual(mapper.map_value(True), 1.0)

    def test_custom_false_true_mapping(self):
        mapper = BooleanRangeMapper(output_range=(0.0, 1.0), false_value=0.25, true_value=0.75)
        self.assertEqual(mapper.map_value(False), 0.25)
        self.assertEqual(mapper.map_value(True), 0.75)

    def test_rejects_non_bool(self):
        mapper = BooleanRangeMapper()
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(1)

    def test_serialization_roundtrip(self):
        mapper = BooleanRangeMapper(output_range=(0.0, 2.0), false_value=0.0, true_value=2.0, name="flag")
        serialized = mapper.to_json()
        loaded = BooleanRangeMapper.from_json(serialized)
        self.assertEqual(loaded.map_value(False), 0.0)
        self.assertEqual(loaded.map_value(True), 2.0)
        self.assertEqual(loaded.name, "flag")

    def test_unknown_mapper_type_fails(self):
        with self.assertRaises(SerializationError):
            BooleanRangeMapper.from_dict({"spec_version": "1.0-alpha", "mapper_type": "integer_range"})


if __name__ == "__main__":
    unittest.main()
