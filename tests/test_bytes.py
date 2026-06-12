import unittest

from librangemap import NotFiniteError, BytesRangeMapper, SerializationError, UnsupportedTypeError


class BytesRangeMapperTests(unittest.TestCase):
    def test_empty_payload_rejected_by_default(self):
        mapper = BytesRangeMapper()
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(b"")

    def test_empty_payload_allowed_when_configured(self):
        mapper = BytesRangeMapper(allow_empty=True)
        self.assertEqual(mapper.map_value(bytearray()), [])

    def test_byte_payload_maps_to_output_range(self):
        mapper = BytesRangeMapper(output_range=(0.0, 10.0))
        self.assertEqual(mapper.map_value(bytes([0, 127, 255])), [0.0, 5.0, 10.0])

    def test_rejects_non_bytes_value(self):
        mapper = BytesRangeMapper()
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value("not-bytes")

    def test_memoryview_is_accepted(self):
        mapper = BytesRangeMapper(output_range=(0.0, 2.0))
        mapped = mapper.map_value(memoryview(b"AB"))
        self.assertEqual(len(mapped), 2)
        self.assertAlmostEqual(mapped[0], 0.0)
        self.assertAlmostEqual(mapped[1], 66.0 / 255.0 * 2.0)

    def test_serialization_roundtrip(self):
        mapper = BytesRangeMapper(output_range=(0.0, 2.0), allow_empty=True, name="payload")
        restored = BytesRangeMapper.from_json(mapper.to_json())
        self.assertEqual(restored.map_value(bytes([255])), [2.0])
        self.assertEqual(restored.allow_empty, True)
        self.assertEqual(restored.name, "payload")

    def test_unknown_mapper_type_fails(self):
        with self.assertRaises(SerializationError):
            BytesRangeMapper.from_dict({"spec_version": "1.0-alpha", "mapper_type": "integer_range", "output_range": [-1.0, 1.0]})

    def test_rejects_non_finite_output_range(self):
        with self.assertRaises(NotFiniteError):
            BytesRangeMapper(output_range=(0.0, float("inf")))


if __name__ == "__main__":
    unittest.main()
