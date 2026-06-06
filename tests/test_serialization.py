import os
import tempfile
import unittest

from librangemap import IntegerRangeMapper, SerializationError


class SerializationTests(unittest.TestCase):
    def test_to_dict_and_from_dict_round_trip(self):
        mapper = IntegerRangeMapper(input_range=(0, 255), clip=True, name="pixel")
        loaded = IntegerRangeMapper.from_dict(mapper.to_dict())
        self.assertEqual(loaded.to_dict(), mapper.to_dict())
        self.assertEqual(loaded.map_value(255), 1.0)

    def test_to_json_and_from_json_round_trip(self):
        mapper = IntegerRangeMapper(input_range=(-10, 10))
        loaded = IntegerRangeMapper.from_json(mapper.to_json())
        self.assertEqual(loaded.map_value(0), 0.0)

    def test_save_and_load_round_trip(self):
        mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
        with tempfile.TemporaryDirectory() as tmpdir:
            path = os.path.join(tmpdir, "mapper.json")
            mapper.save(path)
            loaded = IntegerRangeMapper.load(path)
        self.assertEqual(loaded.map_value(-10), -1.0)
        self.assertEqual(loaded.map_value(100), 1.0)

    def test_rejects_wrong_spec_version(self):
        data = IntegerRangeMapper(input_range=(0, 1)).to_dict()
        data["spec_version"] = "0"
        with self.assertRaises(SerializationError):
            IntegerRangeMapper.from_dict(data)

    def test_rejects_wrong_mapper_type(self):
        data = IntegerRangeMapper(input_range=(0, 1)).to_dict()
        data["mapper_type"] = "float_range"
        with self.assertRaises(SerializationError):
            IntegerRangeMapper.from_dict(data)


if __name__ == "__main__":
    unittest.main()
