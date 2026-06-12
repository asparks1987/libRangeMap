import unittest

from librangemap import TextRangeMapper, SerializationError, UnsupportedTypeError


class TextRangeMapperTests(unittest.TestCase):
    def test_codepoint_default_mapping(self):
        mapper = TextRangeMapper(output_range=(-1.0, 1.0), mode="codepoint", allow_empty=True)
        expected = [-1.0 + ((ord("A") - 0.0) / (0x10FFFF - 0.0)) * 2.0]
        self.assertEqual(mapper.map_value("A"), expected)

    def test_alphabet_mapping(self):
        mapper = TextRangeMapper(mode="alphabet", alphabet="abc", output_range=(-1.0, 1.0), allow_empty=True)
        self.assertEqual(mapper.map_value("cab"), [1.0, -1.0, 0.0])

    def test_byte_mapping(self):
        mapper = TextRangeMapper(mode="byte", output_range=(0.0, 10.0), allow_empty=True)
        self.assertEqual(mapper.map_value("A"), [((65.0 - 0.0) / 255.0) * 10.0])

    def test_empty_string_disallowed_by_default(self):
        mapper = TextRangeMapper()
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value("")

    def test_rejects_unknown_alphabet_character(self):
        mapper = TextRangeMapper(mode="alphabet", alphabet="abc")
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value("d")

    def test_rejects_non_string_value(self):
        mapper = TextRangeMapper()
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(123)

    def test_serialization_roundtrip(self):
        mapper = TextRangeMapper(mode="alphabet", alphabet="abc", output_range=(0.0, 2.0), clip=True, allow_empty=True, name="labels")
        serialized = mapper.to_json()
        restored = TextRangeMapper.from_json(serialized)
        self.assertEqual(restored.map_value("ca"), [2.0, 0.0])
        self.assertEqual(restored.allow_empty, True)
        self.assertEqual(restored.name, "labels")

    def test_unknown_mapper_type_fails(self):
        with self.assertRaises(SerializationError):
            TextRangeMapper.from_dict({"spec_version": "1.0-alpha", "mapper_type": "integer_range"})


if __name__ == "__main__":
    unittest.main()
